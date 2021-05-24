//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/21
/// Stylizated Stone
//////////////////////////////////////////////////////////////////////////////////////////////////
Shader "Universal Render Pipeline/Stylizated/SharedStone"
{
    Properties
    {
        /// albedo
        [Header(Albedo)]
        _MainColor("_MainColor", Color) = (1, 1, 1, 1)
        _MainAlbedoMap("_MainAlbedoMap", 2D) = "white" {}
        _MainNormalMap("_MainNormalMap", 2D) = "bump" {}
        _MainMetallicGlossMap("Metallic (R) Occlusion (G) Smoothness (A)", 2D) = "black" {}
        _MainNormalScale("_MainNormalScale", Range(0, 1)) = 1

        [Space(10)][Header(HightSettings)]
        _MetallicScale("_MetallicScale", Range(0, 1)) = 0
        _SmoothnessScale("_SmoothnessScale", Range(0, 1)) = 1
        _OcclusionScale("_OcclusionScale", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
		Cull Back
		AlphaToMask Off
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma vertex VertexShaderWork
            #pragma fragment FragmentShaderWork

            #include "SharedStone.hlsl"
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}