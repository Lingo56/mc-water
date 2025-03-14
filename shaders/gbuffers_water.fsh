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

    vec3 waterBaseColor = color.rgb;

    // Check if this fragment belongs to water
    float water = float(mat > 0.98 && mat < 1.02);

    // Detect if it's a top face
    bool isTopFace = abs(normalize(cross(dFdx(fragWorldPos), dFdy(fragWorldPos))).y) > 0.9;

    if(water > 0.5 && isTopFace) {
        // Use world position coordinates for seamless tiling
        vec2 worldCoord = fragWorldPos.xz; // Use xz plane for top faces
        
        // Adjust the scale of the noise texture
        float noiseScale = 0.1; // Smaller value for world coords (try 0.05-0.2)
        worldCoord *= noiseScale;
        
        // First noise layer - scrolling one direction
        float scrollSpeed = 0.02;
        vec2 scrolledCoord1 = worldCoord + vec2(frameTimeCounter * scrollSpeed, frameTimeCounter * scrollSpeed * 0.7);
        scrolledCoord1 = fract(scrolledCoord1);
        float noiseValue1 = texture2D(noisetex, scrolledCoord1).r;
        
        // Second noise layer - scrolling opposite direction
        vec2 scrolledCoord2 = worldCoord + vec2(-frameTimeCounter * scrollSpeed * 2, frameTimeCounter * scrollSpeed * 0.4);
        scrolledCoord2 = fract(scrolledCoord2);
        float noiseValue2 = texture2D(noisetex, scrolledCoord2).r;
        
        // Combine both noise patterns
        float combinedNoise = (noiseValue1 + noiseValue2) * 0.5;
        
        // Define two thresholds
        float lowerThreshold = 0.38;
        float upperThreshold = 0.7; // New higher threshold
        
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
        
        albedo.rgb = waveColor;
    }

    // Normalize lightmap coordinates (0-15 range → 0-1 range)
    vec2 lightCoord = lmCoord / 16.0;
    vec3 lightColor = texture2D(lightmap, lightCoord).rgb;

    // Apply Minecraft's lighting
    albedo.rgb *= lightColor;

    gl_FragColor = vec4(albedo.rgb, albedo.a);
}