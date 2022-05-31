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
    vec4 viewPos = _rt_InvView * (_rt_InvProj * vec4(vertex, 1.0f)); // Calculates from view space to world space
    //vec4 viewPos = _rt_InvProj * vec4(vertex, 1.0f);
    //viewPos *= vec4(Pos, 1.f);



    //vec4 viewPos = vec4(Pos, 1.f);

    //vec4 viewDir = vec4(Dir, 1.f);

    //vec4 viewDir = _rt_InvProj * vec4(vertex, 1.0f); //Used to convert view space into model space
    vec4 viewDir = _rt_InvView * (_rt_InvProj * vec4(vertex, 1.0f));

    //vec4 viewDir = _rt_InvView * _rt_InvProj * vec4(vertex, 1.0f);
    //vec4 viewDir = _rt_InvProj * vec4(vertex, 1.0f) * vec4(normalize(Dir), 1.f);
    //vec4 viewDir = _rt_InvProj * vec4(vertex, 1.0f) ;
    //vec4 viewDir = _rt_InvProj * vec4(vertex, 1.0f) * vec4(normalize(vec3(_rt_View[3].xyz)), 1.f);
    //vec4 viewDir = _rt_InvProj * vec4(vertex, 1.0f) * vec4(normalize(_rt_InvView[1] + _rt_InvView[2] + _rt_InvView[3]));

    //vec4 viewDir = _rt_InvProj * _rt_InvView * vec4(vertex, 1.0f);
    //vec4 viewDir = _rt_View * vec4(vertex, 1.0f);
    //vec4 viewDir = _rt_InvView * _rt_InvProj * vec4(vertex, 1.0f);



    //vec4 viewDir = _rt_InvProj * (_rt_View * vec4(vertex, 1.0f));
    //vec4 viewDir = _rt_InvView * vec4(vertex, 1.f);

    //vec4 viewDir = _rt_InvProj *  vec4(vertex, 1.0f) * _rt_View;
    //vec4 viewDir = _rt_View * vec4(vertex, 1.0f);

    //vec4 viewDir = _rt_View * vec4(vertex, 1.0f);
    //vec4 viewDir = _rt_Proj * vec4(Dir, 1.f) * vec4(vertex, 1.0f);

    _rt_viewDir = viewDir.xyz / viewDir.w;
    _rt_viewPos = viewPos.xyz/ viewPos.w;



    gl_Position = vec4(vertex, 1.0f);
}
