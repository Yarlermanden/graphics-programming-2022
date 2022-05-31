#version 330 core
layout (location = 0) in vec3 vertex;

uniform mat4 _rt_InvProj;
uniform mat4 _rt_InvView;
uniform mat4 _rt_View;
uniform vec3 Pos;

out vec3 _rt_viewPos;
out vec3 _rt_viewDir;

void main()
{
    vec4 viewPos = _rt_InvProj * vec4(vertex, 1.0f);
    //vec4 viewPos =  _rt_InvProj * vec4(vertex, 1.0f) * _rt_View;
    //vec4 viewPos =  _rt_InvProj * vec4(vertex, 1.0f) + _rt_View * vec4(1.0f);
    //vec4 viewPos =  (_rt_InvProj + _rt_View) * vec4(vertex, 1.0f);
    //_rt_viewPos = (viewPos.xyz / viewPos.w) + Pos;
    _rt_viewDir = viewPos.xyz / viewPos.w;
    _rt_viewPos = (viewPos.xyz / viewPos.w) + Pos;
    gl_Position = vec4(vertex, 1.0f);
}
