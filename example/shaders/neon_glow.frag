#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  vec2 center = vec2(0.5, 0.5);
  
  // Pulsing glow effect
  float pulse = sin(u_time * 3.0) * 0.3 + 0.7;
  
  // Distance from center for gradient
  float dist = length(uv - center);
  
  // Neon color (cyan/magenta)
  vec3 color1 = vec3(0.0, 1.0, 1.0); // Cyan
  vec3 color2 = vec3(1.0, 0.0, 1.0); // Magenta
  vec3 color = mix(color1, color2, sin(u_time + dist * 5.0) * 0.5 + 0.5);
  
  // Intensify the color for glow effect
  color *= pulse * 1.5;
  
  fragColor = vec4(color, 1.0);
}
