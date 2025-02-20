#version 120

uniform sampler2D noise;
uniform int worldTime;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

varying vec2 texCoord;
varying float currWaveHeight;

void main() {
  texCoord = gl_MultiTexCoord0.st;

  // World position
  vec3 worldPos = gl_Vertex.xyz + cameraPosition;

  // Time calculation (smooth animation)
  float time = frameTimeCounter;

  // Time-based UV scrolling
  vec2 windA = vec2(time) * 0.04;  // Positive scrolling direction
  vec2 windB = vec2(-time) * 0.04; // Opposing scrolling direction

  // Offset the world position to animate the noise
  vec2 animatedPosA = worldPos.xz / 12.0 + windA;
  vec2 animatedPosB = worldPos.xz / 24.0 + windB;

  // Sample the noise textures
  float noiseA = texture2D(noise, animatedPosA).g;
  float noiseB = texture2D(noise, animatedPosB).g;

  // Mix the two noise values for smoother transitions
  float noiseValue = mix(noiseA, noiseB, 0.5);

  // Set wave height based purely on the noise value
  float maxWaveHeight = 0.25;
  currWaveHeight = noiseValue * maxWaveHeight;

  // Standard position transformation
  gl_Position = ftransform();

  // Apply vertical displacement based on the noise-driven wave height
  gl_Position.y += currWaveHeight - (maxWaveHeight * 0.5);
}