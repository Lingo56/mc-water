#version 120

attribute vec4 mc_Entity; // Entity data, including block ID

uniform sampler2D noise;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

varying vec2 texCoord;
varying vec4 color;
varying float mat;
varying float currWaveHeight;

void main() {
  // World position
  vec3 worldPos = gl_Vertex.xyz + cameraPosition;
  color = gl_Color;

  // Set block IDs for water
  int blockID = int(mod(max(mc_Entity.x - 10000, 0), 10000));
  mat = 0.0;

  if (blockID == 300 || blockID == 304)
    mat = 1.0;
  if (blockID == 301)
    mat = 2.0;
  if (blockID == 302)
    mat = 3.0;
  if (blockID == 303)
    mat = 4.0;
  if (blockID == 400)
    mat = 5.0;

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
  currWaveHeight = (mat == 1.0) ? noiseValue * maxWaveHeight : 0.0;

  // Standard position transformation
  gl_Position = ftransform();

  // Apply vertical displacement based on the noise-driven wave height
  if (mat == 1.0) { // Only apply wave displacement for water
    gl_Position.y += currWaveHeight - (maxWaveHeight * 0.5);
  }

  texCoord = gl_MultiTexCoord0.xy;
}