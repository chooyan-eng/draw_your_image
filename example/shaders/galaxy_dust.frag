#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

float random(vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  
  // Rotating effect
  float angle = u_time * 0.5;
  mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
  vec2 rotatedUV = rotation * (uv - 0.5) + 0.5;
  
  // Multiple layers of "stars"
  float stars = 0.0;
  for (float i = 1.0; i < 4.0; i++) {
    vec2 layer = rotatedUV * i * 10.0 + u_time * i * 0.1;
    float star = random(floor(layer));
    star = step(0.98, star);
    stars += star / i;
  }
  
  // Galaxy colors: purple -> blue -> pink
  vec3 color = vec3(
    0.5 + 0.5 * sin(u_time + uv.x * 2.0),
    0.3 + 0.3 * sin(u_time * 0.7 + uv.y * 2.0),
    0.8 + 0.2 * sin(u_time * 1.3)
  );
  
  color *= 0.3 + stars * 2.0;
  
  fragColor = vec4(color, 1.0);
}
