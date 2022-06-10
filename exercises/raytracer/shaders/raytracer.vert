#version 330 core
layout (location = 0) in vec3 vertex;

uniform mat4 _rt_InvProj;
uniform mat4 _rt_Proj;
uniform mat4 _rt_InvView;
uniform mat4 _rt_View;
uniform mat3 rotation;

out vec3 _rt_viewPos;
out vec3 _rt_viewDir;

void main()
{
    vec4 viewPos = _rt_InvView * _rt_InvProj * vec4(vertex, 1.f);

    //I didn't find a way to compute direction using view matrix/inverse view matrix
    //Instead we compute direction of each pixel in camera and then rotate it according to the rotation matching LookAt
    vec4 viewDir = normalize(_rt_InvProj * vec4(vertex, 1.0f));
    _rt_viewDir = viewDir.xyz / viewDir.w;
    //_rt_viewDir = normalize(rotation * _rt_viewDir); //This needs to be using Dir as the offset and from there find in the direction of vertex
    vec4 x = _rt_InvView[0];
    vec4 y = _rt_InvView[1];
    vec4 z = _rt_InvView[2];
    mat3 rot = mat3(x.xyz, y.xyz, z.xyz);
    _rt_viewDir = normalize(rot * _rt_viewDir); //This needs to be using Dir as the offset and from there find in the direction of vertex

    _rt_viewPos = viewPos.xyz / viewPos.w;
    gl_Position = vec4(vertex, 1.0f);
}
