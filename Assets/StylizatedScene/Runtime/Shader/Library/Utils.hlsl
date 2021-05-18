//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// 用到的一些工具函数
//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma once

float3 SamplingNormal(float4 nortex, float normalScale, float4 tangentOS, float3 normalOS)
{
    float3 _normalTS = UnpackNormalScale(nortex, normalScale);
    float3x3 M_TS2OS =
    {
        tangentOS.xyz * tangentOS.w,
        cross(tangentOS * tangentOS.w, normalOS),
        normalOS
    };
    M_TS2OS = transpose(M_TS2OS);
    float3 _normalOS = mul(M_TS2OS, _normalTS);
    return normalize(TransformObjectToWorldDir(_normalOS));
}

float3 SamplingNormalMapInFrag(sampler2D normalMap, float2 uv, float normalScale, float4 tangentOS, float3 normalOS)
{
    float4 _nortex = tex2D(normalMap, uv);
    return SamplingNormal(_nortex, normalScale, tangentOS, normalOS);
}

float3 SamplingNormalMapInInVer(sampler2D normalMap, float2 uv, float normalScale, float4 tangentOS, float3 normalOS)
{
    float4 _nortex = tex2Dlod(normalMap, float4(uv, 0, 0));
    return SamplingNormal(_nortex, normalScale, tangentOS, normalOS);
}