#version 120

uniform sampler2D texture;

varying vec2 texCoord;
varying float currWaveHeight;

void main() {
    // Sample the base water color
  vec4 color = texture2D(texture, texCoord);

    // Calculate foam — only at wave peaks
  float foam = smoothstep(0.08, 0.1, abs(currWaveHeight)); // Narrow foam range
  foam = clamp(foam, 0.0, 1.0);

    // Mix foam with water color, but only where foam is significant
  vec3 foamColor = vec3(1.0); // White foam
  color.rgb = mix(color.rgb, foamColor, foam);

  gl_FragColor = color;
}