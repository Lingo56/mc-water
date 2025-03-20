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

// Apply displacement to world coordinates
vec2 calculateDisplacement(vec2 worldCoord) {
    float displacementScale = 0.04; // Scale for displacement coords
    vec2 displacementCoord = worldCoord * displacementScale;
    float displacementSpeed = 0.001; // Slower speed for more stable displacement
    vec2 scrolledDispCoord = displacementCoord + vec2(frameTimeCounter * displacementSpeed, 
                                                     -frameTimeCounter * displacementSpeed * 0.7);
    scrolledDispCoord = fract(scrolledDispCoord);
    
    // Sample displacement noise from noisetex
    vec2 displacement = texture2D(noisetex, scrolledDispCoord).rg * 2.0 - 1.0; // Convert to -1 to 1 range
    float displacementStrength = 0.6; // Adjust the strength of displacement
    
    // Return the displaced coordinates
    return worldCoord + displacement * displacementStrength;
}

// Calculate caustic pattern
vec3 calculateCaustics(vec2 worldCoord, vec3 waterBaseColor, bool useThreshold) {
    float scrollSpeed = 0.03;

    vec2 scrolledCoord1 = (worldCoord * 1.1) + vec2(frameTimeCounter * scrollSpeed, -frameTimeCounter * scrollSpeed * 0.7);
    scrolledCoord1 = fract(scrolledCoord1);
    float noiseValue1 = texture2D(colortex5, scrolledCoord1).r;
    
    // Second noise layer - scrolling opposite direction
    vec2 scrolledCoord2 = (worldCoord ) + vec2(-frameTimeCounter * scrollSpeed * 2, frameTimeCounter * scrollSpeed * 0.4);
    scrolledCoord2 = fract(scrolledCoord2);
    float noiseValue2 = texture2D(colortex5, scrolledCoord2).r;
    
    // Combine both noise patterns
    float combinedNoise = (noiseValue1 + noiseValue2) * 0.5;
    
    if (useThreshold) {
        // Original threshold behavior
        float lowerThreshold = 0.5;
        float upperThreshold = 0.76;
        
        // Apply dual threshold system
        float belowThreshold = combinedNoise * (1.0 - step(lowerThreshold, combinedNoise));
        float aboveThreshold = combinedNoise * step(upperThreshold, combinedNoise);
        
        // Apply different intensities to different regions
        vec3 lowNoiseColor = mix(waterBaseColor, vec3(0.8, 0.9, 1.0), belowThreshold * 0.5);
        vec3 highNoiseColor = mix(waterBaseColor, vec3(1.0), aboveThreshold * 1.5);
        
        // Blend based on which region has a non-zero value
        return mix(lowNoiseColor, highNoiseColor, step(0.01, aboveThreshold));
    } else {
        // Direct noise visualization without thresholds
        // Just apply the noise to water directly for debugging
        return mix(waterBaseColor, vec3(0.8, 0.9, 1.0), combinedNoise);
    }
}

// Apply distance-based effects with both near and far fading
vec3 applyDistanceFade(vec3 waveColor, vec3 waterBaseColor, vec3 viewPosition) {
    float distanceToCamera = length(viewPosition);
    
    // Near distance fading parameters
    float nearMinDistance = 3.5;   // Start near transition at this distance
    float nearMaxDistance = 16.0;   // Complete near transition at this distance
    
    // Far distance fading parameters
    float farMinDistance = 24.0;   // Start far transition at this distance
    float farMaxDistance = 48.0;   // Complete far transition at this distance
    
    // Calculate transition factors
    float nearTransition = 1.0 - clamp((distanceToCamera - nearMinDistance) / (nearMaxDistance - nearMinDistance), 0.0, 1.0);
    float farTransition = clamp((distanceToCamera - farMinDistance) / (farMaxDistance - farMinDistance), 0.0, 1.0);
    
    // Create target colors for the transitions
    vec3 nearColor = mix(waterBaseColor, vec3(waterBaseColor.rgb), 0.7); // Darker, more transparent near color
    vec3 farColor = waterBaseColor * 0.7; // Darker water in the distance
    
    // Apply both transitions
    vec3 result = waveColor;
    
    // Apply near transition first
    result = mix(result, nearColor, nearTransition);
    
    // Apply far transition second
    result = mix(result, farColor, farTransition);
    
    return result;
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
        
        // Adjust the scale of the noise texture
        float noiseScale = 0.125;
        worldCoord *= noiseScale;
        
        // Apply displacement to coordinates
        vec2 displacedCoord = calculateDisplacement(worldCoord);
        
        // Set to false to disable thresholds
        bool useThreshold = true; // Toggle this to enable/disable
        
        // Calculate caustic pattern using the new parameter
        vec3 waveColor = calculateCaustics(displacedCoord, waterBaseColor, useThreshold);
        
        // Apply distance-based fading
        albedo.rgb = applyDistanceFade(waveColor, waterBaseColor, viewPos);
    }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
    vec2 lightCoord = lmCoord / 16.0;
    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft's lighting
    albedo.rgb *= lightColor;

    gl_FragColor = vec4(albedo.rgb, albedo.a);
}