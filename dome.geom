#version 330
#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_viewport_array : enable

#define PI 3.14159265358979
#define INVERT_DOME false
#define STEREO true

// Uniforms and inputs
uniform int vLevel;
uniform float vZFar;
uniform float vFOV;
uniform int vStereo;
uniform float vBaseline;

layout(triangles) in;
layout(triangle_strip, max_vertices = 32) out;
layout(invocations = 2) in;

// Input and output types
in VertexData
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
    vec4 diffuse;
} vertexIn[];

out VertexData
{
    vec2 texCoord;
    vec3 normal;
    vec4 diffuse;
} vertexOut;

// Types
struct Point
{
    vec4 vertex;
    vec2 texCoord;
    vec3 normal;
    vec4 diffuse;
};

// Declarations
void main();
void subdiv_l1(in Point p[3]);
void subdiv_l2(in Point p[3]);
void subdiv_l3(in Point p[3]);
void subdiv_l4(in Point p[3]);
void toSphere(inout Point p);
void toStereo(inout vec4 v);

// Utility functions
Point middleOf(in Point p, in Point q);
vec4 middleOf(in vec4 v, in vec4 w);
vec3 middleOf(in vec3 v, in vec3 w);
vec2 middleOf(in vec2 l, in vec2 m);
void emitVertex(in vec4 v, in vec2 s);

/***************/
Point middleOf(in Point p, in Point q)
{
    Point o;
    o.vertex = (p.vertex + q.vertex) * 0.5;
    o.texCoord = (p.texCoord + q.texCoord) * 0.5;
    o.normal = (p.normal + q.normal) * 0.5;
    o.diffuse = (p.diffuse + q.diffuse) * 0.5;
    return o;
}

/***************/
vec4 middleOf(in vec4 v, in vec4 w)
{
    return (v + w) * 0.5;
}

/***************/
vec3 middleOf(in vec3 v, in vec3 w)
{
    return (v + w) * 0.5;
}

/***************/
vec2 middleOf(in vec2 l, in vec2 m)
{
    return (l + m) * 0.5;
}

/***************/
void emitVertex(in Point p)
{
    gl_Position = p.vertex;
    vertexOut.texCoord = p.texCoord;
    vertexOut.normal = p.normal;
    vertexOut.diffuse = p.diffuse;
    gl_PrimitiveID = gl_InvocationID;
    EmitVertex();
}

