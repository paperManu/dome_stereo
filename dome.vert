#version 330 compatibility

out VertexData
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
} vertexOut;

/***************/
void main()
{
    vertexOut.vertex = (gl_ModelViewMatrix * gl_Vertex).xzyw;
    vertexOut.texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
    vertexOut.normal = gl_NormalMatrix * gl_Normal; //vec3(0.0, 0.0, 1.0);
}
