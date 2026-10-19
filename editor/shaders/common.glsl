// The card every shader draws: the skin's image files stacked, lit, worn and lettered.
//
// A skin is a folder of images. The engine binds each file to the sampler named after it
// (colour.png to uColour, pattern_material.png to uPatternMaterial) and a neutral 1 x 1 image
// when the file is missing. Shaders only stack, light and wear these images; shapes and layout
// live in the files.
//
// A custom shader includes this file and declares its own extra inputs with one-line tags after
// each uniform (@colour, @number, @switch, @choice, @texture, @placement, @random); the editor
// builds their form rows from the tags. Inputs the engine sets are tagged @engine.
//
// Placements: a mat3 window maps card uv (x / 374, y / 374) to sheet uv. The card turns about its
// own centre, `scale` is how many sheet widths lie across the card's width (a 1024 px sheet that
// covers 256 units has scale 374 / 256), x and y are the sheet point under the card centre in sheet
// widths. Sheets repeat. Texture reads are macros because SkSL refuses a sampler as an argument.

precision highp float;
out vec4 outColor;

// ---- Constants: every number that tunes the look lives in this block ----------

const vec2 CARD = vec2(374., 525.);
const vec2 CC = vec2(187., 262.5);
const float CAMERA_DISTANCE = 1600.;

// Wear, CS style. The wear sheet's R (chip order, 0..1) times the skin's wear.png gives each spot a
// value; paint survives where that value is below 1 - float. wear.png decides where the card wears
// and in what order, the sheet only breaks that up so two cards at the same float differ.
const float WEAR_CURVE = .6;
const float SURVIVE_BAND = .03;
// Dirt: a darkening from the sheet's G, mostly near the edges. Scratches: the sheet's B, each line
// with its own depth, showing under.png.
const vec3 GRIME_TINT = vec3(.88, .8, .66);
const float GRIME_STRENGTH = .5, GRIME_INTERIOR = .35;
const float SCRATCH_STRENGTH = .5, SCRATCH_REACH = 1.3, SCRATCH_BAND = .06, SCRATCH_FLOOR = .02;
// Worn ink fades a little where the grunge is.
const float TEXT_WEAR_FADE = .12;
// Bare card under worn paint is matte.
const float UNDER_GLOSS = .02;

// Pattern sheets are this many pixels wide, the wear sheet this many. Sheets are read at an explicit
// mip level: a wrapped coordinate (fract) makes the automatic level jump to the blurriest at the seam.
const float SHEET_TEXELS = 1024.;
const float TILE_TEXELS = 512.;

// Light. Gloss (material G) sets how much a surface reflects the studio and how tight its
// highlight is. Metal (material R) tints the reflection with the colour and drops the diffuse.
const float DIFFUSE_GAIN = .95;
const float GLOSS_SHEEN = .3, GLOSS_GLINT = .45;
const float GLINT_POWER_DULL = 8., GLINT_POWER_GLOSSY = 160.;
const float METAL_BASE = .35, METAL_STUDIO = .95, METAL_GLINT = .7;

// The brocade border: a centre loop (rounded rectangle) inset from the card edge, and the strips
// drawn along it. The water strip repeats every WATER_UNITS along it (rounded to a whole number of
// repeats round the loop); the leaves strip repeats twice round it.
const float LOOP_INSET = 18., LOOP_RADIUS = 22.;
const float WATER_UNITS = 120., WATER_DEPTH = 24., LEAVES_DEPTH = 32.;
const float WATER_RELIEF_STEP = .6, WATER_TEXELS_PER_UNIT = 4., WATER_GOLD_GLOSS = .85;

// The studio the metals reflect.
const float STUDIO_BASE = .15, STUDIO_LIGHT = .85, STUDIO_LIGHT_FULL = 1.25, STUDIO_LIGHT_MAX = 1.4;

// The stage behind the card, and the card's shadow on it.
const vec3 STAGE_DARK = vec3(.05, .055, .07), STAGE_LIGHT = vec3(.15, .155, .19);
const vec2 STAGE_CENTRE_SHIFT = vec2(0., 30.), STAGE_SIZE = vec2(430., 560.);
const float STAGE_FALLOFF = .9;
const float SHADOW_SHIFT = 9., SHADOW_SHIFT_MAX = 40., SHADOW_LIGHT_FLOOR = .25;
const float SHADOW_FROM = -26., SHADOW_TO = 30., SHADOW_ROUND = 6., SHADOW_DARKEN = .6;

