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
    vec4 diffuse = vec4(0.0);

    for (int i = 0; i < 8; ++i)
    {
        vec3 lpos = gl_LightSource[i].position.xyz;
        vec3 ldir = normalize(vertexOut.vertex.xyz - lpos);
        diffuse += gl_FrontMaterial.diffuse * gl_LightSource[i].diffuse * max(-dot(n, ldir), 0.0);
    }

    vertexOut.diffuse = diffuse;
}
