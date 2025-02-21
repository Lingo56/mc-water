#version 120

uniform sampler2D gtexture; // Base textures

varying vec2 texCoord;
varying vec4 color;
varying float currWaveHeight;

void main() {
  // Sample base textures and colors
  vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Calculate foam — only at wave peaks
  float foam = smoothstep(0.08, 0.1, abs(currWaveHeight));
  foam = clamp(foam, 0.0, 1.0);

    // Add foam to albedo
  vec3 foamColor = vec3(1.0, 1.0, 1.0);
  albedo.rgb = mix(albedo.rgb, foamColor, foam);

  // Apply albedo to game
  gl_FragColor = vec4(albedo.rgb, albedo.a);
}