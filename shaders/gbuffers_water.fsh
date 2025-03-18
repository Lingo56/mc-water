#version 120

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform sampler2D colortex5;       // Use this for caustics
uniform float frameTimeCounter;

varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 color;
varying float mat;
varying vec3 fragWorldPos;
varying vec3 viewPos;

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
        float noiseScale = 0.02; // Smaller value for world coords (try 0.05-0.2)
        worldCoord *= noiseScale;
        
        // DISPLACEMENT MAP - Using noisetex for displacement
        float displacementScale = 0.4; // Scale for displacement coords (smaller = larger features)
        vec2 displacementCoord = worldCoord * displacementScale;
        float displacementSpeed = 0.001; // Slower speed for more stable displacement
        vec2 scrolledDispCoord = displacementCoord + vec2(frameTimeCounter * displacementSpeed, -frameTimeCounter * displacementSpeed * 0.7);
        scrolledDispCoord = fract(scrolledDispCoord);
        
        // Sample displacement noise from noisetex
        vec2 displacement = texture2D(noisetex, scrolledDispCoord).rg * 2.0 - 1.0; // Convert to -1 to 1 range
        float displacementStrength = 0.03; // Adjust the strength of displacement
        
        // Apply displacement to the main noise coordinates
        vec2 displacedCoord = worldCoord + displacement * displacementStrength;
        
        // First noise layer - scrolling one direction (with displacement)
        float scrollSpeed = 0.0007;
        vec2 scrolledCoord1 = displacedCoord + vec2(frameTimeCounter * scrollSpeed, frameTimeCounter * scrollSpeed);
        scrolledCoord1 = fract(scrolledCoord1);
        
        // Use gaux1 or fallback to noisetex
        vec4 causticSample = texture2D(colortex5, scrolledCoord1);
        
        float sampleSum = causticSample.r + causticSample.g + causticSample.b + causticSample.a;
        
        if (sampleSum < 0.01) {
            // Fallback to noisetex
            causticSample = texture2D(noisetex, scrolledCoord1 * 2.37);
        }
        
        float noiseValue1 = causticSample.r;
        
        // Second noise layer - similar approach
        vec2 scrolledCoord2 = displacedCoord + vec2(-frameTimeCounter * scrollSpeed, frameTimeCounter * scrollSpeed);
        scrolledCoord2 = fract(scrolledCoord2);
        
        // Use gaux1 or fallback to noisetex
        causticSample = texture2D(colortex5, scrolledCoord2);
        
        sampleSum = causticSample.r + causticSample.g + causticSample.b + causticSample.a;
        
        if (sampleSum < 0.01) {
            // Fallback to noisetex
            causticSample = texture2D(noisetex, scrolledCoord2 * 0.79);
        }
        
        float noiseValue2 = causticSample.r;
        
        // Combine both noise patterns
        float combinedNoise = (noiseValue1 + noiseValue2) * 0.5;
        
        // Define two thresholds
        float lowerThreshold = 0.3;
        float upperThreshold = 0.8; // New higher threshold
        
        // Apply dual threshold system
        // Keep values below lowerThreshold and above upperThreshold
        float belowThreshold = combinedNoise * (1.0 - step(lowerThreshold, combinedNoise));
        float aboveThreshold = combinedNoise * step(upperThreshold, combinedNoise);
        
        // Combine both regions
        float thresholdedNoise = belowThreshold + aboveThreshold;
        
        // Optional: Apply different intensities to different regions
        vec3 lowNoiseColor = mix(waterBaseColor, vec3(0.8, 0.9, 1.0), belowThreshold * 1.2);
        vec3 highNoiseColor = mix(waterBaseColor, vec3(1.0), aboveThreshold * 1.5);
        
        // Blend based on which region has a non-zero value
        vec3 waveColor = mix(lowNoiseColor, highNoiseColor, step(0.01, aboveThreshold));
        
        // APPLY DISTANCE-BASED EFFECTS
        // Calculate distance from camera using viewPos
        float distanceToCamera = length(viewPos);
        
        // Adjust distance ranges based on Minecraft scale
        float minDistance = 8.0;   // Start transition at this distance
        float maxDistance = 40.0;   // Complete transition at this distance
        
        // Calculate transition factor (0.0 to 1.0) based on distance
        float transitionFactor = clamp((distanceToCamera - minDistance) / (maxDistance - minDistance), 0.0, 1.0);
        
        // Create a darker version of the base water color (not the wave color)
        // This ensures a flat, noiseless appearance at distance
        float darkenFactor = 0.7;
        vec3 distantColor = waterBaseColor * darkenFactor;
        
        // For distances beyond maxDistance, use the flat distant color with no wave patterns
        // For closer distances, use the wave color with darkening effect
        albedo.rgb = mix(waveColor, distantColor, transitionFactor);
    }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
    vec2 lightCoord = lmCoord / 16.0;
    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft's lighting
    albedo.rgb *= lightColor;

    gl_FragColor = vec4(albedo.rgb, albedo.a);
}