#version 120

varying vec2 texCoord;

uniform int worldTime; // OptiFine passes this

void main() {
  // Standard position transformation
  gl_Position = ftransform();
  texCoord = gl_MultiTexCoord0.st;

  // Normalize worldTime to get smooth animation
  float time = float(worldTime) /
               1000.0; // Scale down the time (adjust the divisor for speed)

  // Apply sine wave to the Y position of the vertex for the wave effect
  float waveSpeed = 50;    // Control the speed of the wave
  float waveHeight = 0.25; // Control the height of the wave
  float wave = sin(texCoord.x * 10.0 + time * waveSpeed) * waveHeight;

  gl_Position.y += wave; // Add the wave displacement to the Y position
}