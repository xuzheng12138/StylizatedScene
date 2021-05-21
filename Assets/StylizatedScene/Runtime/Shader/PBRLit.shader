//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// PRB Lit
//////////////////////////////////////////////////////////////////////////////////////////////////
Shader "Universal Render Pipeline/Stylizated/PBRLit"
{
    Properties
    {
        /// albedo
        _MainTex("_MainTex", 2D) = "white" {}
        _BaseColor("_BaseColor", Color) = (1, 1, 1, 1)

        /// normal
        _NormalMap("_NormalMap", 2D) = "bump" {}

        /// roughness
        _Roughness("_Roughness", Range(0, 1)) = 0.5

        /// metallic
        _Metallic("_Metallic", Range(0, 1)) = 0.5
        _MetallicMap("_MetallicMap", 2D) = "white" {}

        /// occlusion
        _OcclusionMap("_OcclusionMap", 2D) = "while" {}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" 
        }
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma vertex VertexShaderWork
            #pragma fragment FragmentShaderWork

            #include "PRBLit.hlsl"
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}