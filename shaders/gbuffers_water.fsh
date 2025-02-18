#version 120

varying vec2 texCoord;
uniform sampler2D texture;

void main() {
  vec4 color = texture2D(texture, texCoord); // Get water texture color
  color.rgb *= vec3(1.0, 0.0, 0.0);         // Apply a blue tint effect
  gl_FragColor = color;
}