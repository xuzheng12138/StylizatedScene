//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// PBR Lit
//////////////////////////////////////////////////////////////////////////////////////////////////
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "Library/Utils.hlsl"

struct A2V
{
    float3 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 uv           : TEXCOORD0;
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

sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _MetallicMap;
sampler2D _OcclusionMap;
CBUFFER_START(UnityPerMaterial)
    half3 _BaseColor;
    float _Roughness;
    float _Metallic;
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
    output.uv = input.uv;
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
    half3 Albedo = tex2D(_MainTex, input.uv) * _BaseColor;
    half Metallic = tex2D(_MetallicMap, input.uv).r * _Metallic;
    half AO = tex2D(_OcclusionMap, input.uv).r;
    half Roughness = _Roughness;
    float FogFactor = input.positionWS.w;

    Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS.xyz));

    float3 V = normalize(_WorldSpaceCameraPos - input.positionWS.xyz);
    float3 N = SampleNormalUtil(_NormalMap, 1, input.uv, input.normalWS, input.tangentWS, input.bitangentWS);
    float3 L = normalize(mainLight.direction);
    float3 H = normalize(L + V);
    float3 F0 = lerp(0.04, Albedo, Metallic);

    float NdotH = max(saturate(dot(N, H)), 0.00001);
    float NdotL = max(saturate(dot(N, L)), 0.00001);
    float NdotV = max(saturate(dot(N, V)), 0.00001);
    float HdotL = max(saturate(dot(H, L)), 0.00001);
    float HdotV = max(saturate(dot(H, V)), 0.00001);
    
    float _D = NormalDistributionFunction(NdotH, Roughness);
    float _G = GeometryFunction(NdotL, NdotV, Roughness);
    float3 _F = FresnelEquationFunction(HdotL, F0);

    /// spe
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
    float3 _SHColor = SH_IndirectionDiff(N) * AO;
    float3 _IndirKS = Inder_FresnelEquationFunction(HdotV, F0, Roughness);
    float3 _IndirKD = (1 - _IndirKS) * (1 - Metallic);
    float3 _IndirDiffColor = _SHColor * _IndirKD * Albedo;

    
    float3 _DirectColor = _DirectSpeColor + _DirectDiffColor * mainLight.shadowAttenuation;
    float3 _IndirColor = _IndirSpeColor + _IndirDiffColor;

    float3 _AddColor = float3(0, 0, 0);
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