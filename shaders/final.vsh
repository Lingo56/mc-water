#version 120

varying vec2 texCoord; // Pass texture coordinates to fragment shader

void main() {
  gl_Position = ftransform();      // Standard transformation
  texCoord = gl_MultiTexCoord0.st; // Get texture coordinates from Minecraft
}