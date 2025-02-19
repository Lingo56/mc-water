#version 120

uniform sampler2D noise;
uniform int worldTime;
uniform vec3 cameraPosition;

varying vec2 texCoord;
varying float currWaveHeight;

void main() {
  texCoord = gl_MultiTexCoord0.st;

  // World position
  vec3 worldPos = gl_Vertex.xyz + cameraPosition;

  // Time calculation (smooth animation)
  float time = float(worldTime) / 1000.0;
  vec2 flowDirection = vec2(0.02, 0.01);

  // Domain warping (reduces repetitive bands)
  vec2 offsetUV = worldPos.xz * 0.04;
  vec2 warp = texture2D(noise, fract(offsetUV)).rg * 0.1 - 0.05;

  // Animated noise UVs (smooth wave motion)
  vec2 animatedUV = worldPos.xz * 0.05 + time * flowDirection + warp;
  float noiseValue = texture2D(noise, fract(animatedUV)).r;

  // Wave height calculation (noise + time-based motion)
  float maxWaveHeight = 0.1; // Control the height of the wave
  currWaveHeight = sin(noiseValue * time * 100) * maxWaveHeight;

  // Standard position transformation
  gl_Position = ftransform();

  // Apply vertical displacement based on the noise-driven wave height
  gl_Position.y += currWaveHeight - (maxWaveHeight * 0.5);
}