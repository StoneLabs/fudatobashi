#version 460 core
#include <flutter/runtime_effect.glsl>
#include "common.glsl"

// @shader "Brocade" The standard card with gold water that flows round the trim and maple leaves that drift along it, both bending round the corners.
// @animated

// @group Water
uniform sampler2D uWater; // @texture "Water" channels="R: water lines, first flow. G: water lines, second flow. Rows run from the card edge inward." fallback=black
uniform vec3 uGold;            // @colour "Gold" default=#C9A45A help="The colour of the water lines."
uniform float uWaterAmount[2]; // @number "Amount" range=0..1 step=0.01 default=0.9|0.6 labels=First flow|Second flow help="How strong each set of water lines is."
uniform float uWaterSpeed[2];  // @number "Flow speed" range=-60..60 step=0.1 unit=units/s default=8|5 labels=First flow|Second flow help="How fast each set of lines moves round the card, clockwise when positive."
uniform float uWaterRelief;    // @number "Relief" range=0..10 step=0.01 default=0.4 help="How much the lines stand out of the trim and catch the light. 0 is flat."

// @group Leaves
uniform sampler2D uLeaves;     // @texture "Leaves" channels="RGBA. Rows run from the card edge inward." fallback=transparent
uniform float uLeafSpeed;      // @number "Drift speed" range=-120..120 step=0.1 unit=units/s default=37 help="How fast the leaves move round the card, clockwise when positive. 37 is one lap in 44 seconds."
uniform float uLeafPhase;      // @random "Leaf position" x=0..1 help="Where the leaves start along the edge, as a share of one repeat."
uniform float uLeafOpacity;    // @number "Leaf opacity" range=0..1 step=0.01 default=1

// The paper of the card, in card units: the trim lies outside it.
const vec2 PAPER_CENTRE = vec2(187.02, 262.545), PAPER_SIZE = vec2(339.36, 485.79);

// A point on the centre loop's rounded rectangle, found in one quarter of the card.
// Returns x: arc length from the top centre going clockwise, y: distance to the loop (+ outward).
vec2 loopCoords(vec2 cp) {
  vec2 p = cp - CC, hi = CC - LOOP_INSET - LOOP_RADIUS, q = abs(p), v = q - hi;
  float quarter = hi.x + hi.y + 1.5707963 * LOOP_RADIUS, u, dist;
  if (v.x > 0. && v.y > 0.) {
    u = hi.x + LOOP_RADIUS * atan(v.x, v.y);
    dist = length(v) - LOOP_RADIUS;
  } else if (v.y > v.x) {
    u = min(q.x, hi.x);
    dist = v.y - LOOP_RADIUS;
  } else {
    u = hi.x + 1.5707963 * LOOP_RADIUS + hi.y - min(q.y, hi.y);
    dist = v.x - LOOP_RADIUS;
  }
  float s = p.x >= 0. ? (p.y < 0. ? u : 2. * quarter - u) : (p.y >= 0. ? 2. * quarter + u : 4. * quarter - u);
  return vec2(s, dist);
}

float loopLength() { return 4. * (CC.x + CC.y - 2. * (LOOP_INSET + LOOP_RADIUS)) + 6.2831853 * LOOP_RADIUS; }
// The water strip's length along the loop: WATER_UNITS, stretched so a whole number of repeats closes the loop.
float waterUnit() { return loopLength() / max(floor(loopLength() / WATER_UNITS + .5), 1.); }

// The water lines at a card point: x first flow, y second flow, both 0 outside the strip.
vec2 waterAt(vec2 cp, float lod) {
  vec2 sd = loopCoords(cp);
  float inset = LOOP_INSET - sd.y, v = inset / WATER_DEPTH;
  float inside = step(0., v) * step(v, 1.);
  vec2 u = (sd.x - vec2(uWaterSpeed[0], uWaterSpeed[1]) * uTime) / waterUnit();
  float a = textureLod(uWater, vec2(fract(u.x), v), lod).r, b = textureLod(uWater, vec2(fract(u.y), v), lod).g;
  return vec2(a * uWaterAmount[0], b * uWaterAmount[1]) * inside;
}

// The paper is the card inside the trim: 1 on the paper, 0 on the trim, antialiased.
float paperMask(Card c) {
  vec2 d = abs(c.cp - PAPER_CENTRE) - PAPER_SIZE * .5;
  return 1. - smoothstep(-.5 * c.aa, .5 * c.aa, max(d.x, d.y));
}

void main() {
  Card c = cardSetup();
  if (c.alpha <= 0.) {
    outColor = finish(c, vec3(0.));
    return;
  }
  Surface s = cardSurface(c);
  float trim = 1. - paperMask(c);
  float lod = max(log2(c.aa * WATER_TEXELS_PER_UNIT), 0.);

  vec2 w = waterAt(c.cp, lod);
  float gold = clamp(max(w.x, w.y), 0., 1.) * trim;
  vec2 e = vec2(WATER_RELIEF_STEP, 0.);
  vec2 slope = vec2(dot(waterAt(c.cp - e.xy, lod), vec2(1.)) - dot(waterAt(c.cp + e.xy, lod), vec2(1.)),
                    dot(waterAt(c.cp - e.yx, lod), vec2(1.)) - dot(waterAt(c.cp + e.yx, lod), vec2(1.)));
  vec3 n = normalize(vec3(slope * uWaterRelief, 1.));
  s.colour = mix(s.colour, uGold, gold);
  s.metal = mix(s.metal, 1., gold);
  s.gloss = mix(s.gloss, WATER_GOLD_GLOSS, gold);
  s.n = normalize(mix(s.n, n, gold));

  vec2 sd = loopCoords(c.cp);
  float inLeaves = step(0., LOOP_INSET - sd.y) * step(LOOP_INSET - sd.y, LEAVES_DEPTH);
  float leafU = fract((sd.x - uLeafSpeed * uTime) / (loopLength() * .5) + uLeafPhase);
  vec4 leaf = textureLod(uLeaves, vec2(leafU, (LOOP_INSET - sd.y) / LEAVES_DEPTH), lod) * uLeafOpacity * inLeaves;
  s.colour = s.colour * (1. - leaf.a) + leaf.rgb;
  s.metal *= 1. - leaf.a;
  s.gloss = mix(s.gloss, UNDER_GLOSS, leaf.a);
  s.n = normalize(mix(s.n, vec3(0., 0., 1.), leaf.a));

  outColor = finish(c, shadeCard(c, s));
}
