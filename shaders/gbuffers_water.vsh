#version 120

varying vec2 texCoord;
varying float currWaveHeight;

uniform int worldTime; // OptiFine passes this

void main() {
  // Standard position transformation
  gl_Position = ftransform();
  texCoord = gl_MultiTexCoord0.st;

  // Normalize worldTime to get smooth animation
  float time = float(worldTime) /
               1000.0; // Scale down the time (adjust the divisor for speed)

  // Apply sine wave to the Y position of the vertex for the wave effect
  float waveSpeed = 100;     // Control the speed of the wave
  float maxWaveHeight = 0.1; // Control the height of the wave
  currWaveHeight = sin(time * waveSpeed) * maxWaveHeight;

  gl_Position.y += currWaveHeight - maxWaveHeight -
                   0.1; // Add the wave displacement to the Y position
}