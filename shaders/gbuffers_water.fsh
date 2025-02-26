#version 120

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform sampler2D waterNormal;
uniform vec3 lightDir;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 color;
varying float mat;
varying vec3 fragWorldPos;

vec3 FlowUVW(vec2 uv, vec2 flowVector, vec2 jump, float tiling, float time, bool flowB) {
  float phaseOffset = flowB ? 0.5 : 0;
  float progress = fract(time + phaseOffset);

  vec3 uvw;
  uvw.xy = uv - flowVector * progress;
  uvw.xy *= tiling;
  uvw.xy += phaseOffset;

  uvw.xy += (time - progress) * jump;
  uvw.z = 1 - abs(1 - 2 * progress);

  return uvw;
}

vec3 UnpackNormalGLSL(vec4 normalSample) {
  vec3 normal = normalSample.rgb * 2.0 - 1.0; // Remap from [0,1] to [-1,1]
  normal.z = sqrt(1.0 - clamp(dot(normal.xy, normal.xy), 0.0, 1.0)); // Reconstruct Z
  return normal;
}

// TODO: Not sure if this approach gets water that looks good.
// Need to find an approach that makes good water without normal maps and realtime light.
void main() {
    // Sample base texture
  vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Check if this fragment belongs to water
  float water = float(mat > 0.98 && mat < 1.02);

    // Detect if it's a top face
  bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

  vec3 finalNormal = vec3(0.0, 1.0, 0.0); // Default up-normal

  if(water > 0.5 && isTopFace) {
        // Sample the flow map to get flow direction
    vec2 flowVector = texture2D(noisetex, texCoord).rg * 2.0 - 1.0;
    flowVector *= 0.04;

    float noise = texture2D(noisetex, texCoord).a;
    float speed = 0.5;
    float time = (frameTimeCounter * speed) + noise;

    vec2 jump = vec2(0.1, 0.1);
    float tiling = 2.0;

    vec3 uvwA = FlowUVW(texCoord, flowVector, jump, tiling, time, false);
    vec3 uvwB = FlowUVW(texCoord, flowVector, jump, tiling, time, true);

    vec3 normalA = UnpackNormalGLSL(texture2D(waterNormal, uvwA.xy)) * uvwA.z;
    vec3 normalB = UnpackNormalGLSL(texture2D(waterNormal, uvwB.xy)) * uvwB.z;
    finalNormal = normalize(normalA + normalB); // Compute final normal

        // **Use Normal Height for Brightness**
    float waveHeight = clamp(finalNormal.z, 0.0, 1.0); // Keep in valid range
    vec3 waveColor = mix(albedo.rgb, vec3(1.0), waveHeight * 0.3); // Blend toward white

    albedo.rgb = waveColor;
  }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
  vec2 lightCoord = lmCoord / 16.0;
  vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft’s lighting
  albedo.rgb *= lightColor;

  gl_FragColor = vec4(albedo.rgb, albedo.a);
}