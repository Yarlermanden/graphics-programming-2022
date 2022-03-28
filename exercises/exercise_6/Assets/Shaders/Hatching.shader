Shader "CG2022/Hatching"
{
    Properties
    {
        _Albedo("Albedo", Color) = (1,1,1,1)
        _AlbedoTexture("Albedo Texture", 2D) = "white" {}
        _Reflectance("Reflectance (Ambient, Diffuse, Specular)", Vector) = (1, 1, 1, 0)
        _SpecularExponent("Specular Exponent", Float) = 100.0
        // TODO exercise 6 - Add the required properties here
        _Hatch0Texture("Hatching Texture 0", 2D) = "white" {}
        _Hatch1Texture("Hatching Texture 1", 2D) = "white" {}
        _Hatch2Texture("Hatching Texture 2", 2D) = "white" {}
        _Hatch3Texture("Hatching Texture 3", 2D) = "white" {}
        _Hatch4Texture("Hatching Texture 4", 2D) = "white" {}
        _Hatch5Texture("Hatching Texture 5", 2D) = "white" {}
        _HatchTexture("HatchingArr", 2DArray) = "White" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        GLSLINCLUDE
        #include "UnityCG.glslinc"
        #include "ITUCG.glslinc"

        uniform vec4 _Albedo;
        uniform sampler2D _AlbedoTexture;
        uniform vec4 _AlbedoTexture_ST;
        uniform vec4 _Reflectance;
        uniform float _SpecularExponent;

        // TODO exercise 6 - Add the required uniforms here
        uniform sampler2D _Hatch0Texture;
        uniform sampler2D _Hatch1Texture;
        uniform sampler2D _Hatch2Texture;
        uniform sampler2D _Hatch3Texture;
        uniform sampler2D _Hatch4Texture;
        uniform sampler2D _Hatch5Texture;

        uniform sampler2DArray _HatchTexture;
        uniform vec4 _HatchTexture_ST;
        
        // TODO exercise 6 - Compute the hatching intensity here
        float ComputeHatching(vec3 lighting, vec2 texCoords)
        {
            const float levels = 7.0f;

            // TODO exercise 6.3 - Compute the lighting intensity from the lighting color luminance
            float intensity = GetColorLuminance(lighting);

            // TODO exercise 6.3 - Clamp the intensity value between 0 and 1
            intensity = saturate(intensity);

            // TODO exercise 6.3 - Multiply the intensity by the number of levels. This time the number of levels is fixed, 7, given by the number of textures + 1
            intensity = intensity * levels;

            // TODO exercise 6.3 - Compute the blending factor, as the fractional part of the intensity
            float blend = fract(intensity);

            // TODO exercise 6.3 - Depending on the intensity, choose up to 2 textures to sample and mix them based on the blending factor. That would be the hatching intensity
            float hatch = 1.0f;
            if(intensity <= 1.0f) {
                hatch = mix(vec4(0.0f), texture(_Hatch5Texture, texCoords), blend).r;
            } else if(intensity <= 2.0f){
                hatch = mix(texture(_Hatch5Texture, texCoords), texture(_Hatch4Texture, texCoords), blend).r;
            } else if(intensity <= 3.0f){
                hatch = mix(texture(_Hatch4Texture, texCoords), texture(_Hatch3Texture, texCoords), blend).r;
            } else if(intensity <= 4.0f){
                hatch = mix(texture(_Hatch3Texture, texCoords), texture(_Hatch2Texture, texCoords), blend).r;
            } else if(intensity <= 5.0f){
                hatch = mix(texture(_Hatch2Texture, texCoords), texture(_Hatch1Texture, texCoords), blend).r;
            } else if(intensity <= 6.0f){
                hatch = mix(texture(_Hatch1Texture, texCoords), texture(_Hatch0Texture, texCoords), blend).r;
            } else {
                hatch = mix(texture(_Hatch0Texture, texCoords), vec4(1.0f), blend).r;
            }
            float hatchA = texture(_HatchTexture, vec3(texCoords, floor(intensity))).r;
            float hatchB = texture(_HatchTexture, vec3(texCoords, ceil(intensity))).r;
            hatch = mix(hatchA, hatchB, blend);

            // TODO exercise 6.4 - Replace the previous step with 2 samples from the texture array. Mix them based on the blending factor to get the hatching intensity

            return hatch;
        }
        ENDGLSL

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            GLSLPROGRAM

            struct vertexToFragment
            {
                vec3 worldPos;
                vec3 normal;
                vec4 texCoords;
            };

            #ifdef VERTEX
            out vertexToFragment v2f;

            void main()
            {
                v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
                v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;
                v2f.texCoords.xy = TransformTexCoords(gl_MultiTexCoord0.xy, _AlbedoTexture_ST);

                // TODO exercise 6.3 - Transform hatching texture coordinates and pass to the fragment
                v2f.texCoords.zw = TransformTexCoords(gl_MultiTexCoord0.xy, _HatchTexture_ST);

                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            in vertexToFragment v2f;

            void main()
            {
                vec3 lightDir = GetWorldSpaceLightDir(v2f.worldPos);
                vec3 viewDir = GetWorldSpaceViewDir(v2f.worldPos);

                vec3 normal = normalize(v2f.normal);

                vec3 albedo = texture(_AlbedoTexture, v2f.texCoords.xy).rgb;
                albedo *= _Albedo.rgb;

                // Like in the cel-shading exercise, we replace the albedo here with 1.0f
                vec3 lighting = BlinnPhongLighting(lightDir, viewDir, normal, vec3(1.0f), vec3(1.0f), _Reflectance.x, _Reflectance.y, _Reflectance.z, _SpecularExponent);

                float hatch = ComputeHatching(lighting, v2f.texCoords.zw);

                // Like in the cel-shading exercise, we multiply by the albedo and the light color at the end
                gl_FragColor = vec4(hatch * albedo * _LightColor0.rgb, 1.0f);
            }
            #endif // FRAGMENT

            ENDGLSL
        }
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardAdd" }

            ZWrite Off
            Blend One One

            GLSLPROGRAM

            struct vertexToFragment
            {
                vec3 worldPos;
                vec3 normal;
                vec4 texCoords;
            };

            #ifdef VERTEX
            out vertexToFragment v2f;

            void main()
            {
                v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
                v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;
                v2f.texCoords.xy = TransformTexCoords(gl_MultiTexCoord0.xy, _AlbedoTexture_ST);

                // TODO exercise 6.3 - Transform hatching texture coordinates and pass to the fragment
                v2f.texCoords.zw = TransformTexCoords(gl_MultiTexCoord0.xy, _HatchTexture_ST);

                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            in vertexToFragment v2f;

            void main()
            {
                vec3 lightDir = GetWorldSpaceLightDir(v2f.worldPos);
                vec3 viewDir = GetWorldSpaceViewDir(v2f.worldPos);

                vec3 normal = normalize(v2f.normal);

                vec3 albedo = texture(_AlbedoTexture, v2f.texCoords.xy).rgb;
                albedo *= _Albedo.rgb;

                // Like in the cel-shading exercise, we replace the albedo here with 1.0f. Notice that ambient reflectance is still 0.0f
                vec3 lighting = BlinnPhongLighting(lightDir, viewDir, normal, vec3(1.0f), vec3(1.0f), 0.0f, _Reflectance.y, _Reflectance.z, _SpecularExponent);

                float hatch = ComputeHatching(lighting, v2f.texCoords.zw);

                // Like in the cel-shading exercise, we multiply by the albedo and the light color at the end
                gl_FragColor = vec4(hatch * albedo * _LightColor0.rgb, 1.0f);
            }
            #endif // FRAGMENT

            ENDGLSL
        }
        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode" = "ShadowCaster" }

            GLSLPROGRAM

            #ifdef VERTEX
            void main()
            {
                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            void main()
            {
            }
            #endif // FRAGMENT

            ENDGLSL
        }
        // TODO exercise 6 - Add the outline pass here
        Pass
        { //Outline
            Name "OUTLINE"
            Tags { "LightMode" = "ForwardBase" }

            Cull Front

            GLSLPROGRAM

            #ifdef VERTEX

            void main()
            {
                //transform vertex position to world space
                vec3 worldPosition = (unity_ObjectToWorld * gl_Vertex).xyz;

                //transform normal to world space
                vec3 normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;

                //add normal, multipled by a small number (0.01f) to the world position
                worldPosition += normal*0.02f;

                //output to gl_position the position, transformed by the view projection matrix. (unity_MatrixVP)
                gl_Position = unity_MatrixVP * vec4(worldPosition, 1.0f);
            }
            #endif // VERTEX

            #ifdef FRAGMENT

            void main()
            {
                gl_FragColor = vec4(0.0f);
            }
            #endif // FRAGMENT

            ENDGLSL
        }
    }
}
