#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  
  // Scan lines moving up
  float scanline = sin(uv.y * 100.0 - u_time * 5.0) * 0.5 + 0.5;
  scanline = smoothstep(0.3, 0.7, scanline);
  
  // Hologram flicker
  float flicker = sin(u_time * 20.0) * 0.05 + 0.95;
  
  // Cyan/green hologram color
  vec3 color = vec3(0.0, 0.8, 0.8);
  color *= scanline * flicker;
  
  // Add some noise for glitch effect
  float noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + u_time) * 43758.5453);
  color += noise * 0.1;
  
  fragColor = vec4(color, 0.9); // Slightly transparent for hologram effect
}
