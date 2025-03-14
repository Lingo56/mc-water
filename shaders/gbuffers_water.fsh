#version 120

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 color;
varying float mat;
varying vec3 fragWorldPos;

void main() {
    // Sample base texture
    vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Check if this fragment belongs to water
    float water = float(mat > 0.98 && mat < 1.02);

    // Detect if it's a top face
    bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

    if(water > 0.5 && isTopFace) {
        // Use world position coordinates for seamless tiling
        vec2 worldCoord = fragWorldPos.xz; // Use xz plane for top faces
        
        // Adjust the scale of the noise texture
        float noiseScale = 0.02; // Smaller value for world coords (try 0.05-0.2)
        worldCoord *= noiseScale;
        
        // Simple scrolling of the noise texture
        float scrollSpeed = 0.005;
        vec2 scrolledCoord = worldCoord + vec2(frameTimeCounter * scrollSpeed, frameTimeCounter * scrollSpeed * 0.7);
        
        // Ensure coordinates wrap properly for seamless tiling
        scrolledCoord = fract(scrolledCoord);
        
        // Sample noise texture
        float noiseValue = texture2D(noisetex, scrolledCoord).r;
        
        // Make water brighter as noise approaches 100%
        vec3 waveColor = mix(albedo.rgb, vec3(1.0), noiseValue * 0.4);
        
        albedo.rgb = waveColor;
    }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
    vec2 lightCoord = lmCoord / 16.0;
    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft's lighting
    albedo.rgb *= lightColor;

    gl_FragColor = vec4(albedo.rgb, albedo.a);
}