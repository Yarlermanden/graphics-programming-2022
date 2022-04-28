//
// Created by henrique on 04/11/2021.
//

#ifndef ITU_GRAPHICS_PROGRAMMING_RT_TYPES_H
#define ITU_GRAPHICS_PROGRAMMING_RT_TYPES_H

#include "glm/glm.hpp"

namespace rt{

    namespace Colors {
        // colors are 32 bits unsigned ints, so it is easy to upload to the GPU as a texture
        //typedef uint32_t color;
        typedef glm::vec4 color;

        // hardcoded some colors for convenience
        const color white = glm::vec4(1, 1, 1, 1);
        const color grey = glm::vec4(.5, .5, .5, 1);;
        const color dark = glm::vec4(.15, .15, .15, 1);
        const color black = glm::vec4(0, 0, 0, 1);
        const color blue = glm::vec4(0, 0, 1, 1);
        const color green = glm::vec4(0, 1, 0, 1);
        const color red = glm::vec4(1, 0, 0, 1);

        inline std::uint32_t toRGBA32(color c) {
            // convert color to four 8 bits uint, packed in a 32 bits uint.
            // We do that because that is the proper format for the color buffer that renders to the screen
            color c_clamp = glm::clamp(c, .0f, 1.0f);
            return (uint32_t(255 *  c_clamp.r)) + (uint32_t(255 * c_clamp.g) << 8) +
                   (uint32_t(255 * c_clamp.b) << 16) + (uint32_t(255 * c_clamp.a) << 24);
        }
    }

    struct Ray{
        Ray(glm::vec3 orig, glm::vec3 dir): origin(orig), direction(dir){};
        glm::vec3 origin;
        glm::vec3 direction;
    };

    struct Hit{
        int hit_ID = -1;
        glm::vec3 barycentric;
        float dist = FLT_MAX;
    };

    struct Material {
        public:
            float ambient = 0.1f;
            float diffuse = 0.5f;
            float specularExp = 20.f;
            float specularReflectance = 1.f;
            Material() {};
            Material(float a, float d, float exp, float ref) { ambient = a; diffuse = d; specularExp = exp; specularReflectance = ref; }
            Material avg(Material m2) { return Material((ambient+m2.ambient)/2, (diffuse+m2.diffuse)/2, (specularExp+m2.specularExp)/2, (specularReflectance+m2.specularReflectance)/2);}
    };

    struct vertex {
        glm::vec4 pos;
        glm::vec4 norm;
        Colors::color col;
        glm::vec2 uv;
        Material mat;

        friend vertex operator/(vertex v, float sc);
        friend vertex operator*(vertex v, float sc);
        friend vertex operator-(vertex v1, const vertex &v2);
        friend vertex operator+(vertex v1, const vertex &v2);
    };

}


#endif //ITU_GRAPHICS_PROGRAMMING_RT_TYPES_H
