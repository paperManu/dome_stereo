#version 330 core

uniform sampler2D tex0;

in VertexData
{
    vec2 texCoord;
    vec3 normal;
} vertexIn;

layout(location = 0) out vec4 leftEye;
layout(location = 1) out vec4 rightEye;

/**************/
void main()
{
    if (gl_PrimitiveID == 0)
    {
        leftEye = vec4(1.0, 0.0, 0.0, 1.0);
        rightEye = vec4(0.0);
    }
    else
    {
        leftEye = vec4(0.0);
        rightEye = vec4(0.0, 1.0, 1.0, 1.0);
    }
}
