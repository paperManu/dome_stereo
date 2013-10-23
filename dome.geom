#version 330
#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_viewport_array : enable

#define PI 3.14159265358979
#define INVERT_DOME false
#define BASELINE 0.065
#define RADIUS 2
#define STEREO true

// Uniforms and inputs
uniform int vPass;
uniform int vLevel;
uniform float vZFar;
uniform float vFOV;

layout(triangles) in;
layout(triangle_strip, max_vertices = 128) out;
layout(invocations = 2) in;

// Input and output types
in VertexData
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
} vertexIn[];

out VertexData
{
    vec2 texCoord;
    vec3 normal;
} vertexOut;

// Declarations
void main();
void subdiv_l1(in vec4 v[3], in vec2 s[3]);
void subdiv_l2(in vec4 v[3], in vec2 s[3]);
void subdiv_l3(in vec4 v[3], in vec2 s[3]);
void subdiv_l4(in vec4 v[3], in vec2 s[3]);
vec4 toSphere(in vec4 v);
vec4 toStereo(in vec4 v);

// Utility functions
float clampUnit(in float v);
vec4 middleOf(in vec4 v, in vec4 w);
vec2 middleOf(in vec2 l, in vec2 m);
void emitVertex(in vec4 v, in vec2 s);

/***************/
float clampUnit(in float v)
{
    return max(-1.0, min(1.0, v));
}

/***************/
vec4 middleOf(in vec4 v, in vec4 w)
{
    return (v + w) * 0.5;
}

/***************/
vec2 middleOf(in vec2 l, in vec2 m)
{
    return (l + m) * 0.5;
}

/***************/
void emitVertex(in vec4 v, in vec2 s, in vec3 n)
{
    gl_Position = v;
    vertexOut.texCoord = s;
    vertexOut.normal = n;
    gl_PrimitiveID = gl_InvocationID;
    EmitVertex();
}

/***************/
vec4 toSphere(in vec4 v)
{
    float val;
    vec4 o = vec4(1.0);

    float r = sqrt(pow(v.x, 2.0) + pow(v.y, 2.0) + pow(v.z, 2.0));
    val = clampUnit(v.z / r);
    float theta = acos(val);

    float phi;
    val = v.x / (r * sin(theta));
    float first = acos(clampUnit(val));
    val = v.y / (r * sin(theta));
    float second = asin(clampUnit(val));
    if (second >= 0.0)
        phi = first;
    else
        phi = 2.0*PI - first;
        
    if (STEREO)
    {
        vec4 s = toStereo(vec4(phi, theta, r, 1.0));
        phi = s.x;
        theta = s.y;
        r = s.z;
    }

    o.x = theta * cos(phi);
    o.y = theta * sin(phi);
    o.y /= PI / (360.0 / vFOV);
    o.x /= PI / (360.0 / vFOV);
    o.z = r / vZFar;

    // Small work around to the depth testing which hides duplicate objects...
    if (gl_InvocationID == 0)
        o.x = o.x / 2.0 - 0.5;
    else
        o.x = o.x / 2.0 + 0.5;

    return o;
}

/***************/
vec4 toStereo(in vec4 v)
{
    float b = BASELINE;
    float r = RADIUS;

    float d = v.z; // * (1 - cos(v.y));
    float theta;
    if (gl_InvocationID == 0)
        theta = atan(b * (d - r) / (d * r));
    else
        theta = atan(-b * (d - r) / (d * r));

    vec4 s = vec4(v.x + theta, v.yzw);
    return s;
}

/***************/
void main()
{
    vec4 vertices[3];
    for (int i = 0; i < 3; ++i)
        if (INVERT_DOME)
            vertices[i] = vec4(vertexIn[i].vertex.x, vertexIn[i].vertex.y, -vertexIn[i].vertex.z, vertexIn[i].vertex.w);
        else
            vertices[i] = vertexIn[i].vertex;

    if (vLevel > 0)
    {


        vec2 s[3];
        for (int i = 0; i < 3; ++i)
            s[i] = vertexIn[i].texCoord;

        subdiv_l1(vertices, s);
    }
    else
    {
        vertices[0] = toSphere(vertices[0]);
        vertices[1] = toSphere(vertices[1]);
        vertices[2] = toSphere(vertices[2]);

        emitVertex(vertices[0], vertexIn[0].texCoord, vertexIn[0].normal);
        emitVertex(vertices[1], vertexIn[1].texCoord, vertexIn[1].normal);
        emitVertex(vertices[2], vertexIn[2].texCoord, vertexIn[2].normal);
        EndPrimitive();

    }
}

/*************/
void subdiv_l1(in vec4 v[3], in vec2 s[3])
{
    vec4 w[3];
    w[0] = middleOf(v[0], v[1]);
    w[1] = middleOf(v[1], v[2]);
    w[2] = middleOf(v[2], v[0]);
    vec2 t[3];
    t[0] = middleOf(s[0], s[1]);
    t[1] = middleOf(s[1], s[2]);
    t[2] = middleOf(s[2], s[0]);

    if (vLevel > 1)
    {
        for (int i = 0; i < 3; ++i)
        {
            vec4 u[3];
            u[0] = v[i];
            u[1] = w[i];
            u[2] = w[(i+2)%3];

            vec2 r[3];
            r[0] = s[i];
            r[1] = t[i];
            r[2] = t[(i+2)%3];

            subdiv_l2(u, r);
        }

        subdiv_l2(w, t);
    }
    else
    {
        vec4 inputVert[3], newVert[3];
        inputVert[0] = toSphere(v[0]);
        inputVert[1] = toSphere(v[1]);
        inputVert[2] = toSphere(v[2]);
        newVert[0] = toSphere(w[0]);
        newVert[1] = toSphere(w[1]);
        newVert[2] = toSphere(w[2]);

        emitVertex(inputVert[0], s[0], vec3(1.0));
        emitVertex(newVert[2], t[2], vec3(1.0));
        emitVertex(newVert[0], t[0], vec3(1.0));
        emitVertex(newVert[1], t[1], vec3(1.0));
        emitVertex(inputVert[1], s[1], vec3(1.0));
        EndPrimitive();

        emitVertex(inputVert[2], s[2], vec3(1.0));
        emitVertex(newVert[2], t[2], vec3(1.0));
        emitVertex(newVert[1], t[1], vec3(1.0));
        EndPrimitive();
    }
}

