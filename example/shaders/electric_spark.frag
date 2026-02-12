#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

// Random function for spark effect
float random(vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  
  // Create electric spark pattern
  float spark = random(floor(uv * 20.0 + u_time * 5.0));
  spark = step(0.95, spark); // Only show brightest sparks
  
  // Electric blue-white color
  vec3 baseColor = vec3(0.2, 0.4, 1.0);
  vec3 sparkColor = vec3(0.8, 0.9, 1.0);
  
  vec3 color = mix(baseColor, sparkColor, spark);
  
  // Add some animation
  color *= sin(u_time * 10.0 + uv.x * 20.0) * 0.3 + 0.7;
  
  fragColor = vec4(color, 1.0);
}
