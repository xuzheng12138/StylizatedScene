//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// 用到的一些工具函数
//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma once

half3 SampleNormalUtil(sampler2D normalMap, float normalScale, float2 uv, float3 normalWS, float3 tangentWS, float3 bitangentWS)
{
    half3 normalTS = UnpackNormalScale(tex2D(normalMap, uv), normalScale);
    half3 outNormalWS = TransformTangentToWorld(normalTS, half3x3(tangentWS, bitangentWS, normalWS));
    return outNormalWS;
}