// ---- Engine inputs ---------------------------------------------------------------

uniform vec2 uSize;            // @engine pixels painted
uniform vec4 uView;            // @engine the window into card space: x, y, width, height in card units
uniform vec2 uTilt;            // @engine -1 to 1 on each axis
uniform float uMaxTilt;        // @engine radians at full tilt
uniform float uFloat;          // @engine the float, 0 new to 1 worn out
uniform float uTime;           // @engine seconds, for @animated shaders; 0 when baked
uniform vec3 uLightDir;        // @engine
uniform vec3 uLightColor;      // @engine
uniform float uLightIntensity; // @engine
uniform float uAmbient;        // @engine
uniform mat3 uWearWin;         // @engine the seed's window on the wear sheet
uniform mat3 uGrungeWin;       // @engine the seed's second window on the wear sheet
uniform mat3 uPatternWin;      // @engine the seed's window on pattern.png
uniform vec3 uInk;             // @engine text colours from skin.json
uniform vec3 uBadge;           // @engine
uniform vec3 uNumeral;         // @engine
uniform sampler2D uText;       // @engine R kana ink, G kana halo
uniform sampler2D uBadgeText;  // @engine R badge ring, G poem number
uniform sampler2D uWearSheet;  // @engine R chip order, G grunge, B scratches

// The skin's files.
uniform sampler2D uColour;          // @engine colour.png: the card front as it shows
uniform sampler2D uNormal;          // @engine normal.png: tangent-space normals, OpenGL style
uniform sampler2D uMaterial;        // @engine material.png: R metal, G gloss
uniform sampler2D uPattern;         // @engine pattern.png: a sheet that shows where colour.png is clear
uniform sampler2D uPatternMaterial; // @engine pattern_material.png
uniform sampler2D uPatternNormal;   // @engine pattern_normal.png
uniform sampler2D uWear;            // @engine wear.png: white wears first, black never wears
uniform sampler2D uUnder;           // @engine under.png: what shows where the paint has worn off

// A repeating read at an explicit mip level. [uvPerUnit] is how far uv moves per card unit.
#define tiled(s, uv, lod) textureLod(s, fract(uv), lod)
float mipLevel(float aa, float uvPerUnit, float texels) { return max(log2(aa * uvPerUnit * texels), 0.); }

// ---- The card ----------------------------------------------------------------------

struct Card {
  vec2 sp;         // the point in the view, card units
  vec2 cp;         // the point on the (tilted) card plane, card units
  vec2 uv;         // cp across the card, 0 to 1
  float alpha;     // card coverage, antialiased
  float aa;        // card units per pixel on the card
  float wearOrder; // wear.png here: how early this spot wears, 0 to 1
  float wear;      // the float shaped into wear, 0 new, 1 worn out
  float chip;      // wear sheet chip order at this spot
  vec2 grunge;     // wear sheet grunge (x) and scratches (y)
  float envK;      // how bright the studio is
  vec3 V, L, Ls;   // view and light on the card, light in the view
  vec3 N, R;       // surface normal and the reflected view
};

// What the paint is at one spot: its colour, how metallic and glossy, and its normal.
struct Surface {
  vec3 colour;
  float metal;
  float gloss;
  vec3 n;
};

vec2 tm(mat3 m, vec2 p) { return (m * vec3(p, 1.)).xy; }
float lum(vec3 c) { return dot(c, vec3(.2126, .7152, .0722)); }
float sdBox(vec2 p, vec2 b, float r) { vec2 q = abs(p) - b + r; return length(max(q, 0.)) + min(max(q.x, q.y), 0.) - r; }

// Where the view ray through screen point sp meets the card turned by Rm, in card
// space. P is the hit point in world space. Rt turns back.
vec3 cardPoint(vec2 sp, mat3 Rm, mat3 Rt, out vec3 P) {
  vec3 cam = vec3(CC, CAMERA_DISTANCE), dir = vec3(sp, 0.) - cam, nrm = Rm * vec3(0., 0., 1.);
  float t = dot(vec3(CC, 0.) - cam, nrm) / dot(dir, nrm);
  P = cam + t * dir;
  return Rt * (P - vec3(CC, 0.)) + vec3(CC, 0.);
}

