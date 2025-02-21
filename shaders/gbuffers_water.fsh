#version 120

uniform sampler2D texture; // Base water texture
uniform sampler2D lightmap; // Default Minecraft lightmap

varying vec2 texCoord;
varying float currWaveHeight;
varying vec2 lmCoord; // Lightmap coordinates

void main() {
    // Sample the base water color
  vec4 color = texture2D(texture, texCoord);

    // Calculate foam — only at wave peaks
  float foam = smoothstep(0.08, 0.1, abs(currWaveHeight));
  foam = clamp(foam, 0.0, 1.0);

    // Mix foam with water color
  vec3 foamColor = vec3(0.24, 0.0, 1.0);
  color.rgb = mix(color.rgb, foamColor, foam);

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
  vec2 lightCoord = lmCoord / 16.0; 

    // Sample Minecraft’s default lightmap
  vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft’s lighting
  color.rgb *= lightColor;

  gl_FragColor = color;
}