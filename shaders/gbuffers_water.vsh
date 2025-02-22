#version 120

attribute vec4 mc_Entity; // Entity data, including block ID

uniform vec3 cameraPosition;

varying vec2 texCoord;
varying vec2 lmCoord; // Lightmap coordinates
varying vec4 color;
varying float mat;
varying vec3 fragWorldPos; // Pass world position to fragment shader

void main() {
  // World position
  vec3 worldPos = gl_Vertex.xyz + cameraPosition;
  color = gl_Color;

  // Set block IDs for water
  int blockID = int(mod(max(mc_Entity.x - 10000, 0), 10000));
  mat = 0.0;

  if (blockID == 300 || blockID == 304)
    mat = 1.0; // Water
  if (blockID == 301)
    mat = 2.0; // Ice
  if (blockID == 302)
    mat = 3.0;
  if (blockID == 303)
    mat = 4.0;
  if (blockID == 400)
    mat = 5.0;

  fragWorldPos = worldPos; // Pass world position to fragment shader
  gl_Position = ftransform();
  lmCoord = gl_MultiTexCoord1.xy;
  texCoord = gl_MultiTexCoord0.xy;
}