#version 460 core
#include <flutter/runtime_effect.glsl>
#include "common.glsl"

// @shader "Standard" The skin's image files stacked, lit and worn. Every skin uses it unless it needs an effect the files cannot hold.

void main() {
  Card c = cardSetup();
  if (c.alpha <= 0.) {
    outColor = finish(c, vec3(0.));
    return;
  }
  outColor = finish(c, shadeCard(c, cardSurface(c)));
}