/***************/
void toSphere(inout Point p)
{
    vec4 v = p.vertex;

    float val;
    vec4 o = vec4(1.0);

    float r = sqrt(pow(v.x, 2.0) + pow(v.y, 2.0) + pow(v.z, 2.0));
    val = clamp(v.z / r, -1.0, 1.0);
    float theta = acos(val);

    float phi;
    val = v.x / (r * sin(theta));
    float first = acos(clamp(val, -1.0, 1.0));
    val = v.y / (r * sin(theta));
    float second = asin(clamp(val, -1.0, 1.0));
    if (second >= 0.0)
        phi = first;
    else
        phi = 2.0*PI - first;
        
    if (vStereo == 1)
    {
        vec4 s = vec4(phi, theta, r, 1.0);
        toStereo(s);
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

    p.vertex = o;
}

/***************/
void toStereo(inout vec4 v)
{
    float b = vBaseline;
    float r = b * 30.0;

    float d = v.z; // * (1 - cos(v.y));
    float theta;
    if (gl_InvocationID == 0)
        theta = atan(b * (d - r) / (d * r));
    else
        theta = atan(-b * (d - r) / (d * r));

    v = vec4(v.x + theta, v.yzw);
}

/***************/
void main()
{
    if (vStereo != 1 && gl_InvocationID != 0)
        return;

    Point points[3];
    vec4 vertices[3];
    for (int i = 0; i < 3; ++i)
    {
        if (INVERT_DOME)
            points[i].vertex = vec4(vertexIn[i].vertex.x, vertexIn[i].vertex.y, -vertexIn[i].vertex.z, vertexIn[i].vertex.w);
        else
            points[i].vertex = vertexIn[i].vertex;

        points[i].texCoord = vertexIn[i].texCoord;
        points[i].normal = vertexIn[i].normal;
        points[i].diffuse = vertexIn[i].diffuse;
    }

    if (vLevel > 0)
    {
        subdiv_l1(points);
    }
    else
    {
        toSphere(points[0]);
        toSphere(points[1]);
        toSphere(points[2]);

        emitVertex(points[0]);
        emitVertex(points[1]);
        emitVertex(points[2]);
        EndPrimitive();
    }
}

/*************/
void subdiv_l1(in Point p[3])
{
    Point q[3];
    for (int i = 0; i < 3; ++i)
        q[i] = middleOf(p[i], p[(i+1)%3]);

    if (vLevel > 1)
    {
        for (int i = 0; i < 3; ++i)
        {
            Point r[3];
            r[0] = p[i];
            r[1] = q[i];
            r[2] = q[(i+2)%3];

            subdiv_l2(r);
        }

        subdiv_l2(q);
    }
    else
    {
        for (int i = 0; i < 3; ++i)
        {
            toSphere(p[i]);
            toSphere(q[i]);
        }

        emitVertex(p[0]);
        emitVertex(q[2]);
        emitVertex(q[0]);
        emitVertex(q[1]);
        emitVertex(p[1]);
        EndPrimitive();

        emitVertex(p[2]);
        emitVertex(q[2]);
        emitVertex(q[1]);
        EndPrimitive();
    }
}

/*************/
void subdiv_l2(in Point p[3])
{
    Point q[3];
    for (int i = 0; i < 3; ++i)
        q[i] = middleOf(p[i], p[(i+1)%3]);

    if (vLevel > 2)
    {
        for (int i = 0; i < 3; ++i)
        {
            Point r[3];
            r[0] = p[i];
            r[1] = q[i];
            r[2] = q[(i+2)%3];

            subdiv_l3(r);
        }

        subdiv_l3(q);
    }
    else
    {
        for (int i = 0; i < 3; ++i)
        {
            toSphere(p[i]);
            toSphere(q[i]);
        }

        emitVertex(p[0]);
        emitVertex(q[2]);
        emitVertex(q[0]);
        emitVertex(q[1]);
        emitVertex(p[1]);
        EndPrimitive();

        emitVertex(p[2]);
        emitVertex(q[2]);
        emitVertex(q[1]);
        EndPrimitive();
    }
}

/*************/
void subdiv_l3(in Point p[3])
{
    Point q[3];
    for (int i = 0; i < 3; ++i)
        q[i] = middleOf(p[i], p[(i+1)%3]);

    if (vLevel > 3)
    {
        for (int i = 0; i < 3; ++i)
        {
            Point r[3];
            r[0] = p[i];
            r[1] = q[i];
            r[2] = q[(i+2)%3];

            subdiv_l4(r);
        }

        subdiv_l4(q);
    }
    else
    {
        for (int i = 0; i < 3; ++i)
        {
            toSphere(p[i]);
            toSphere(q[i]);
        }

        emitVertex(p[0]);
        emitVertex(q[2]);
        emitVertex(q[0]);
        emitVertex(q[1]);
        emitVertex(p[1]);
        EndPrimitive();

        emitVertex(p[2]);
        emitVertex(q[2]);
        emitVertex(q[1]);
        EndPrimitive();
    }
}

/*************/
void subdiv_l4(in Point p[3])
{
    Point q[3];
    for (int i = 0; i < 3; ++i)
        q[i] = middleOf(p[i], p[(i+1)%3]);

    for (int i = 0; i < 3; ++i)
    {
        toSphere(p[i]);
        toSphere(q[i]);
    }

    emitVertex(p[0]);
    emitVertex(q[2]);
    emitVertex(q[0]);
    emitVertex(q[1]);
    emitVertex(p[1]);
    EndPrimitive();

    emitVertex(p[2]);
    emitVertex(q[2]);
    emitVertex(q[1]);
    EndPrimitive();
}
