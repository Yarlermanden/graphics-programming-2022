#version 330 core
layout (location = 0) in vec3 vertex;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 textCoord; // here for completness, but we are not using it just yet

uniform mat4 model; // represents model coordinates in the world coord space
uniform mat4 viewProjection;  // represents the view and projection matrices combined
uniform vec3 camPosition; // so we can compute the view vector

// send shaded color to the fragment shader
out vec4 shadedColor;

// TODO exercise 5 setup the uniform variables needed for lighting
//5.1
//light uniform variable
uniform vec3 ambientLightColor; //ambient light color modulated by intensity (I_a) - not ambientLightColor but ambientLightIntensity
//material properties
uniform float ambientReflectance; //object reflection of ambient light (k_a)
uniform vec3 reflectionColor; //color of object (color)

//5.2
//light uniform variable
uniform vec3 light1Position; //position of the first light (L)
uniform vec3 light1Color; //light color modulated by intensity (I_light)
//material properties
uniform float diffuseReflectance; //how much diffues light the object reflects (k_d)

//5.3
//light uniform variable
//material properties
uniform float specularReflectance; //(k_s)
uniform float specularExponent; //how concentrated the spotlight is - higher value is smoother surface (exp)


void main() {
   // vertex in world space (for light computation)
   vec4 P = model * vec4(vertex, 1.0);
   // normal in world space (for light computation)
   vec3 N = normalize(model * vec4(normal, 0.0)).xyz;

   // final vertex transform (for opengl rendering, not for lighting)
   gl_Position = viewProjection * P;

   // TODO exercises 5.1, 5.2 and 5.3 - Gouraud shading (i.e. Phong reflection model computed in the vertex shader)

   // TODO 5.1 ambient
   vec3 RambientLight = ambientLightColor * ambientReflectance * reflectionColor; //R_ambient = I_a * k_a * color

   // TODO 5.2 diffuse
   vec3 L = normalize(light1Position-P.xyz);//we need to normalize the lightposition
   vec3 Rdiffuse = light1Color * diffuseReflectance * (dot(N,L)); //I_light * K_d * (N•L) * color - color and I_light is already multipled in the setup

   // TODO 5.3 specular
   //R_specular = I_light * k_s * cosß^exp = I_light * k_s * (N*H)^exp
   //need to calculate H as halfway point between view angle (V) and light angle (L)
   //vec3 V = normalize(abs(camPosition - P.xyz));
   vec3 H = normalize(L + camPosition);
   vec3 Rspecular = light1Color * specularReflectance * pow(dot(N, H), specularExponent);

   // TODO exercise 5.5 - attenuation - light 1
   float distance = length(light1Position-P.xyz);
   float attenuation = 1/pow(distance,2);


   // TODO set the output color to the shaded color that you have computed
   //shadedColor = vec4(.8, .8, .8, 1.0);
   shadedColor = vec4(RambientLight + attenuation * (Rdiffuse + Rspecular), 1.0);

}