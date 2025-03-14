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

// Creates a more natural wave movement by combining multiple sine waves
vec2 createNaturalWave(float time) {
    // Primary wave motion - reduced frequencies
    vec2 wave1 = vec2(
        sin(time * 0.2) * 0.5, // reduced from 0.4 to 0.2
        cos(time * 0.15) * 0.3 // reduced from 0.3 to 0.15
    );
    
    // Secondary wave motion with different frequency - reduced frequencies
    vec2 wave2 = vec2(
        sin(time * 0.35 + 0.9) * 0.2, // reduced from 0.7 to 0.35
        cos(time * 0.3 + 1.2) * 0.2 // reduced from 0.6 to 0.3
    );
    
    // Tertiary small ripple effect - slightly reduced frequencies
    vec2 wave3 = vec2(
        sin(time * 0.7 + 0.5) * 0.1, // reduced from 1.1 to 0.7
        cos(time * 0.8 + 0.7) * 0.1 // reduced from 1.3 to 0.8
    );
    
    // Combine all waves
    return wave1 + wave2 + wave3;
}

void main() {
    // Sample base texture
    vec4 albedo = texture2D(gtexture, texCoord) * vec4(color.rgb, 1.0);

    // Check if this fragment belongs to water
    float water = float(mat > 0.98 && mat < 1.02);

    // Detect if it's a top face
    bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

    if(water > 0.5 && isTopFace) {
        // The color variable contains Minecraft's biome water color
        // Minecraft passes biome water coloring through the vertex color
        vec3 waterBaseColor = color.rgb;
        
        // Use world position coordinates for seamless tiling
        vec2 worldCoord = fragWorldPos.xz; // Use xz plane for top faces
        
        // Adjust the scale of the noise texture
        float noiseScale = 0.02; 
        worldCoord *= noiseScale;
        
        // Get composite wave motion
        vec2 waveOffset = createNaturalWave(frameTimeCounter);
        
        // Apply complex wave motion to coordinates with some base movement
        float baseScrollSpeed = 0.000000001;
        vec2 scrolledCoord = worldCoord + 
                            waveOffset * 0.008 +
                            vec2(frameTimeCounter * baseScrollSpeed, frameTimeCounter * baseScrollSpeed * 0.7);
        
        // Ensure coordinates wrap properly for seamless tiling
        scrolledCoord = fract(scrolledCoord);
        
        // Sample noise texture (single layer)
        float noiseValue = texture2D(noisetex, scrolledCoord).r;
        
        // Create a time-varying power exponent that oscillates between min and max values
        float minPower = 2.0;   // Minimum power (less pronounced effect)
        float maxPower = 3.0;   // Maximum power (more pronounced effect)
        float cycleSpeed = 0.5; // How fast the cycle completes (lower = slower)
        
        // Oscillate the power based on time
        float timeCycle = sin(frameTimeCounter * cycleSpeed) * 0.5 + 0.5; // 0 to 1 cycle
        float dynamicPower = mix(minPower, maxPower, timeCycle);
        
        // Apply the time-varying power to the noise
        float adjustedNoise = pow(noiseValue, dynamicPower);
        
        // Use the adjusted noise value with mixing
        vec3 waveColor = mix(waterBaseColor * 0.5, waterBaseColor * 1.5, adjustedNoise);
        
        albedo.rgb = waveColor;
    }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
    vec2 lightCoord = lmCoord / 16.0;
    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft's lighting
    albedo.rgb *= lightColor;

    gl_FragColor = vec4(albedo.rgb, albedo.a);
}