Card cardSetup() {
  Card c;
  c.sp = uView.xy + FlutterFragCoord().xy / uSize * uView.zw;
  float upp = uView.z / uSize.x;
  float ax = -uTilt.y * uMaxTilt, ay = uTilt.x * uMaxTilt;
  vec3 cam = vec3(CC, CAMERA_DISTANCE);
  mat3 Rx = mat3(1., 0., 0., 0., cos(ax), sin(ax), 0., -sin(ax), cos(ax));
  mat3 Ry = mat3(cos(ay), 0., -sin(ay), 0., 1., 0., sin(ay), 0., cos(ay));
  mat3 Rm = Ry * Rx;
  // Written out because SkSL has no transpose.
  mat3 Rt = mat3(1., 0., 0., 0., cos(ax), -sin(ax), 0., sin(ax), cos(ax)) * mat3(cos(ay), 0., sin(ay), 0., 1., 0., -sin(ay), 0., cos(ay));
  vec3 P, Px, Py;
  c.cp = cardPoint(c.sp, Rm, Rt, P).xy;
  c.uv = c.cp / CARD;
  vec2 cpx = cardPoint(c.sp + vec2(upp, 0.), Rm, Rt, Px).xy, cpy = cardPoint(c.sp + vec2(0., upp), Rm, Rt, Py).xy;
  c.aa = max(length(cpx - c.cp), length(cpy - c.cp));
  c.V = normalize(Rt * (cam - P));
  c.L = normalize(Rt * uLightDir);
  c.Ls = normalize(uLightDir);
  c.N = vec3(0., 0., 1.);
  c.R = reflect(-c.V, c.N);
  c.envK = STUDIO_BASE + STUDIO_LIGHT * clamp((uAmbient + uLightIntensity) / STUDIO_LIGHT_FULL, 0., STUDIO_LIGHT_MAX);

  c.wear = pow(uFloat, WEAR_CURVE);
  c.wearOrder = texture(uWear, c.uv).r;
  float lodWear = mipLevel(c.aa, length(uWearWin[0].xy) / CARD.x, TILE_TEXELS), lodGrunge = mipLevel(c.aa, length(uGrungeWin[0].xy) / CARD.x, TILE_TEXELS);
  c.chip = tiled(uWearSheet, tm(uWearWin, c.cp / CARD.x), lodWear).r;
  c.grunge = tiled(uWearSheet, tm(uGrungeWin, c.cp / CARD.x), lodGrunge).gb;

  float aa = c.aa * 1.1;
  c.alpha = 1. - smoothstep(-aa, aa, sdBox(c.cp - CC, CARD * .5, 0.));
  return c;
}

// An OpenGL-style normal map texel (green up) as a normal on the card, whose y runs down.
vec3 unpackNormal(vec3 t) {
  vec3 n = t * 2. - 1.;
  return normalize(vec3(n.x, -n.y, max(n.z, .05)));
}

// ---- The skin's files ----------------------------------------------------------------

// colour.png over the placed pattern over under.png, with the matching material and normal.
// Flutter hands over images with premultiplied alpha.
Surface cardSurface(Card c) {
  vec4 top = texture(uColour, c.uv);
  vec2 puv = tm(uPatternWin, c.cp / CARD.x);
  float lod = mipLevel(c.aa, length(uPatternWin[0].xy) / CARD.x, SHEET_TEXELS);
  vec4 pattern = tiled(uPattern, puv, lod);
  vec3 under = texture(uUnder, c.uv).rgb;
  Surface s;
  s.colour = top.rgb + (pattern.rgb + under * (1. - pattern.a)) * (1. - top.a);
  vec2 m = mix(tiled(uPatternMaterial, puv, lod).rg, vec2(0., UNDER_GLOSS), 1. - pattern.a);
  m = mix(m, texture(uMaterial, c.uv).rg, top.a);
  s.metal = m.r;
  s.gloss = m.g;
  s.n = normalize(mix(unpackNormal(tiled(uPatternNormal, puv, lod).rgb), unpackNormal(texture(uNormal, c.uv).rgb), top.a));
  return s;
}

// ---- Light --------------------------------------------------------------------------

