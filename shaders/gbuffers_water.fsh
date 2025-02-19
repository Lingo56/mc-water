#version 120

varying vec2 texCoord;
varying float currWaveHeight;

uniform sampler2D texture;

void main() {
  vec4 color = texture2D(texture, texCoord);

    // Add foam where waveHeight is close to the peak
  float foam = smoothstep(0.07, 0.1, abs(currWaveHeight)); // Control the foam range

    // Mix the foam color (white) with the water color
  vec3 foamColor = vec3(1.0); // White foam
  color.rgb = mix(color.rgb, foamColor, foam);

  gl_FragColor = color;
}