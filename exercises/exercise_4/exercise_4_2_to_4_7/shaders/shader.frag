#version 330 core
// TODO 4.6: should receive the age of the particle as an input variable
in float age;

out vec4 fragColor;


void main()
{
    // TODO 4.4 set the alpha value to 0.2 (alpha is the 4th value of the output color)
    //fragColor = vec4(1.0, 1.0, 1.0, 0.2);

    // TODO 4.5 and 4.6: improve the particles appearance
    //gl_PointCoord
    float alpha = 1 - smoothstep(0.0, 1.0, ((distance(vec2(0.5,0.5), gl_PointCoord))/distance(vec2(0.5,0.5), vec2(0.5, 0.0)))); //from 0 to 1, depending on the distance from the center to the point

    fragColor = vec4(1.0, 1.0-(age/10), mix(0.05, 0.01, (age/10.0)), pow(alpha, 2.0));

    if(age > 10)
    {
        fragColor = vec4(0,0,0,0);
    }

    // remember to replace the default output (vec4(1.0,1.0,1.0,1.0)) with the color and alpha values that you have computed
    //fragColor = vec4(1.0, 1.0, 1.0, 1.0);

}