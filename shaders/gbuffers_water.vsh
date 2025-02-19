#version 120

uniform sampler2D noise;
uniform int worldTime;
uniform vec3 cameraPosition; // Custom uniform for world space approximation

varying vec2 texCoord;
varying float currWaveHeight;

void main() {
  texCoord = gl_MultiTexCoord0.st;

  // Approximate world position
  vec3 worldPos = gl_Vertex.xyz + cameraPosition;

  float time = float(worldTime) / 1000.0;
  vec2 flowDirection = vec2(0.02, 0.01);

  vec2 worldPosXZ = worldPos.xz;
  vec2 noiseUV = fract(worldPosXZ * 0.05 + time * flowDirection);

  float noiseValue = texture2D(noise, noiseUV).r;
  float maxWaveHeight = 0.5;

  currWaveHeight =
      (sin(time + noiseValue * 6.2831) * 0.5 + 0.5) * maxWaveHeight;

  vec4 pos = gl_Vertex;
  pos.y += currWaveHeight - maxWaveHeight - 0.1;

  gl_Position = ftransform();
}