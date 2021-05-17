Shader "Universal Render Pipeline/Grass Patch"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _ShadowColor("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowIntensity("Shadow Intensity", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite OFF

            HLSLPROGRAM

            #pragma multi_compile_fog

            #pragma vertex VertexShaderWork
            #pragma fragment FragmentShaderWork

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT //柔化阴影，得到软阴影

            #include "GrassPatch.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}