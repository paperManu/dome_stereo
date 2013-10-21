#version 330 compatibility

in vec4 vVertex;
in vec2 vTexCoord;

uniform mat4 vMVP;

out VertexData
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
} vertexOut;

/***************/
void main()
{
    //gl_Position.xyz = (vMVP * vVertex).xyz;
    gl_Position = vec4(0.0, 0.0, 0.0, 1.0); //vVertex.xyz;

    vertexOut.vertex = (gl_ModelViewMatrix * gl_Vertex).xzyw; //vVertex.xyzw;
    //vertexOut.vertex = gl_Vertex;
    vertexOut.texCoord = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0); //vTexCoord;
    vertexOut.normal = vec3(0.0, 0.0, 1.0);

    //if (vVertex.x > 0.0 && vVertex.y > 0.0)
    //{
    //    vertexOut.vertex.x *= 1.25;
    //}
}
