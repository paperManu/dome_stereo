#version 330 core
#extension GL_ARB_conservative_depth : enable

uniform sampler2D tex0;

in VertexData
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
} vertexIn;

layout(location = 0) out vec4 both;
layout(location = 1) out vec4 leftEye;
layout(location = 2) out vec4 rightEye;
layout(depth_greater) out float gl_FragDepth;

/**************/
void main()
{
    if (gl_PrimitiveID == 0)
    {
        both = vec4(vertexIn.normal, 1.0);
        leftEye = vec4(vertexIn.normal, 1.0) * vec4(1.0, 0.0, 0.0, 1.0);
        //leftEye = vec4(1.0, 0.0, 0.0, 1.0);
        rightEye = vec4(0.0);
    }
    else
    {
        both = vec4(vertexIn.normal, 1.0);
        leftEye = vec4(0.0);
        rightEye = vec4(vertexIn.normal, 1.0) * vec4(0.0, 1.0, 1.0, 1.0);
        //rightEye = vec4(0.0, 1.0, 1.0, 1.0);
    }
}
