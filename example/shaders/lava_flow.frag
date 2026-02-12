#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  
  // Create flowing pattern
  float flow = sin(uv.x * 5.0 + u_time) + 
               sin(uv.y * 7.0 - u_time * 0.7) +
               sin((uv.x + uv.y) * 3.0 + u_time * 0.5);
  
  // Normalize to 0-1 range
  flow = flow / 3.0 * 0.5 + 0.5;
  
  // Lava colors: dark red -> orange -> yellow
  vec3 color;
  if (flow < 0.3) {
    color = mix(vec3(0.2, 0.0, 0.0), vec3(1.0, 0.0, 0.0), flow / 0.3);
  } else if (flow < 0.7) {
    color = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.5, 0.0), (flow - 0.3) / 0.4);
  } else {
    color = mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 1.0, 0.0), (flow - 0.7) / 0.3);
  }
  
  fragColor = vec4(color, 1.0);
}
