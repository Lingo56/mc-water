#version 120

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform sampler2D colortex5;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 color;
varying float mat;
varying vec3 fragWorldPos;
varying vec3 viewPos;

// STEP 1: Calculate wave noise
vec3 calculateCaustics(vec2 worldCoord, vec3 waterBaseColor) {
    return 0;
}

// STEP 2: Apply displacement to world coordinates
vec2 calculateDisplacement(vec2 worldCoord) {
    return 0;
}

// STEP 3: Fade nearby and at distance
vec3 applyDistanceFade(vec3 waveColor, vec3 waterBaseColor, vec3 viewPosition) {    
    return 0;
}

void main() {
    // Sample base texture
    vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);
    vec3 waterBaseColor = color.rgb;

    // Check if this fragment belongs to water
    float water = float(mat > 0.98 && mat < 1.02);

    // Detect if it's a top face
    bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

    if(water > 0.5 && isTopFace) {
        // Use world position coordinates for seamless tiling
        vec2 worldCoord = fragWorldPos.xz; // Use xz plane for top faces
        
        // Adjust the global scale of sampled textures
        float noiseScale = 0.125;
        worldCoord *= noiseScale;
        
        // Apply displacement to coordinates
        vec2 displacedCoord = calculateDisplacement(worldCoord);
        
        // Calculate caustic pattern using the new parameter
        vec3 waveColor = calculateCaustics(displacedCoord, waterBaseColor);
        
        // Apply distance-based fading
        albedo.rgb = waveColor;
    }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
    vec2 lightCoord = lmCoord / 16.0;
    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft's lighting
    albedo.rgb *= lightColor;

    gl_FragColor = vec4(albedo.rgb, albedo.a);
}