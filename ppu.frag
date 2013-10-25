#version 150

#define INV_PATTERN_WIDTH 3.0
#define DISPLAY_PATTERN false
#define PATTERN_FOV 180.0

uniform sampler2D vColorBuffer_0;
uniform sampler2D vColorBuffer_1;
uniform sampler2D vColorBuffer_2;

uniform float osgppu_ViewportWidth;
uniform float osgppu_ViewportHeight;

in vec2 texCoord;
out vec4 fragColor;

const float radius = 4.0;

/***************/
vec4 drawPattern()
{
    vec4 c = vec4(0.0);
    float dist = length (texCoord - vec2(0.5, 0.5));
    dist *= PATTERN_FOV * INV_PATTERN_WIDTH;
    if (int(dist) % int(10.0 * INV_PATTERN_WIDTH) < 1)
        c = vec4(1.0);

    return c;
}

/*****************/
void main()
{
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    //fragColor += texture2D(vColorBuffer_0, texCoord);
    fragColor += texture2D(vColorBuffer_1, vec2(texCoord.x / 2.0, texCoord.y)) * vec4(1.0, 0.0, 0.0, 1.0);
    fragColor += texture2D(vColorBuffer_2, vec2(texCoord.x / 2.0 + 0.5, texCoord.y)) * vec4(0.0, 1.0, 1.0, 1.0);

    if (DISPLAY_PATTERN)
        fragColor += drawPattern();
}
