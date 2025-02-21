#version 120

uniform sampler2D gtexture; // Base textures

varying vec2 texCoord;
varying vec4 color;
varying float mat; // Material identifier
varying float currWaveHeight;

void main() {
  // Sample base textures and colors
  vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

  // Check if the material is water (mat should be close to 1.0 for water)
  float water = float(mat > 0.98 && mat < 1.02);

  // Foam calculation — only apply to water (not ice)
  float foam = 0.0;
  if(water > 0.5) {
    foam = smoothstep(0.08, 0.1, abs(currWaveHeight));
    foam = clamp(foam, 0.0, 1.0);

    // Add foam effect only for water
    vec3 foamColor = vec3(1.0, 1.0, 1.0);
    albedo.rgb = mix(albedo.rgb, foamColor, foam);
  }

  gl_FragColor = vec4(albedo.rgb, albedo.a);  // For ice or other materials, no foam or changes

}