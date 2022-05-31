#version 330 core
layout (location = 0) in vec3 vertex;

uniform mat4 _rt_InvProj;
uniform mat4 _rt_Proj;
uniform mat4 _rt_InvView;
uniform mat4 _rt_View;
uniform vec3 Pos;
uniform vec3 Dir;

out vec3 _rt_viewPos;
out vec3 _rt_viewDir;

void main()
{
    /*
    vec4 viewPos = _rt_InvView * (_rt_InvProj * vec4(vertex, 1.0f)); // Calculates from view space to world space
    vec4 viewDir = _rt_InvView * (_rt_InvProj * vec4(vertex, 1.0f));
    */

    //This should capture the direction but not position:
    //The weird thing though is, moving a-d moves the view direction
    //vec4 viewPos = vec4(Pos, 1.f);
    //vec4 viewDir = _rt_InvView * (_rt_InvProj * vec4(vertex, 1.f));

    //This makes less sense, but work better:
    vec4 viewPos = _rt_InvView * vec4(1.0f);
    //vec4 viewDir = vec4(Dir, 1.f);
    //vec4 viewDir = vec4(Dir, 1.f) + vec4(vertex, 1.0f);
    //vec4 viewDir = _rt_InvProj * normalize(vec4(Dir, 1.f) + vec4(vertex, 1.0f));
    vec4 viewDir = normalize(vec4(Dir, 1.f) - normalize(_rt_InvProj * -vec4(vertex, 1.0f))); //This needs to be using Dir as the offset and from there find in the direction of vertex
    //vec4 viewDir = _rt_InvProj * (_rt_Proj * vec4(Dir, 1.f) + vec4(vertex, 1.f));

    _rt_viewDir = viewDir.xyz / viewDir.w;
    _rt_viewPos = viewPos.xyz/ viewPos.w;

    gl_Position = vec4(vertex, 1.0f);
}
