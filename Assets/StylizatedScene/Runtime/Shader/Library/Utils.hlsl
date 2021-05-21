//////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// PRB Function && Utils Function
//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma once

//////////////////////////////////////////////////////////////////////////////////////////////////
/// Utils
//////////////////////////////////////////////////////////////////////////////////////////////////

/// 采样法线并从切线空间转换到世界空间
half3 SampleNormalUtil(sampler2D normalMap, float normalScale, float2 uv, float3 normalWS, float3 tangentWS, float3 bitangentWS)
{
    half3 normalTS = UnpackNormalScale(tex2D(normalMap, uv), normalScale);
    half3 outNormalWS = TransformTangentToWorld(normalTS, half3x3(tangentWS, bitangentWS, normalWS));
    return outNormalWS;
}

/// 球谐函数
half3 SH_IndirectionDiff(float3 normalWS)
{
    float4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;
    half3 color = SampleSH9(SHCoefficients, normalWS);
    return max(0, color);
}

float pow2(float i)
{
    return i * i;
}

float pow4(float i)
{
    return i * i * i * i;
}

float pow5(float i)
{
    return i * i * i * i * i;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
/// PBR
//////////////////////////////////////////////////////////////////////////////////////////////////

///------------------------------------------------------------------
/// 直射光照部分
///------------------------------------------------------------------

/// [D项]
/// 法线微表面分布函数GGX (Normal Distribution Function)
/// 描述微观法线N和半角向量H的趋同性比重
/// D = pow2(a) / pi * pow2(pow2((NdotH) * (pow2(a) - 1) + 1))
/// params : roughness[粗糙度]
float NormalDistributionFunction(float NdotH, float roughness)
{
    float _pow2a = pow2(roughness);
    float _pow2NdotH = pow2(NdotH);
    float _nom = _pow2a;
    float _denom = _pow2NdotH * (_pow2a - 1) + 1;
    _denom = pow2(_denom) * PI;
    return _nom / _denom;
}

/// [G项]
/// 几何函数G (Geometry Function)
/// 描述入射射线(即光照方向)和出射方向(既视线方向) 被自己的围观几何形状遮挡的比重
/// G = (NdotL / lerp(NdotL, 1, k)) * (NdotV / lerp(NdotV, 1, k))
/// params : roughness[粗糙度]
float GeometryFunction(float NdotL, float NdotV, float roughness)
{
    /// 注意k系数, 在直接光的是pow(1+roughness, 2) / 8, 间接光是pow(roughness, 2) / 2
    float _k = pow2(1 + roughness) * 0.125;
    float _GnL = NdotL / lerp(NdotL, 1, _k);
    float _GnV = NdotV / lerp(NdotV, 1, _k);
    return _GnL * _GnV;
}

/// [F项]
/// 菲涅尔函数F (Fresnel Equation Function)
/// F = lerp(pow5(1 - NdotV), 1, F0)
/// 由于我们需要的法线方向并不是模型本身的宏观法线N, 而是经过D项筛选通过的围观法线H, 固然吧N替换为H;
/// F[schlick](h, v, F0) = F0 + (1 - F0) * pow5(1 - HdotV)
/// 后来unity对它进行了优化(https://link.zhihu.com/?target=http%3A//filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/)
/// 视线方向V换成了L
/// F(l, h) = F0 + (1 - F0) * pow5(1 - LdotH)
float3 FresnelEquationFunction(float HdotL, float3 F0)
{
    /// 这里五次方换算成对数计算了
    float _Fresnel = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
    return lerp(_Fresnel, 1, F0);
}

///------------------------------------------------------------------
/// 间射光照部分
///------------------------------------------------------------------

/// [F项]
/// 间接光 菲涅尔函数F (Fresnel Equation Function)
float3 Inder_FresnelEquationFunction(float HdotV, float3 F0, float roughness)
{
    float _Fresnel = exp2((-5.55473 * HdotV - 6.98316) * HdotV);
    return F0 + _Fresnel * saturate(1 - roughness - F0);
}

/// 间接光高光&&反射探针 
float3 IndirSpeCube(float3 N, float3 V, float roughness, float AO)
{
    float3 _reflectDirWS = reflect(-V, N);
    /// Unity 内部不是线性, 调整下拟合去先求近似
    roughness = roughness * (1.7 - 0.7 * roughness);
    /// 把粗糙度remap到 [0-6] 七个阶级 然后进行lod采样
    float _MidLevel = roughness * 6;
    /// 根据不同等级采样
    float4 _speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, _reflectDirWS, _MidLevel);
#if !defined(UNITY_USE_NATIVE_HDR)
    /// 用DecodeHDREnvironment将颜色从HDR便面下解码, 卡伊 看到采样出的rgbm是一个4通道的值, 最后一个m存的是一个参数
    /// 解码时将前三个通道表示颜色乘上xM^y, x和y都是由环境贴图定义的系数, 储存在unity_SpceCube0_HDR这个结构中
    return DecodeHDREnvironment(_speColor, unity_SpecCube0_HDR) * AO;
#else
    return _speColor.xyz * AO;
#endif
}

///间接高光, 曲线拟合 放弃LUT采样而使用曲线拟合
float3 IndirSpeFactor(float roughness, float smoothness, float3 BRDFspe, float3 F0, float NdotV)
{
#ifdef UNITY_COLORSPACE_GAMMA
    float _SurReduction = 1 - 0.28 * roughness, roughness;
#else
    float _SurReduction = 1 / (pow2(roughness) + 1);
#endif
#if defined(SHADER_API_GLES) // Lighting.hals 261h
    float _Reflectivity = BRDFspe.x;
#else
    float _Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
#endif
    half _GrazingTSection = saturate(_Reflectivity + smoothness);
    float _Fresnel = pow4(1 - NdotV); // Lighting.hlsl 501h
    // float _Fresnel = exp2((-5.55473 * NdotV - 6.98316) * NdotV); 五次方
    return lerp(F0, _GrazingTSection, _Fresnel) * _SurReduction;
}