#version 150

uniform sampler2D vColorBuffer_0;
uniform sampler2D vColorBuffer_1;
uniform sampler2D vColorBuffer_2;

uniform float osgppu_ViewportWidth;
uniform float osgppu_ViewportHeight;

in vec2 texCoord;
out vec4 fragColor;

const float radius = 4.0;

/*****************/
void main()
{
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    //fragColor += texture2D(vColorBuffer_0, texCoord);
    fragColor += texture2D(vColorBuffer_1, vec2(texCoord.x / 2.0, texCoord.y));
    fragColor += texture2D(vColorBuffer_2, vec2(texCoord.x / 2.0 + 0.5, texCoord.y));
}
