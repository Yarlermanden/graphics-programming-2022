#version 330 core
layout (location = 0) in vec2 pos;   // the position variable has attribute position 0
// TODO 4.2 add velocity and timeOfBirth as vertex attributes
layout (location = 1) in vec2 vel;
layout (location = 2) in float tob;

// TODO 4.3 create and use a float uniform for currentTime
uniform float currentTime;

// TODO 4.6 create out variable to send the age of the particle to the fragment shader
out float age;

void main()
{
    // TODO 4.3 use the currentTime to control the particle in different stages of its lifetime
    if(tob == 0.0)
    {
        gl_Position = vec4(1.1, 1.1, 0.0, 1.0);
    }
    else
    {
        age = currentTime-tob;
        if(age > 10.0)
        {
            gl_Position = vec4(-1.0, -1.0, 0.0, -1.0);
        }
        else
        {
            // TODO 4.6 send the age of the particle to the fragment shader using the out variable you have created
            gl_Position = vec4(pos.x + age*vel.x, pos.y + age*vel.y, 0.0, 1.0);

            float size = 2*age;
            gl_PointSize = size;
        }
    }


    // this is the output position and and point size (this time we are rendering points, instad of triangles!)
    //gl_Position = vec4(pos, 0.0, 1.0);
    //gl_PointSize = 10.0;
}