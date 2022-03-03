#version 330 core

uniform vec3 camPosition; // so we can compute the view vector
out vec4 FragColor; // the output color of this fragment

// TODO exercise 5.4 setup the 'uniform' variables needed for lighting
// light uniforms
uniform vec3 ambientLightColor; //ambient light color modulated by intensity (I_a) - not ambientLightColor but ambientLightIntensity
uniform vec3 light1Position; //position of the first light (L)
uniform vec3 light1Color; //light color modulated by intensity (I_light)

uniform vec3 light2Position;
uniform vec3 light2Color;

// material uniforms
uniform float ambientReflectance; //object reflection of ambient light (k_a)
uniform vec3 reflectionColor; //color of object (color)
uniform float diffuseReflectance; //how much diffues light the object reflects (k_d)
uniform float specularReflectance; //(k_s)
uniform float specularExponent; //how concentrated the spotlight is - higher value is smoother surface (exp)

// TODO exercise 5.4 add the 'in' variables to receive the interpolated Position and Normal from the vertex shader
in vec4 P;
in vec3 N;

void main()
{

   // TODO exercise 5.4 - phong shading (i.e. Phong reflection model computed in the fragment shader)
   // ambient component
   vec3 RambientLight = ambientLightColor * ambientReflectance * reflectionColor; //R_ambient = I_a * k_a * color

   // diffuse component for light 1
   vec3 L = normalize(light1Position-P.xyz);//we need to normalize the lightposition
   vec3 Rdiffuse = light1Color * diffuseReflectance * (dot(N,L)); //I_light * K_d * (N•L) * color - color and I_light is already multipled in the setup

   // specular component for light 1
   //R_specular = I_light * k_s * cosß^exp = I_light * k_s * (N*H)^exp
   vec3 H = normalize(L + camPosition); //halfway point between V and L
   vec3 Rspecular = light1Color * specularReflectance * pow(dot(N, H), specularExponent);

   // TODO exercuse 5.5 - attenuation - light 1
   float distance = length(light1Position-P.xyz);
   float attenuation = 1/pow(distance,2);


   // TODO exercise 5.6 - multiple lights, compute diffuse, specular and attenuation of light 2
   vec3 L2 = normalize(light2Position-P.xyz);
   vec3 Rdiffuse2 = light2Color * diffuseReflectance * (dot(N,L2));

   vec3 H2 = normalize(L2 + camPosition);
   vec3 Rspecular2 = light2Color * specularReflectance * pow(dot(N,H2), specularExponent);

   float distance2 = length(light2Position-P.xyz);
   float attenuation2 = 1/pow(distance2, 2);

   // TODO compute the final shaded color (e.g. add contribution of the attenuated lights 1 and 2)
   vec3 R = RambientLight + attenuation * (Rdiffuse + Rspecular) + attenuation2 * (Rdiffuse2 + Rspecular2);

   // TODO set the output color to the shaded color that you have computed
   FragColor = vec4(R, 1.0f);
}
