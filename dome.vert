#version 330 compatibility

out VertexData
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
    vec4 diffuse;
} vertexOut;

/***************/
void main()
{
    vertexOut.vertex = (gl_ModelViewMatrix * gl_Vertex).xzyw;
    vertexOut.texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
    vertexOut.normal = gl_NormalMatrix * gl_Normal; //vec3(0.0, 0.0, 1.0);

    vec3 n = vertexOut.normal;
    vec3 ldir = normalize(vertexOut.vertex.xyz - vec3(0.0, 0.0, 50.0));
    vertexOut.diffuse = gl_FrontMaterial.diffuse * max(-dot(n, ldir), 0.0);
}
