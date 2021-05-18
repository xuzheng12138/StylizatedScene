//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// 石头的 风格化Shader URP
//////////////////////////////////////////////////////////////////////////////////////////////////
Shader "Universal Render Pipeline/Stylizated/StoneLit"
{
    Properties
    {
        [MainTexture] _BaseMap("_BaseMap", 2D) = "white" {}
        _BaseNormalMap("_BaseNormal", 2D) = "white" {}
        [HDR]_BaseColor("_BaseColor", Color) = (1, 1, 1, 1)

        _MappingMap("_MappingMap", 2D) = "white" {}
        _MappingNormalMap("_MappingNormalMap", 2D) = "white" {}
        [HDR]_MappingColor("_MappingColor", Color) = (1, 1, 1, 1)
        _MappingPower("_MappingPower", Range(1, 10)) = 1
        _MappingMinClip("_MappingMinClip", Range(0, 1)) = 0.3
        _MappingNormalClip("_MappingNormalClip", Range(0, 1)) = 0.5
        /// Mapping Vector3
        _MappingVectorX("_MappingVectorX", float) = 0
        _MappingVectorY("_MappingVectorY", float) = 1
        _MappingVectorZ("_MappingVectorZ", float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" 
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
            /// 软阴影
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma vertex VertexShaderWork
            #pragma fragment FragmentShaderWork

            #include "Library/StylizatedStoneLit.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "StylizatedScene.Editor.StoneGUI"
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}