/*************/
void subdiv_l2(in vec4 v[3], in vec2 s[3])
{
    vec4 w[3];
    w[0] = middleOf(v[0], v[1]);
    w[1] = middleOf(v[1], v[2]);
    w[2] = middleOf(v[2], v[0]);
    vec2 t[3];
    t[0] = middleOf(s[0], s[1]);
    t[1] = middleOf(s[1], s[2]);
    t[2] = middleOf(s[2], s[0]);

    if (vLevel > 2)
    {
        // To the third level
        for (int i = 0; i < 3; ++i)
        {
            vec4 u[3];
            u[0] = v[i];
            u[1] = w[i];
            u[2] = w[(i+2)%3];

            vec2 r[3];
            r[0] = s[i];
            r[1] = t[i];
            r[2] = t[(i+2)%3];

            subdiv_l3(u, r);
        }

        subdiv_l3(w, t);
    }
    else
    {
        // Projection of all points
        vec4 inputVert[3], newVert[3];
        inputVert[0] = toSphere(v[0]);
        inputVert[1] = toSphere(v[1]);
        inputVert[2] = toSphere(v[2]);
        newVert[0] = toSphere(w[0]);
        newVert[1] = toSphere(w[1]);
        newVert[2] = toSphere(w[2]);

        emitVertex(inputVert[0], s[0], vec3(1.0));
        emitVertex(newVert[2], t[2], vec3(1.0));
        emitVertex(newVert[0], t[0], vec3(1.0));
        emitVertex(newVert[1], t[1], vec3(1.0));
        emitVertex(inputVert[1], s[1], vec3(1.0));
        EndPrimitive();

        emitVertex(inputVert[2], s[2], vec3(1.0));
        emitVertex(newVert[2], t[2], vec3(1.0));
        emitVertex(newVert[1], t[1], vec3(1.0));
        EndPrimitive();
    }
}

/*************/
void subdiv_l3(in vec4 v[3], in vec2 s[3])
{
    vec4 w[3];
    w[0] = middleOf(v[0], v[1]);
    w[1] = middleOf(v[1], v[2]);
    w[2] = middleOf(v[2], v[0]);
    vec2 t[3];
    t[0] = middleOf(s[0], s[1]);
    t[1] = middleOf(s[1], s[2]);
    t[2] = middleOf(s[2], s[0]);

    if (vLevel > 3)
    {
        // To the third level
        for (int i = 0; i < 3; ++i)
        {
            vec4 u[3];
            u[0] = v[i];
            u[1] = w[i];
            u[2] = w[(i+2)%3];

            vec2 r[3];
            r[0] = s[i];
            r[1] = t[i];
            r[2] = t[(i+2)%3];

            subdiv_l4(u, r);
        }

        subdiv_l4(w, t);
    }
    else
    {
        // Projection of all points
        vec4 inputVert[3], newVert[3];
        inputVert[0] = toSphere(v[0]);
        inputVert[1] = toSphere(v[1]);
        inputVert[2] = toSphere(v[2]);
        newVert[0] = toSphere(w[0]);
        newVert[1] = toSphere(w[1]);
        newVert[2] = toSphere(w[2]);

        emitVertex(inputVert[0], s[0], vec3(1.0));
        emitVertex(newVert[2], t[2], vec3(1.0));
        emitVertex(newVert[0], t[0], vec3(1.0));
        emitVertex(newVert[1], t[1], vec3(1.0));
        emitVertex(inputVert[1], s[1], vec3(1.0));
        EndPrimitive();

        emitVertex(inputVert[2], s[2], vec3(1.0));
        emitVertex(newVert[2], t[2], vec3(1.0));
        emitVertex(newVert[1], t[1], vec3(1.0));
        EndPrimitive();
    }
}

/*************/
void subdiv_l4(in vec4 v[3], in vec2 s[3])
{
    vec4 w[3];
    w[0] = middleOf(v[0], v[1]);
    w[1] = middleOf(v[1], v[2]);
    w[2] = middleOf(v[2], v[0]);
    vec2 t[3];
    t[0] = middleOf(s[0], s[1]);
    t[1] = middleOf(s[1], s[2]);
    t[2] = middleOf(s[2], s[0]);


    // Projection of all points
    vec4 inputVert[3], newVert[3];
    inputVert[0] = toSphere(v[0]);
    inputVert[1] = toSphere(v[1]);
    inputVert[2] = toSphere(v[2]);
    newVert[0] = toSphere(w[0]);
    newVert[1] = toSphere(w[1]);
    newVert[2] = toSphere(w[2]);

    emitVertex(inputVert[0], s[0], vec3(1.0));
    emitVertex(newVert[2], t[2], vec3(1.0));
    emitVertex(newVert[0], t[0], vec3(1.0));
    emitVertex(newVert[1], t[1], vec3(1.0));
    emitVertex(inputVert[1], s[1], vec3(1.0));
    EndPrimitive();

    emitVertex(inputVert[2], s[2], vec3(1.0));
    emitVertex(newVert[2], t[2], vec3(1.0));
    emitVertex(newVert[1], t[1], vec3(1.0));
    EndPrimitive();
}
