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
    float2 uv2                      : TEXCOORD1;
    float4 positionWS               : TEXCOORD2;
    float3 normalWS                 : TEXCOORD3;
    float3 tangentWS                : TEXCOORD4;
    float3 bitangentWS              : TEXCOORD5;
};

sampler2D _BaseMap;
sampler2D _BaseNormalMap;
sampler2D _MappingMap;
sampler2D _MappingNormalMap;

CBUFFER_START(UnityPerMaterial)
    half3 _BaseColor;
    half3 _MappingColor;
    float4 _BaseMap_ST;
    float4 _MappingMap_ST;

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
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.uv2 = TRANSFORM_TEX(input.uv, _MappingMap);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;
    output.positionWS.xyz = TransformObjectToWorld(input.positionOS);
    output.positionWS.w = ComputeFogFactor(output.positionCS.z);
    return output;
}

///////////////////////////////////////////////////////////////////////////////////////
// Fragment Shader
///////////////////////////////////////////////////////////////////////////////////////
half4 FragmentShaderWork(V2F input) : SV_TARGET
{
    float3 baseNormalWS = SampleNormalUtil(_BaseNormalMap, 1, input.uv, input.normalWS, input.tangentWS, input.bitangentWS);
    float3 mappingNormalWS = SampleNormalUtil(_MappingNormalMap, 1, input.uv2, input.normalWS, input.tangentWS, input.bitangentWS);
    
    float3 mappingDirWS = normalize(float3(_MappingVectorX, _MappingVectorY, _MappingVectorZ));
    float NDotM = saturate(dot(baseNormalWS, mappingDirWS));
    NDotM = pow(NDotM, _MappingPower);
    NDotM = NDotM < _MappingMinClip ? 0 : NDotM;
    half3 basicColor = tex2D(_BaseMap, input.uv) * _BaseColor * 1.5;
    half3 mappingColor = tex2D(_MappingMap, input.uv2) * _MappingColor;
    half3 color = lerp(basicColor, mappingColor, NDotM);
    float3 normalWS = NDotM < _MappingNormalClip ? baseNormalWS : mappingNormalWS;

    Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS.xyz));
    float3 lightDir = normalize(mainLight.direction);
    float NDotL = saturate(dot(normalWS, lightDir));
    float diffuse = smoothstep(0, 1, NDotL);
    float shadow = smoothstep(0, 0.1, mainLight.shadowAttenuation);
    float shade = diffuse * shadow * 0.5 + 0.5;
    color = color * shade;

    float3 addColor = float3(0, 0, 0);
    int addlightsCount = GetAdditionalLightsCount();
    for(int i = 0; i < addlightsCount; i++)
    {
        Light addlight = GetAdditionalLight(i, input.positionWS.xyz);
        float3 addlightDirWS = normalize(addlight.direction);
        float NDotAL = saturate(dot(normalWS, addlightDirWS)) * 0.5 + 0.5;
        addColor += NDotAL * addlight.color * basicColor * addlight.distanceAttenuation * addlight.shadowAttenuation;
    }

    color += addColor;

    float fogFactor = input.positionWS.w;
    color = MixFog(color, fogFactor);

    return half4(color, 1);
}