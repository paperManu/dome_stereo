#version 330 compatibility
#extension GL_ARB_gpu_shader5 : enable

#define PI 3.14159265358979

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
    flat int eyeID;
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
void emitVertex(in vec4 v, in vec2 s)
{
    if (gl_InvocationID == 0)
        gl_Position = v;
    else
        gl_Position = v + vec4(0.1, 0.1, 0.1, 0.0);
    vertexOut.texCoord = s;
    vertexOut.eyeID = gl_InvocationID;
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

    o.x = theta * cos(phi);
    o.y = theta * sin(phi);
    o.y /= PI / (360.0 / vFOV);
    o.x /= PI / (360.0 / vFOV);
    o.z = r / vZFar;

    return o;
}

/***************/
void main()
{
    if (vLevel > 0)
    {
        vec4 vertices[3];
        for (int i = 0; i < 3; ++i)
            vertices[i] = vertexIn[i].vertex;

        vec2 s[3];
        for (int i = 0; i < 3; ++i)
            s[i] = vertexIn[i].texCoord;

        subdiv_l1(vertices, s);
    }
    else
    {
        vec4[3] vertices;
        for (int i = 0; i < 3; ++i)
            vertices[i] = vec4(0.0);

        //vertices[0] = gl_in[0].gl_Position;
        //vertices[1] = gl_in[1].gl_Position;
        //vertices[2] = gl_in[2].gl_Position;

        vertices[0] = toSphere(vertexIn[0].vertex);
        vertices[1] = toSphere(vertexIn[1].vertex);
        vertices[2] = toSphere(vertexIn[2].vertex);
        //vertices[2].x = 0.0;
        //vertices[2].y = 0.0;
        //vertices[2].z = -0.5;

        emitVertex(vertices[0], vertexIn[0].texCoord);
        emitVertex(vertices[1], vertexIn[1].texCoord);
        emitVertex(vertices[2], vertexIn[2].texCoord);
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
        // To the second level
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

        //{
        //    int i = gl_InvocationID;
        //    vec4 u[3];
        //    u[0] = v[i];
        //    u[1] = w[i];
        //    u[2] = w[(i+2)%3];

        //    vec2 r[3];
        //    r[0] = s[i];
        //    r[1] = t[i];
        //    r[2] = t[(i+2)%3];

        //    subdiv_l2(u, r);
        //}

        subdiv_l2(w, t);
    }
    else
    {
        //Projection of all points
        vec4 inputVert[3], newVert[3];
        inputVert[0] = toSphere(v[0]);
        inputVert[1] = toSphere(v[1]);
        inputVert[2] = toSphere(v[2]);
        newVert[0] = toSphere(w[0]);
        newVert[1] = toSphere(w[1]);
        newVert[2] = toSphere(w[2]);

        //inputVert[0] = toSphere(v[0]);
        //inputVert[1] = toSphere(v[1]);
        //inputVert[2] = toSphere(v[2]);
        //newVert[0] = toSphere(w[0]);
        //newVert[1] = toSphere(w[1]);
        //newVert[2] = w[2];

        emitVertex(inputVert[0], s[0]);
        emitVertex(newVert[2], t[2]);
        emitVertex(newVert[0], t[0]);
        emitVertex(newVert[1], t[1]);
        emitVertex(inputVert[1], s[1]);
        EndPrimitive();

        emitVertex(inputVert[2], s[2]);
        emitVertex(newVert[2], t[2]);
        emitVertex(newVert[1], t[1]);
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

        emitVertex(inputVert[0], s[0]);
        emitVertex(newVert[2], t[2]);
        emitVertex(newVert[0], t[0]);
        emitVertex(newVert[1], t[1]);
        emitVertex(inputVert[1], s[1]);
        EndPrimitive();

        emitVertex(inputVert[2], s[2]);
        emitVertex(newVert[2], t[2]);
        emitVertex(newVert[1], t[1]);
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

        emitVertex(inputVert[0], s[0]);
        emitVertex(newVert[2], t[2]);
        emitVertex(newVert[0], t[0]);
        emitVertex(newVert[1], t[1]);
        emitVertex(inputVert[1], s[1]);
        EndPrimitive();

        emitVertex(inputVert[2], s[2]);
        emitVertex(newVert[2], t[2]);
        emitVertex(newVert[1], t[1]);
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

    emitVertex(inputVert[0], s[0]);
    emitVertex(newVert[2], t[2]);
    emitVertex(newVert[0], t[0]);
    emitVertex(newVert[1], t[1]);
    emitVertex(inputVert[1], s[1]);
    EndPrimitive();

    emitVertex(inputVert[2], s[2]);
    emitVertex(newVert[2], t[2]);
    emitVertex(newVert[1], t[1]);
    EndPrimitive();
}
