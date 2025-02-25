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

vec3 FlowUVW(vec2 uv, vec2 flowVector, float time, bool flowB) {
  float phaseOffset = flowB ? 0.5 : 0;
  float noise = texture2D(noisetex, texCoord).a;
  float progress = fract(time + phaseOffset + noise);

  vec3 uvw;
  uvw.xy = uv - flowVector * progress;
  uvw.z = 1 - abs(1 - 2 * progress);

  return uvw;
}

void main() {
    // Sample base texture
  vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Check if this fragment belongs to water
  float water = float(mat > 0.98 && mat < 1.02);

    // **Detect if it's a top face**
  bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

    // Apply wave effects **only on the top face**
  if(water > 0.5 && isTopFace) {
        // Sample the flow map to get flow direction (similar to Unity's tex2D)
    vec2 flowVector = texture2D(noisetex, texCoord).rg * 2.0 - 1.0;
    flowVector *= 0.06; // Scale down the flow strength

    vec3 uvwA = FlowUVW(texCoord, flowVector, frameTimeCounter, false);
    vec3 uvwB = FlowUVW(texCoord, flowVector, frameTimeCounter, true);

    vec4 texA = texture2D(gtexture, uvwA.xy) * uvwA.z;
    vec4 texB = texture2D(gtexture, uvwB.xy) * uvwB.z;

        // Sample the texture with the animated UVs
    vec4 c = (texA + texB) * vec4(color.rgb, 1.0);

    // **Alternative to foam: blend with a highlight color**
    float highlight = smoothstep(0.2, 0.8, length(flowVector));
    vec3 highlightColor = vec3(0.8, 0.9, 1.0); // Light blue highlight
    albedo.rgb = mix(c.rgb, highlightColor, highlight * 0.2); // 20% blend
  }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
  vec2 lightCoord = lmCoord / 16.0; 

    // Sample Minecraft’s default lightmap
  vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft’s lighting
  albedo.rgb *= lightColor;

  gl_FragColor = vec4(albedo.rgb, albedo.a);
}