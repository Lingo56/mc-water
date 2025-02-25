#version 120

uniform sampler2D gtexture;   // Base textures
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform sampler2D waterNormal;
uniform vec3 lightDir;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lmCoord; // Lightmap coordinates
varying vec4 color;
varying float mat;
varying vec3 fragWorldPos; // Pass world position to fragment shader

void main() {
    // Sample base texture
  vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Check if this fragment belongs to water
  float water = float(mat > 0.98 && mat < 1.02);

    // **Detect if it's a top face**
  bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

    // Apply wave effects **only on the top face**
  if(water > 0.5 && isTopFace) {
        // Scroll normal maps over time for wave animation
    vec2 waveOffsetA = vec2(frameTimeCounter) * 0.05;
    vec2 waveOffsetB = vec2(-frameTimeCounter) * 0.05;

    vec2 uvA = texCoord + waveOffsetA;
    vec2 uvB = texCoord - waveOffsetB;

        // Sample normal maps at two different offsets for better effect
    vec3 normalA = texture2D(waterNormal, uvA).rgb * 2.0 - 1.0;
    vec3 normalB = texture2D(waterNormal, uvB).rgb * 2.0 - 1.0;

        // Mix the two normals for smoother animation
    vec3 normal = normalize(mix(normalA, normalB, 0.5));

        // Adjust normal intensity
    normal.xy *= 0.5; // Scale down distortion to avoid excessive warping
    normal.z = sqrt(1.0 - dot(normal.xy, normal.xy)); // Keep Z normalized

        // Compute wave height using noise
    vec2 animatedPos = fragWorldPos.xz / 12.0 + waveOffsetA;
    float waveHeight = texture2D(noisetex, animatedPos).g * 0.2;

        // Foam effect at wave peaks
    float foam = smoothstep(0.08, 0.1, abs(waveHeight));
    foam = clamp(foam, 0.0, 1.0);
    vec3 foamColor = vec3(1.0, 1.0, 1.0);

    albedo.rgb = mix(albedo.rgb, foamColor, foam);
  }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
  vec2 lightCoord = lmCoord / 16.0; 

    // Sample Minecraft’s default lightmap
  vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft’s lighting
  albedo.rgb *= lightColor;

  gl_FragColor = vec4(albedo.rgb, albedo.a);
}