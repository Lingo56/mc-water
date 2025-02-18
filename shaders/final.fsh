#version 120

varying vec2 texCoord; // Receive texture coordinates from vertex shader
uniform sampler2D texture; // Minecraft’s main texture sampler

void main() {
  vec4 color = texture2D(texture, texCoord); // Sample the world texture
  gl_FragColor = color * vec4(0.5, 0.5, 1.0, 1.0); // Apply a blue tint
}