#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  
  // Wave effect based on position
  float wave = sin(uv.x * 10.0 + u_time * 2.0) * 0.5 + 0.5;
  
  // Rainbow colors cycling over time
  vec3 color = vec3(
    sin(u_time + uv.x * 3.0) * 0.5 + 0.5,
    sin(u_time + uv.x * 3.0 + 2.0) * 0.5 + 0.5,
    sin(u_time + uv.x * 3.0 + 4.0) * 0.5 + 0.5
  );
  
  // Apply wave modulation
  color *= wave;
  
  fragColor = vec4(color, 1.0);
}