// A soft studio for metals to reflect: a bright diagonal strip, a cool top.
vec3 env(Card c, vec3 r) {
  float strip = exp(-pow((r.x * .75 - r.y * .66 + .1) * 3.6, 2.));
  float strip2 = exp(-pow((r.x * .2 + r.y * .9 - .55) * 5., 2.)) * .5;
  float top = smoothstep(-.3, .9, -r.y);
  return (vec3(.05, .045, .04) + vec3(1., .95, .86) * (strip * 1.25 + strip2) + vec3(.3, .34, .42) * top * .45) * c.envK;
}

// Lit colour of a surface with normal c.N.
vec3 shade(Card c, vec3 colour, float metal, float gloss) {
  float glint = pow(max(dot(c.R, c.L), 0.), mix(GLINT_POWER_DULL, GLINT_POWER_GLOSSY, gloss)) * uLightIntensity;
  vec3 studio = env(c, c.R);
  vec3 dielectric = colour * (uAmbient + uLightColor * uLightIntensity * max(dot(c.N, c.L), 0.)) * DIFFUSE_GAIN
      + gloss * (studio * GLOSS_SHEEN + uLightColor * glint * GLOSS_GLINT);
  vec3 metallic = colour * (METAL_BASE + METAL_STUDIO * studio) + mix(colour, uLightColor, .5) * glint * METAL_GLINT;
  return mix(dielectric, metallic, metal);
}

// The card over the stage and its own shadow.
vec4 finish(Card c, vec3 col) {
  vec2 q = (c.sp - (CC + STAGE_CENTRE_SHIFT)) / STAGE_SIZE;
  vec3 stage = mix(STAGE_DARK, STAGE_LIGHT, clamp(1. - dot(q, q) * STAGE_FALLOFF, 0., 1.));
  vec2 so = -c.Ls.xy / max(c.Ls.z, SHADOW_LIGHT_FLOOR) * SHADOW_SHIFT;
  so *= min(1., SHADOW_SHIFT_MAX / max(length(so), .001));
  float sh = 1. - smoothstep(SHADOW_FROM, SHADOW_TO, sdBox(c.cp - CC - so, CARD * .5, SHADOW_ROUND));
  stage *= 1. - SHADOW_DARKEN * sh;
  return vec4(col * c.alpha + stage * (1. - c.alpha), 1.);
}

// ---- Wear and text ------------------------------------------------------------------

// 1 where the paint is still there.
float survive(Card c) {
  float u = c.wearOrder * c.chip;
  return smoothstep(-SURVIVE_BAND, 0., 1. - c.wear - u);
}

float scratchVis(Card c) {
  float s = c.grunge.y;
  return step(SCRATCH_FLOOR, s) * smoothstep(0., SCRATCH_BAND, s - 1. + c.wear * SCRATCH_REACH);
}

// The finished card colour at c: the surface worn through to under.png, dirt and scratches, the
// kana and badge, then the light.
vec3 shadeCard(inout Card c, Surface s) {
  vec3 under = texture(uUnder, c.uv).rgb;
  float keep = survive(c);
  vec3 col = mix(under, s.colour, keep);
  float metal = s.metal * keep, gloss = mix(UNDER_GLOSS, s.gloss, keep);
  c.N = normalize(mix(vec3(0., 0., 1.), s.n, keep));
  c.R = reflect(-c.V, c.N);

  col = mix(col, col * GRIME_TINT, c.wear * c.grunge.x * mix(GRIME_INTERIOR, 1., c.wearOrder) * GRIME_STRENGTH);
  float scratch = scratchVis(c) * SCRATCH_STRENGTH;
  col = mix(col, under, scratch);

  vec4 t = texture(uText, c.uv);
  float fade = 1. - TEXT_WEAR_FADE * c.wear * c.grunge.x;
  vec2 bt = texture(uBadgeText, c.uv).rg;
  float ink = t.r * fade, ring = bt.r * fade, numeral = bt.g * fade;
  col = mix(col, uInk, ink);
  col = mix(col, uBadge, ring);
  col = mix(col, uNumeral, numeral);
  float bare = max(scratch, max(ink, max(ring, numeral)));
  return shade(c, col, metal * (1. - bare), mix(gloss, UNDER_GLOSS, bare));
}
