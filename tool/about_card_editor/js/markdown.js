/* The Markdown of the card explanations, parsed the way the app reads it.
 *
 * A port of the parts of Dart's package:markdown 7.3.1 (the CommonMark set,
 * encodeHtml off) that these files can reach, so the preview agrees with the
 * app on what is a heading, a list, a paragraph and so on. Left out: HTML
 * blocks, link reference definitions and the rarer HTML entities; none of
 * them are used in the explanations.
 *
 * Additions:
 * - the kana mark {あきの}: kana the app shows as romaji when its romaji
 *   setting is on. It is an inline node of its own.
 * - [kanji|ruby], an inline 'ruby' node with a reading, in any text.
 * - classes in braces, which start with a dot: {.right} after a picture,
 *   [words]{.red} as a span and ::: {.bg-yellow} ... ::: as a box. They are
 *   kept as `classes` (names without the dot) and `raw` (the text as typed).
 *   A brace group that follows nothing is an 'orphan' node, shown as typed.
 *   Needs Editor.config.ALIGN_CLASSES, the classes that only align.
 *
 * Nodes: {t: 'text'} | {kana: 'あきの'} | {tag, attrs?, c?, classes?, raw?}
 * (the same shape as the package's Text and Element, so a test can compare).
 */
Editor.CardMarkdown = (() => {
  /* ---- shared ---- */

  const PUNCT = /[\p{P}!-\/:-@\[-`{-~]/u;
  const SPACE = /[ \t\n\f\r   -   　]/;
  const ENTITIES = { '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&apos;': "'", '&nbsp;': ' ' };

  const P = {
    empty: /^[ \t]*$/,
    setext: /^ {0,3}(=+|-+)\s*$/,
    header: /^ {0,3}(#{1,6})(?:[ \x09\x0b\x0c].*?)?(?:\s(#*)\s*)?$/,
    quote: /^ {0,3}>[ \t]?.*$/,
    indent: /^(?:    | {0,3}\t)(.*)$/,
    fence: /^( {0,3})(?:(`{3,})([^`]*)|(~{3,})(.*))$/,
    hr: /^ {0,3}([-*_])[ \t]*\1[ \t]*\1(?:\1|[ \t])*$/,
    list: /^ {0,3}(?:(\d{1,9})[.)]|[*+-])(?:[ \t]+(.*))?$/,
    boxOpen: /^ {0,3}:{3,}[ \t]*(\{[^{}]*\})[ \t]*$/,
    boxClose: /^ {0,3}:{3,}[ \t]*$/,
  };

  /* {.red .bg-yellow}: one or more dotted names between braces. */
  const CLASS_BRACES = /\{\s*(\.[^\s{}]+(?:\s+\.[^\s{}]+)*)\s*\}/y;
  const classNames = (match) => match[1].split(/\s+/).map((c) => c.slice(1));

  const isBlank = (s) => P.empty.test(s);
  const indentation = (s) => /^[ \t]*/.exec(s)[0].length;
  const dedent = (s, n) => s.slice(Math.min(n, /^ */.exec(s)[0].length));
  const unescapePunct = (s) => s.replace(/\\([!-\/:-@\[-`{-~])/g, '$1');
  /** A node's text. With [marked], a kana mark keeps its place between KANA_OPEN and KANA_CLOSE,
      and a ruby is RUBY_OPEN base RUBY_SPLIT reading RUBY_CLOSE. */
  const KANA_OPEN = '\uE000';
  const RUBY_OPEN = '\uE002';
  const RUBY_SPLIT = '\uE003';
  const RUBY_CLOSE = '\uE004';
  const KANA_CLOSE = '\uE001';
  const textOf = (n, marked = false) => {
    if (n.t !== undefined) return n.t;
    if (n.kana !== undefined) return marked ? KANA_OPEN + n.kana + KANA_CLOSE : n.kana;
    const inner = (n.c || []).map((k) => textOf(k, marked)).join('');
    return marked && n.tag === 'ruby' ? RUBY_OPEN + inner + RUBY_SPLIT + n.reading + RUBY_CLOSE : inner;
  };
  /** Marked text as plain text: no marks, and a ruby is its base. */
  const unmark = (s) => s.replace(new RegExp(`${RUBY_OPEN}(.*?)${RUBY_SPLIT}.*?${RUBY_CLOSE}`, 'g'), '$1').replace(new RegExp(`[${KANA_OPEN}${KANA_CLOSE}]`, 'g'), '');

  /* ---- blocks (package:markdown's block_parser and block_syntaxes) ---- */

  class BlockParser {
    constructor(lines) {
      this.lines = lines;
      this.pos = 0;
      this.start = 0;
      this.encounteredBlankLine = false;
      this.parent = null;
      this.setextDisabled = false;
      this.noBox = false; // see `box`
      this.current = null;
      this.previous = null;
    }
    get cur() { return this.lines[this.pos]; }
    get done() { return this.pos >= this.lines.length; }
    advance() { this.pos++; }

    parseLines(parent = null, setextDisabled = false) {
      this.parent = parent;
      this.setextDisabled = setextDisabled;
      const blocks = [];
      let neverMatch = null;
      while (!this.done) {
        const before = this.pos;
        for (const syn of SYNTAXES) {
          if (syn === neverMatch || !syn.canParse(this)) continue;
          this.previous = this.current;
          this.current = syn;
          const block = syn.parse(this);
          if (block) blocks.push(block);
          neverMatch = this.pos !== before ? null : syn;
          if (block || syn === empty) this.start = this.pos;
          break;
        }
      }
      return blocks;
    }
  }

  const isAtBlockEnd = (p) => p.done || SYNTAXES.some((s) => s.canParse(p) && s.canEnd(p));
  const interruptedBy = (p) => SYNTAXES.find((s) => s.canParse(p) && s.canEnd(p));
  const unparsed = (text) => ({ u: text });

  const empty = {
    canParse: (p) => P.empty.test(p.cur),
    canEnd: () => true,
    parse(p) { p.encounteredBlankLine = true; p.advance(); return null; },
  };

  const fence = {
    canParse: (p) => P.fence.test(p.cur),
    canEnd: () => true,
    parse(p) {
      const open = fenceOf(P.fence.exec(unescapePunct(p.cur)));
      p.advance();
      const lines = [];
      let closing = null;
      while (!p.done) {
        const m = P.fence.exec(p.cur);
        closing = m && fenceOf(m);
        if (!closing || !closing.marker.startsWith(open.marker) || closing.info) {
          lines.push(p.cur.slice(Math.min(open.indent, /^ */.exec(p.cur)[0].length)));
          p.advance();
        } else {
          p.advance();
          break;
        }
      }
      if (!closing && lines.length && isBlank(lines[lines.length - 1])) lines.pop();
      const text = lines.join('\n');
      const language = open.info.split(' ')[0];
      const code = { tag: 'code', c: [{ t: text ? text + '\n' : '' }] };
      if (language) code.attrs = { class: 'language-' + language };
      return { tag: 'pre', c: [code] };
    },
  };
  const fenceOf = (m) => ({ indent: m[1].length, marker: m[2] ?? m[4], info: (m[3] ?? m[5]).trim() });

  /* The class names of an opening ::: {...} line, or null when its braces are not {.names}. */
  const boxNames = (line) => {
    CLASS_BRACES.lastIndex = 0;
    const m = CLASS_BRACES.exec(P.boxOpen.exec(line)[1]);
    return m && classNames(m);
  };
  /* A box with only alignment classes, such as {.right}, draws nothing of its own. */
  const alignOnly = (names) => names.every((n) => Editor.config.ALIGN_CLASSES.includes(n));

  /* ::: {.bg-yellow} ... :::  A box holds ordinary blocks. Boxes do not nest, except that
     an alignment-only box may sit inside another box. Without a closing line it is
     not a box: the opening line stays plain text.
     p.noBox says what the blocks being parsed may not hold: true is no box at all,
     'align' is alignment-only boxes only. */
  const box = {
    canParse: (p) => {
      if (p.noBox === true || !P.boxOpen.test(p.cur)) return false;
      if (p.noBox !== 'align') return true;
      const names = boxNames(p.cur);
      return !!names && alignOnly(names);
    },
    canEnd: () => true,
    parse(p) {
      const openLine = p.cur;
      const start = p.pos;
      const names = boxNames(openLine);
      const holdsAlign = !!names && !alignOnly(names);
      let depth = 0;
      p.advance();
      const lines = [];
      let fence = null;
      let closed = false;
      while (!p.done) {
        const m = P.fence.exec(p.cur);
        const mark = m && fenceOf(m);
        if (mark && !fence) fence = mark;
        else if (mark && fence && mark.marker.startsWith(fence.marker) && !mark.info) fence = null;
        if (!fence && P.boxClose.test(p.cur)) {
          if (!depth) { p.advance(); closed = true; break; }
          depth--;
        } else if (!fence && holdsAlign && P.boxOpen.test(p.cur) && alignOnly(boxNames(p.cur) ?? ['-'])) depth++;
        lines.push(p.cur);
        p.advance();
      }
      if (!names || !closed) {
        p.pos = start + 1;
        return { tag: 'p', c: [{ t: openLine.trim() }], ...(names ? { unclosed: true } : {}) };
      }
      const inner = new BlockParser(lines);
      inner.noBox = holdsAlign ? 'align' : true;
      return { tag: 'div', classes: names, raw: openLine.trim(), c: inner.parseLines() };
    },
  };

  const setext = {
    canParse: (p) => !p.setextDisabled && p.current === paragraph && P.setext.test(p.cur),
    canEnd: () => true,
    parse(p) {
      const lines = p.lines.slice(p.start, p.pos + 1);
      if (lines.length < 2) return null;
      lines.pop();
      const level = p.cur.trim()[0] === '=' ? 1 : 2;
      p.advance();
      return { tag: 'h' + level, c: [unparsed(lines.join('\n').trimEnd())] };
    },
  };

  const header = {
    canParse: (p) => P.header.test(p.cur),
    canEnd: () => true,
    parse(p) {
      const m = P.header.exec(p.cur);
      const level = m[1].length;
      const open = m[0].indexOf(m[1]) + level;
      let content = m[2] === undefined ? p.cur.slice(open) : p.cur.slice(open, m[0].lastIndexOf(m[2]));
      content = content.trim();
      const none = m[2] === undefined && /^#+$/.test(content);
      p.advance();
      return { tag: 'h' + level, c: none ? [] : [unparsed(content)] };
    },
  };

  const code = {
    canParse: (p) => P.indent.test(p.cur),
    canEnd: () => false,
    parse(p) {
      const lines = [];
      const shouldEnd = () => {
        for (let i = 1; ; i++) {
          const next = p.lines[p.pos + i];
          if (next === undefined) return true;
          if (!isBlank(next)) return !P.indent.test(next);
        }
      };
      while (!p.done) {
        const blank = isBlank(p.cur);
        if (blank && shouldEnd()) break;
        if (!blank && lines.length && !P.indent.test(p.cur)) break;
        lines.push(dedent(p.cur, 4));
        p.advance();
      }
      lines.push('');
      return { tag: 'pre', c: [{ tag: 'code', c: [{ t: lines.join('\n') }] }] };
    },
  };

  let lazyContinuation = false;
  const quote = {
    canParse: (p) => P.quote.test(p.cur),
    canEnd: () => true,
    parse(p) {
      const lines = [];
      lazyContinuation = false;
      while (!p.done) {
        const m = P.quote.exec(p.cur);
        if (m) {
          const mark = m[0].indexOf('>');
          const spaced = mark < p.cur.length - 1 && (p.cur[mark + 1] === ' ' || p.cur[mark + 1] === '\t');
          lines.push(p.cur.slice(mark + (p.cur.length > 1 && spaced ? 2 : 1)));
          p.advance();
          lazyContinuation = false;
          continue;
        }
        const last = lines[lines.length - 1];
        const other = SYNTAXES.find((s) => s.canParse(p));
        if ((other === paragraph && !isBlank(last) && !P.fence.test(last)) || (other === code && !P.indent.test(last))) {
          lines.push(p.cur);
          lazyContinuation = true;
          p.advance();
        } else break;
      }
      return { tag: 'blockquote', c: new BlockParser(lines).parseLines(quote, lazyContinuation) };
    },
  };

  const hr = {
    canParse: (p) => P.hr.test(p.cur),
    canEnd: () => true,
    parse(p) { p.advance(); return { tag: 'hr' }; },
  };

  const list = {
    canParse: (p) => P.list.test(p.cur) && !P.hr.test(p.cur),
    canEnd(p) {
      const m = P.list.exec(p.cur);
      if (p.parent !== list && m[1] !== undefined && m[1] !== '1') return false;
      return !!m[2];
    },
    parse(p) {
      const ordered = P.list.exec(p.cur)[1] !== undefined;
      const items = [];
      let lines = [];
      const endItem = () => { if (lines.length) { items.push(lines); lines = []; } };
      let marker0 = null, indent = null, startNumber = null, blankRun = null;

      while (!p.done) {
        const cur = p.cur;
        let m;
        if (isBlank(cur)) {
          lines.push(cur);
          if (blankRun !== null) blankRun++;
        } else if (indent !== null && indent <= indentation(cur)) {
          if (blankRun !== null && blankRun > 1) break;
          lines.push(dedent(cur, indent));
        } else if (P.hr.test(cur)) {
          break;
        } else if ((m = P.list.exec(cur))) {
          blankRun = null;
          let i = indentation(cur);
          let before = i;
          const markerStart = i;
          const digits = m[1] ?? '';
          if (digits) { startNumber ??= parseInt(digits, 10); i += digits.length; }
          i += 1;
          const marker = cur.slice(markerStart, i);
          let blank = true, spaces = 0, contentStart = null;
          if (i < cur.length) {
            i += 1;
            contentStart = i;
            if (i < cur.length) {
              spaces = indentation(cur.slice(i));
              i += spaces;
              if (i < cur.length) blank = false;
            }
          }
          if (marker0 !== null && marker0.slice(-1) !== marker.slice(-1)) break;
          endItem();
          marker0 = marker;
          before += digits.length + 2;
          if (blank) { blankRun = 1; indent = before; }
          else if (spaces >= 4) indent = before;
          else indent = before + spaces;
          lines.push(contentStart !== null && !blank ? cur.slice(contentStart) : '');
        } else if (isAtBlockEnd(p)) {
          break;
        } else {
          if (lines.length && isBlank(lines[lines.length - 1])) { p.encounteredBlankLine = true; break; }
          lines.push(cur);
        }
        p.advance();
      }
      endItem();

      items.forEach((l) => { if (l.length && isBlank(l[0])) l.shift(); });
      let anyEmpty = false;
      items.forEach((l, i) => {
        if (l.length === 1) return;
        while (l.length && isBlank(l[l.length - 1])) {
          if (i < items.length - 1) anyEmpty = true;
          l.pop();
        }
      });
      let blankBetween = false;
      const lis = items.map((l) => {
        const sub = new BlockParser(l);
        const c = sub.parseLines(list);
        blankBetween ||= sub.encounteredBlankLine;
        return { tag: 'li', c };
      });
      if (!anyEmpty && !blankBetween) {
        for (const li of lis) {
          let last = null;
          for (let i = 0; i < li.c.length; i++) {
            const child = li.c[i];
            if (child.tag === 'p') {
              const inner = child.c;
              if (last && last.tag) inner.unshift({ t: '\n' });
              li.c.splice(i, 1, ...inner);
            }
            last = child;
          }
        }
      }
      const el = { tag: ordered ? 'ol' : 'ul', c: lis };
      if (ordered && startNumber !== 1) el.attrs = { start: String(startNumber) };
      return el;
    },
  };

  const paragraph = {
    canParse: () => true,
    canEnd: () => false,
    parse(p) {
      const lines = [p.cur];
      p.advance();
      let bySetext = false;
      while (!p.done) {
        const syn = interruptedBy(p);
        if (syn) { bySetext = syn === setext; break; }
        lines.push(p.cur);
        p.advance();
      }
      if (bySetext) return null;
      return { tag: 'p', c: [unparsed(lines.join('\n').trimEnd())] };
    },
  };

  const SYNTAXES = [fence, box, empty, setext, header, code, quote, hr, list, paragraph];

  /* ---- inline (package:markdown's inline_parser and syntaxes) ---- */

  class Delimiter {
    constructor(char, node, endPos, flanking) {
      this.char = char;
      this.node = node;
      this.endPos = endPos;
      this.isActive = true;
      this.run = !!flanking;
      this.canOpen = flanking ? flanking.canOpen : true;
      this.canClose = flanking ? flanking.canClose : false;
    }
    get length() { return this.node.t.length; }
  }

  const canFormEmphasis = (o, c) =>
    (o.canOpen && o.canClose) || (c.canOpen && c.canClose)
      ? (o.length + c.length) % 3 !== 0 || (o.length % 3 === 0 && c.length % 3 === 0)
      : true;

  const MARK = /\{(?!\s*\.)([^{}\n]+)\}/y;
  const ORPHAN = /\{\s*\.[^{}\n]*\}/y;
  /* [kanji|ruby]: exactly one |, something on each side, and no spaces, brackets,
     braces, backslashes or emphasis marks inside. */
  const RUBY_TEXT = /^([^|[\]\\{}*_`\s\u3000]+)\|([^|[\]\\{}*_`\s\u3000]+)$/;
  const CODE = /(`+(?!`))((?:.|\n)*?[^`])\1(?!`)/y;
  const AUTOLINK = /<(([a-zA-Z][a-zA-Z\-+.]+):(?:\/\/)?[^\s>]*)>/y;
  const ENTITY = /&(?:([a-z0-9]+)|#([0-9]{1,7})|#x([a-f0-9]{1,6}));/iy;
  const BREAK = /(?:\\|  +)\n/y;

  function parseInline(source, marks) {
    let pos = 0;
    let start = 0;
    const tree = [];
    const stack = [];
    const at = (re) => { re.lastIndex = pos; return re.exec(source); };
    const writeText = () => { if (pos !== start) { tree.push({ t: source.slice(start, pos) }); start = pos; } };
    const consume = (n) => { pos += n; start = pos; };

    /* What stands beside a delimiter run; a kana mark counts as its kana. */
    const before = (i) => {
      if (source[i - 1] === '}') {
        const m = /\{(?!\s*\.)([^{}\n]+)\}$/.exec(source.slice(0, i));
        if (m && marks) return m[1].slice(-1);
      }
      return source[i - 1];
    };
    const after = (i) => {
      if (marks && source[i] === '{') {
        MARK.lastIndex = i;
        const m = MARK.exec(source);
        if (m) return m[1][0];
      }
      return source[i];
    };

    function flanking(from, to) {
      const prev = from === 0 ? undefined : before(from);
      const next = to === source.length ? undefined : after(to);
      const prevSpace = prev === undefined || SPACE.test(prev);
      const nextSpace = next === undefined || SPACE.test(next);
      const prevPunct = !prevSpace && PUNCT.test(prev);
      const nextPunct = !nextSpace && PUNCT.test(next);
      const left = !nextSpace && (!nextPunct || prevSpace || prevPunct);
      const right = !prevSpace && (!prevPunct || nextSpace || nextPunct);
      return { left, right, prevPunct, nextPunct };
    }

    function emphasisRun(char, intraWord) {
      const run = at(char === '*' ? /\*+/y : /_+/y)[0];
      const node = { t: run };
      const f = flanking(pos, pos + run.length);
      const canOpen = f.left && (!f.right || intraWord || f.prevPunct);
      const canClose = f.right && (!f.left || intraWord || f.nextPunct);
      stack.push(new Delimiter(char, node, pos + run.length, { canOpen, canClose }));
      tree.push(node);
      consume(run.length);
      return true;
    }

    function processRuns(bottom) {
      let cur = bottom + 1;
      const openersBottom = {};
      while (cur < stack.length) {
        const closer = stack[cur];
        if (!closer.canClose || !closer.run) { cur++; continue; }
        const ob = (openersBottom[closer.char] ??= [bottom, bottom, bottom]);
        let oi = -1;
        for (let k = cur - 1; k >= 0; k--) {
          const d = stack[k];
          if (d.char === closer.char && d.canOpen && canFormEmphasis(d, closer)) { oi = k; break; }
        }
        if (oi > bottom && oi > ob[closer.length % 3]) {
          const opener = stack[oi];
          if (!opener.run) { cur++; continue; }
          const size = opener.length >= 2 && closer.length >= 2 ? 2 : 1;
          const oNode = opener.node;
          const cNode = closer.node;
          const oIdx = tree.indexOf(oNode);
          let cIdx = tree.indexOf(cNode);
          const children = tree.slice(oIdx + 1, cIdx);
          tree.splice(oIdx + 1, cIdx - oIdx - 1, { tag: size === 2 ? 'strong' : 'em', c: children });
          cIdx = oIdx + 2;
          stack.splice(oi + 1, cur - oi - 1);
          cur = oi + 1;
          if (opener.length === size) {
            tree.splice(oIdx, 1);
            stack.splice(oi, 1);
            cur--;
            cIdx--;
          } else {
            opener.node = tree[oIdx] = { t: oNode.t.slice(size) };
          }
          if (closer.length === size) {
            tree.splice(cIdx, 1);
            stack.splice(cur, 1);
          } else {
            closer.node = tree[cIdx] = { t: cNode.t.slice(size) };
          }
        } else {
          ob[closer.length % 3] = cur - 1;
          if (!closer.canOpen) stack.splice(cur, 1);
          else cur++;
        }
      }
      stack.splice(bottom + 1);
    }

    /* Links and pictures: only the inline form `[text](destination "title")`. */
    const skipSpace = () => { while (pos < source.length && /[ \t\n\v\r\f]/.test(source[pos])) pos++; };
    function parseTitle() {
      skipSpace();
      if (pos >= source.length) return null;
      const open = source[pos];
      if (open !== "'" && open !== '"' && open !== '(') return null;
      const close = open === '(' ? ')' : open;
      pos++;
      if (pos >= source.length) return null;
      let title = '';
      for (;;) {
        const ch = source[pos];
        if (ch === '\\') {
          pos++;
          if (pos >= source.length) return null;
          if (source[pos] !== '\\' && source[pos] !== close) title += ch;
          title += source[pos];
        } else if (ch === close) break;
        else title += ch;
        pos++;
        if (pos >= source.length) return null;
      }
      pos++;
      if (pos >= source.length) return null;
      skipSpace();
      if (pos >= source.length || source[pos] !== ')') return null;
      return title;
    }
    function parseInlineLink() {
      pos++;
      skipSpace();
      if (pos >= source.length) return null;
      let dest = '';
      if (source[pos] === '<') {
        pos++;
        if (pos >= source.length) return null;
        for (;;) {
          const ch = source[pos];
          if (ch === '\\') {
            pos++;
            if (pos >= source.length) return null;
            if (source[pos] !== '\\' && source[pos] !== '>') dest += ch;
            dest += source[pos];
          } else if (/[\n\r\f]/.test(ch)) return null;
          else if (ch === ' ') dest += '%20';
          else if (ch === '>') break;
          else dest += ch;
          pos++;
          if (pos >= source.length) return null;
        }
        pos++;
        if (pos >= source.length) return null;
        const ch = source[pos];
        if (/[ \n\r\f]/.test(ch)) {
          const title = parseTitle();
          if (title === null && (pos >= source.length || source[pos] !== ')')) return null;
          return { dest, title };
        }
        return ch === ')' ? { dest, title: null } : null;
      }
      let depth = 1;
      for (;;) {
        const ch = source[pos];
        if (ch === '\\') {
          pos++;
          if (pos >= source.length) return null;
          if (!'\\()'.includes(source[pos])) dest += ch;
          dest += source[pos];
        } else if (/[ \n\r\f]/.test(ch)) {
          const title = parseTitle();
          if (title === null && (pos >= source.length || source[pos] !== ')')) return null;
          depth--;
          if (depth === 0) return { dest, title };
        } else if (ch === '(') {
          depth++;
          dest += ch;
        } else if (ch === ')') {
          depth--;
          if (depth === 0) return { dest, title: null };
          dest += ch;
        } else dest += ch;
        pos++;
        if (pos >= source.length) return null;
      }
    }
    const destination = (s) =>
      unescapePunct(s).split(/(%[0-9A-Fa-f]{2})/).map((part, i) => {
        if (i % 2) return part;
        try { return encodeURI(decodeURI(part)); } catch { return encodeURI(part); }
      }).join('');

    /* The {.classes} that start at [i], or null. */
    const bracesAt = (i) => {
      CLASS_BRACES.lastIndex = i;
      const m = CLASS_BRACES.exec(source);
      return m && { classes: classNames(m), raw: m[0] };
    };

    function closeLink(opener, children) {
      if (opener.char === '[') {
        const ruby = RUBY_TEXT.exec(source.slice(opener.endPos, pos));
        if (ruby && source[pos + 1] !== '(') {
          const braces = bracesAt(pos + 1);
          if (braces) pos += braces.raw.length;
          children();
          return [{ tag: 'ruby', reading: ruby[2], c: [{ t: ruby[1] }], ...(braces ?? {}) }];
        }
        const braces = bracesAt(pos + 1);
        if (braces) {
          pos += braces.raw.length;
          return [{ tag: 'span', classes: braces.classes, raw: braces.raw, c: children() }];
        }
      }
      if (pos + 1 >= source.length || source[pos + 1] !== '(') return null;
      pos++;
      const leftParen = pos;
      const link = parseInlineLink();
      if (!link) { pos = leftParen - 1; return null; }
      const kids = children();
      if (opener.char === '!') {
        const alt = kids.map((n) => (n.tag === 'img' ? n.attrs.alt : textOf(n, true))).join('');
        const braces = bracesAt(pos + 1);
        if (braces) pos += braces.raw.length;
        return [{ tag: 'img', attrs: { src: destination(link.dest), alt, ...(link.title ? { title: link.title } : {}) }, ...(braces ?? {}) }];
      }
      return [{ tag: 'a', c: kids, attrs: { href: destination(link.dest) } }];
    }

    function linkOrImage() {
      const index = stack.map((d) => d.char).findLastIndex((c) => c === '[' || c === '!');
      const text = () => { tree.push({ t: ']' }); pos++; start = pos; };
      if (index === -1) return text();
      const d = stack[index];
      if (!d.isActive) { stack.splice(index, 1); return text(); }
      const nodeIndex = tree.lastIndexOf(d.node);
      const children = () => {
        processRuns(index);
        const kids = tree.slice(nodeIndex + 1);
        tree.length = nodeIndex + 1;
        return kids;
      };
      const made = closeLink(d, children);
      stack.splice(index, 1);
      if (made) {
        if (made[0].tag === 'a') for (let k = 0; k < index; k++) if (stack[k].char === '[') stack[k].isActive = false;
        tree.splice(nodeIndex, tree.length - nodeIndex, ...made);
        pos++;
        start = pos;
      } else {
        pos = start + 1;
      }
    }

    /* The syntaxes in the package's order; each returns true when it matched. */
    const syntaxes = [
      () => {
        const m = marks && source[pos] === '{' && at(MARK);
        if (!m) return false;
        writeText();
        tree.push({ kana: m[1] });
        consume(m[0].length);
        return true;
      },
      () => {
        const m = source[pos] === '{' && at(ORPHAN);
        if (!m) return false;
        writeText();
        tree.push({ tag: 'orphan', c: [{ t: m[0] }] });
        consume(m[0].length);
        return true;
      },
      () => {
        if (source[pos] !== '\\' || !/[!-\/:-@\[-`{-~]/.test(source[pos + 1] ?? '')) return false;
        writeText();
        tree.push({ t: source[pos + 1] });
        consume(2);
        return true;
      },
      () => {
        if (source[pos] !== '&' || source[pos - 1] === '`') return false;
        const m = at(ENTITY);
        if (!m) return false;
        const text = m[1] ? ENTITIES[m[0]] : String.fromCodePoint(m[2] ? +m[2] : parseInt(m[3], 16));
        if (text === undefined) return false;
        writeText();
        tree.push({ t: text });
        consume(m[0].length);
        return true;
      },
      () => {
        if (source[pos] !== '[') return false;
        writeText();
        const node = { t: '[' };
        stack.push(new Delimiter('[', node, pos + 1));
        tree.push(node);
        consume(1);
        return true;
      },
      () => {
        if (source[pos] !== '!' || source[pos + 1] !== '[') return false;
        writeText();
        const node = { t: '![' };
        stack.push(new Delimiter('!', node, pos + 2));
        tree.push(node);
        consume(2);
        return true;
      },
      () => {
        const m = source[pos] === '<' && at(AUTOLINK);
        if (!m) return false;
        writeText();
        tree.push({ tag: 'a', c: [{ t: m[1] }], attrs: { href: destination(m[1]) } });
        consume(m[0].length);
        return true;
      },
      () => {
        const m = at(BREAK);
        if (!m) return false;
        writeText();
        tree.push({ tag: 'br' });
        consume(m[0].length);
        return true;
      },
      () => {
        if (source[pos] !== '*') return false;
        writeText();
        return emphasisRun('*', true);
      },
      () => {
        if (source[pos] !== '_') return false;
        writeText();
        return emphasisRun('_', false);
      },
      () => {
        if (source[pos - 1] === '`') return false;
        const m = at(CODE);
        if (!m) return false;
        writeText();
        let text = source.slice(pos + m[1].length, pos + m[0].length - m[1].length);
        const spaced = (s) => s.startsWith(' ') || s.startsWith('\n');
        const endSpaced = (s) => s.endsWith(' ') || s.endsWith('\n');
        if (text.trim() && spaced(text) && endSpaced(text)) text = text.slice(1, -1);
        tree.push({ tag: 'code', c: [{ t: text.replaceAll('\n', ' ') }] });
        consume(m[0].length);
        return true;
      },
      () => {
        if (source[pos] !== ' ' || source[pos + 1] !== '\n') return false;
        writeText();
        consume(1);
        return true;
      },
    ];

    while (pos < source.length) {
      if (source[pos] === ']') { writeText(); linkOrImage(); continue; }
      if (syntaxes.some((s) => s())) continue;
      pos++;
    }
    writeText();
    processRuns(-1);
    return joinText(tree);
  }

  function joinText(nodes) {
    const out = [];
    for (const n of nodes) {
      if (n.c) n.c = joinText(n.c);
      if (n.t !== undefined && out.length && out[out.length - 1].t !== undefined) out[out.length - 1] = { t: out[out.length - 1].t + n.t };
      else out.push(n);
    }
    return out;
  }

  /* ---- the document ---- */

  function inlineInto(nodes, marks) {
    return nodes.flatMap((n) => {
      if (n.u !== undefined) return parseInline(n.u, marks);
      if (n.c) n.c = inlineInto(n.c, marks);
      return [n];
    });
  }

  /* A picture with {.left} or {.right} may have its text on the very next line.
     That text is split off into a paragraph of its own, as if a blank line was there. */
  const floats = (img) => img.classes?.some((c) => c === 'left' || c === 'right');
  function splitFloats(nodes) {
    return nodes.flatMap((node) => {
      if (node.tag === 'div') { node.c = splitFloats(node.c); return [node]; }
      const [img, next, ...rest] = node.c ?? [];
      if (node.tag !== 'p' || img?.tag !== 'img' || !floats(img) || next?.t === undefined || !next.t.startsWith('\n')) return [node];
      const text = next.t.replace(/^\n[ \t]*/, '');
      const after = [...(text ? [{ t: text }] : []), ...rest];
      return after.length ? [{ tag: 'p', c: [img] }, { tag: 'p', c: after }] : [{ tag: 'p', c: [img] }];
    });
  }

  /** The blocks of [source] as nodes. [marks] switches the kana mark on. */
  function parse(source, { marks = true } = {}) {
    const lines = source
      .split(/\r\n|\r|\n/)
      .map((l) => { while (/^ *\t/.test(l)) l = l.replace(/^( *)\t/, (_, s) => s + ' '.repeat(4 - (s.length % 4))); return l; });
    if (lines.length && lines[lines.length - 1] === '') lines.pop();
    return splitFloats(inlineInto(new BlockParser(lines).parseLines(), marks));
  }

  return { parse, textOf, unmark, KANA_OPEN, KANA_CLOSE, RUBY_OPEN, RUBY_SPLIT, RUBY_CLOSE };
})();

if (typeof module !== 'undefined') module.exports = Editor.CardMarkdown;
