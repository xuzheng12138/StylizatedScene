//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/21
/// Stylizated Stone
//////////////////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "Library/Utils.hlsl"

struct A2V
{
    float3 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float4 uv           : TEXCOORD0;
};

struct V2F
{
    float4 positionCS               : SV_POSITION;
    float2 main_uv                  : TEXCOORD0;
    float2 layer_uv                 : TEXCOORD1;
    float4 positionWS               : TEXCOORD2;
    float3 normalWS                 : TEXCOORD3;
    float3 tangentWS                : TEXCOORD4;
    float3 bitangentWS              : TEXCOORD5;
};

sampler2D _MainAlbedoMap;
sampler2D _MainNormalMap;
sampler2D _MainMetallicGlossMap;

sampler2D _LayerAlbedoMap;
sampler2D _LayerNormalMap;
sampler2D _LayerMetallicGlossMap;

CBUFFER_START(UnityPerMaterial)
    float4 _MainColor;
    float4 _MainAlbedoMap_ST;
    float _MainNormalScale;

    float4 _LayerColor;
    float4 _LayerAlbedoMap_ST;
    float _LayerNormalScale;

    float _LayerPower;
    float _LayerThreshold;

    float _MetallicScale;
    float _SmoothnessScale;
    float _OcclusionScale;
CBUFFER_END

///////////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
///////////////////////////////////////////////////////////////////////////////////////
V2F VertexShaderWork(A2V input)
{
    V2F output;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;
    output.main_uv = TRANSFORM_TEX(input.uv, _MainAlbedoMap);
    output.layer_uv = TRANSFORM_TEX(input.uv, _LayerAlbedoMap);
    output.positionWS.xyz = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.positionWS.w = ComputeFogFactor(output.positionCS.z);
    return output;
}

///////////////////////////////////////////////////////////////////////////////////////
// Fragment Shader
///////////////////////////////////////////////////////////////////////////////////////
half4 FragmentShaderWork(V2F input) : SV_TARGET
{
    Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS.xyz));

    float3 N = input.normalWS;
    float3 T = input.tangentWS;
    float3 BT = input.bitangentWS;
    float3 V = normalize(_WorldSpaceCameraPos - input.positionWS.xyz);
    float3 L = normalize(mainLight.direction);
    float3 H = normalize(L + V);
    float3 F0 = 0;


    /// main
    half3 MainAlbedo = tex2D(_MainAlbedoMap, input.main_uv) * _MainColor;
    half3 MainNormalWS = SampleNormalUtil(_MainNormalMap, _MainNormalScale, input.main_uv, N, T, BT);
    half4 MainMetallicGloss = tex2D(_MainMetallicGlossMap, input.main_uv);


    /// layer
    half3 LayerAlbedo = tex2D(_LayerAlbedoMap, input.layer_uv) * _LayerColor;
    half3 LayerNormalWS = SampleNormalUtil(_LayerNormalMap, _LayerNormalScale, input.layer_uv, N, T, BT);
    half4 LayerMetallicGloss = tex2D(_LayerMetallicGlossMap, input.layer_uv);


    float4 BlendWeight = pow(saturate((N.y).xxxx + _LayerPower), (0.001 + _LayerThreshold * 0.999).xxxx);
    float FogFactor = input.positionWS.w;
    half3 Albedo = lerp(MainAlbedo, LayerAlbedo, BlendWeight);
    N = lerp(MainNormalWS, LayerNormalWS, BlendWeight);
    half Metallic = lerp(MainMetallicGloss.r, LayerMetallicGloss.r, BlendWeight) + _MetallicScale;
    half Smoothness = lerp(MainMetallicGloss.a, LayerMetallicGloss.a, BlendWeight) * _SmoothnessScale;
    half Occlusion = pow(max(lerp(MainMetallicGloss.g, LayerMetallicGloss.g, BlendWeight), 0.0001), _OcclusionScale);
    half Roughness = pow(1 - Smoothness, 2);
    

    F0 = lerp(0.04, Albedo, Metallic);
    float NdotH = max(saturate(dot(N, H)), 0.00001);
    float NdotL = max(saturate(dot(N, L)), 0.00001);
    float NdotV = max(saturate(dot(N, V)), 0.00001);
    float HdotL = max(saturate(dot(H, L)), 0.00001);
    float HdotV = max(saturate(dot(H, V)), 0.00001);


    float _D = NormalDistributionFunction(NdotH, Roughness);
    float _G = GeometryFunction(NdotL, NdotV, Roughness);
    float3 _F = FresnelEquationFunction(HdotL, F0);


    /// specular
    float3 _nom = _D * _G * _F;
    float _denom = 4 * NdotL * NdotV;
    float3 _BRDFSpeSection = _nom / _denom;
    float3 _DirectSpeColor = _BRDFSpeSection * mainLight.color * NdotL * PI;
    

    /// diffice
    float3 _KS = _F;
    float3 _KD = (1 - _KS) * (1 - Metallic);
    float3 _DirectDiffColor = _KD * Albedo * mainLight.color * NdotL;
    

    /// indir spe
    float3 _IndirSpeCubeColor = IndirSpeCube(N, V, Roughness, 1); /// 环境探针(SkyBox)
    float3 _IndirSpeCubeFactor = IndirSpeFactor(Roughness, Roughness * 0.5, _BRDFSpeSection, F0, NdotV);
    float3 _IndirSpeColor = _IndirSpeCubeColor * _IndirSpeCubeFactor;
    

    /// indir diffice
    float3 _SHColor = SH_IndirectionDiff(N) * Occlusion;
    float3 _IndirKS = Inder_FresnelEquationFunction(HdotV, F0, Roughness);
    float3 _IndirKD = (1 - _IndirKS) * (1 - Metallic);
    float3 _IndirDiffColor = _SHColor * _IndirKD * Albedo;


    float3 _AddColor = float3(0, 0, 0);
    float3 _DirectColor = _DirectSpeColor + _DirectDiffColor * mainLight.shadowAttenuation;
    float3 _IndirColor = _IndirSpeColor + _IndirDiffColor;


    int AddlightsCount = GetAdditionalLightsCount();
    for(int i = 0; i < AddlightsCount; i++)
    {
        Light addlight = GetAdditionalLight(i, input.positionWS.xyz);
        float3 addlightDirWS = normalize(addlight.direction);
        float NDotAL = saturate(dot(N, addlightDirWS)) * 0.5 + 0.5;
        _AddColor += NDotAL * addlight.color * Albedo * addlight.distanceAttenuation * addlight.shadowAttenuation;
    }

    half3 outputColor = _DirectColor + _IndirColor + _AddColor;
    outputColor = MixFog(outputColor, FogFactor);
    return half4(outputColor, 1);
}