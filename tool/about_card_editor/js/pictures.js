/* The pictures a draft mentions, and the image files chosen to preview them. */
Editor.pictures = (() => {
  const { $, esc } = Editor.util;
  const { unmark } = Editor.CardMarkdown;
  const state = Editor.state;
  const { imageUrl, repoUrl } = Editor.preview;

  const picturesIn = (nodes) => {
    const found = [];
    const walk = (list) => list.forEach((x) => {
      if (x.tag === 'img' && !found.some((f) => f.path === x.attrs.src)) found.push({ path: x.attrs.src, caption: unmark(x.attrs.alt || '') });
      if (x.c) walk(x.c);
    });
    walk(nodes);
    return found;
  };

  function renderPictures(nodes) {
    const items = picturesIn(nodes);
    const box = $('#pictures');
    $('#picturesWrap').hidden = !items.length;
    box.innerHTML = items.map(({ path }) => {
      const attached = state.attached[path];
      const url = imageUrl(path);
      /* The repo file may be there or not; the picture's own load events tell, and the row's CSS shows the matching text. */
      const status = attached ? '<small>Preview only: send this image file to the developer.</small>'
        : repoUrl(path)
          ? '<small class="repo-yes">From the repo: this picture is already there. Choose a file only to preview another one.</small>' +
            '<small class="repo-no">Not in the repo yet. Choose a file to preview it, then send the image file to the developer.</small>'
          : '<small>Choose a file to preview it, then send the image file to the developer.</small>';
      const probe = url && !attached ? ' onload="this.closest(\'.picrow\').classList.add(\'in-repo\')" onerror="this.remove()"' : '';
      return `<li class="picrow" data-path="${esc(path)}"><span class="thumb">${url ? `<img src="${url}" alt=""${probe}>` : '?'}</span>` +
        `<span class="pinfo"><code>${esc(path)}</code>${status}</span>` +
        `<button type="button" class="btn small" data-act="pick" data-path="${esc(path)}">Choose image</button>` +
        (state.attached[path] ? `<button type="button" class="btn small" data-act="unpick" data-path="${esc(path)}">Remove</button>` : '') + '</li>';
    }).join('');
  }

  function attach(path, file) {
    if (!file || !file.type.startsWith('image/')) return;
    if (state.attached[path]) URL.revokeObjectURL(state.attached[path].url);
    state.attached[path] = { file, url: URL.createObjectURL(file) };
    Editor.preview.renderMd();
  }

  function wire() {
    const input = $('#pick');
    let pickPath = '';
    const choose = (path) => { pickPath = path; input.value = ''; input.click(); };
    input.addEventListener('change', () => attach(pickPath, input.files[0]));
    document.addEventListener('click', (e) => {
      const d = e.target.closest('.drop');
      if (d) return choose(d.dataset.path);
      const b = e.target.closest('button[data-act]');
      if (!b) return;
      if (b.dataset.act === 'pick') choose(b.dataset.path);
      if (b.dataset.act === 'unpick') { URL.revokeObjectURL(state.attached[b.dataset.path].url); delete state.attached[b.dataset.path]; Editor.preview.renderMd(); }
    });
    document.addEventListener('keydown', (e) => {
      const d = e.target.closest?.('.drop');
      if (d && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); choose(d.dataset.path); }
    });
    document.addEventListener('dragover', (e) => { e.preventDefault(); });
    document.addEventListener('drop', (e) => {
      e.preventDefault();
      const target = e.target.closest?.('[data-path]');
      if (target && e.dataTransfer.files[0]) attach(target.dataset.path, e.dataTransfer.files[0]);
    });
  }

  return { picturesIn, renderPictures, attach, wire };
})();
