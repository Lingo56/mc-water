#version 120

uniform sampler2D gtexture; // Base water texture
uniform sampler2D lightmap; // Default Minecraft lightmap

varying vec2 texCoord;
varying vec2 lmCoord; // Lightmap coordinates
varying vec4 color;
varying float currWaveHeight;

void main() {
    // Sample the base water color
  vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Calculate foam — only at wave peaks
  float foam = smoothstep(0.08, 0.1, abs(currWaveHeight));
  foam = clamp(foam, 0.0, 1.0);

    // Mix foam with water color
  vec3 foamColor = vec3(1.0, 1.0, 1.0);
  albedo.rgb = mix(albedo.rgb, foamColor, foam);

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
  vec2 lightCoord = lmCoord / 16.0; 

    // Sample Minecraft’s default lightmap
  vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft’s lighting
  albedo.rgb *= lightColor;

  albedo.a = 0.8; // Ensure some transparency
  gl_FragColor = vec4(albedo.rgb, albedo.a);
}