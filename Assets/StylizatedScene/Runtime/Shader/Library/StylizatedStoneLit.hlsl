//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// 石头的 风格化Shader hlsl
//////////////////////////////////////////////////////////////////////////////////////////////////

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "Library/Utils.hlsl"

struct A2V
{
    float3 positionOS   : POSITION;
    float2 uv           : TEXCOORD0;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
};

struct V2F
{
    float4 positionCS               : SV_POSITION;
    float2 uv                       : TEXCOORD0;
    float4 positionWS               : TEXCOORD1;
    float3 normalWS                 : TEXCOORD2;
    float3 normalOS                 : TEXCOORD3;
    float4 tangentOS                : TEXCOORD4;
};

sampler2D _BaseMap;
sampler2D _BaseNormalMap;
sampler2D _MappingMap;
sampler2D _MappingNormalMap;

CBUFFER_START(UnityPerMaterial)
    half3 _BaseColor;
    half3 _MappingColor;

    float _MappingVectorX;
    float _MappingVectorY;
    float _MappingVectorZ;
    float _MappingMinClip;
    float _MappingNormalClip;
    float _MappingPower;
CBUFFER_END

///////////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
///////////////////////////////////////////////////////////////////////////////////////
V2F VertexShaderWork(A2V input)
{
    V2F output;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.uv = input.uv;
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.normalOS = input.normalOS;
    output.tangentOS = input.tangentOS;
    /*
    output.positionWS.xyz = TransformObjectToWorld(output.positionCS);
    output.positionWS.w = ComputeFogFactor(output.positionCS.z);
    output.color = input.color;
    */
    return output;
}

///////////////////////////////////////////////////////////////////////////////////////
// Fragment Shader
///////////////////////////////////////////////////////////////////////////////////////
half4 FragmentShaderWork(V2F input) : SV_TARGET
{
    float3 mappingDirWS = normalize(float3(_MappingVectorX, _MappingVectorY, _MappingVectorZ));
    float3 normalWS = SamplingNormalMapInFrag(_BaseNormalMap, input.uv, 0.6, input.tangentOS, input.normalOS);
    float NDotM = saturate(dot(normalWS, mappingDirWS));
    NDotM = pow(NDotM, _MappingPower);
    NDotM = NDotM < _MappingMinClip ? 0 : NDotM;
    half3 basicColor = tex2D(_BaseMap, input.uv) * _BaseColor;
    half3 mappingColor = tex2D(_MappingMap, input.uv) * _MappingColor;

    half3 color = lerp(basicColor, mappingColor, NDotM);

    float3 lambertNormalWS = NDotM < _MappingNormalClip ? normalWS : SamplingNormalMapInFrag(_MappingNormalMap, input.uv, 1, input.tangentOS, input.normalOS);

    Light mainLight = GetMainLight();
    float3 lightDir = normalize(mainLight.direction);
    float NDotL = saturate(dot(lambertNormalWS, lightDir));
    float lambert = NDotL * 0.5 + 0.5;

    color = color * lambert * mainLight.color;
    /*
    Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS.xyz));
    half4 shadowColor = mainLight.shadowAttenuation + half4(_ShadowColor * _ShadowIntensity, 1);
    color = color * saturate(shadowColor);
    float fogFactor = input.positionWS.w;
    color = half4(MixFog(color.rgb, fogFactor), color.a);
    */
    return half4(color, 1);
}