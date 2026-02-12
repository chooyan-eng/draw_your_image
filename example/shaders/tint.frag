// Runtime-effect style GLSL using Flutter helper. Produces an animated pattern.
#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms passed from Dart
uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  vec2 center = uv - 0.5;
  float dist = length(center);
  vec3 color = vec3(
    0.5 + 0.5 * sin(u_time + dist * 3.0),
    0.5 + 0.5 * sin(u_time + dist * 3.0 + 2.0),
    0.5 + 0.5 * sin(u_time + dist * 3.0 + 4.0)
  );
  fragColor = vec4(color, 1.0);
}
