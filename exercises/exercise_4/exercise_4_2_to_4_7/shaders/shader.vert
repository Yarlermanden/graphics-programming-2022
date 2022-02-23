#version 330 core
layout (location = 0) in vec2 pos;   // the position variable has attribute position 0
// TODO 4.2 add velocity and timeOfBirth as vertex attributes
layout (location = 1) in vec2 vel;
layout (location = 2) in float tob;

// TODO 4.3 create and use a float uniform for currentTime
uniform float currentTime;

// TODO 4.6 create out variable to send the age of the particle to the fragment shader

void main()
{
    // TODO 4.3 use the currentTime to control the particle in different stages of its lifetime
    if(currentTime <= 1)
    {
        gl_Position = vec4(10000.0, 5.0, -5.0, -5.0);
    }
    else
    {
        float age = currentTime-tob;
        if(age > 5)
        {
            gl_Position = vec4(5.0, 5.0, 5.0, 5.0);
        }
        else
        {
            gl_Position = vec4(pos.x + age*vel.x, pos.y + age*vel.y, 0.0, 1.0);
            //gl_Position = vec4(pos, 0.0, 1.0);
        }
    }

    // TODO 4.6 send the age of the particle to the fragment shader using the out variable you have created

    // this is the output position and and point size (this time we are rendering points, instad of triangles!)
    //gl_Position = vec4(pos, 0.0, 1.0);
    gl_PointSize = 10.0;
}