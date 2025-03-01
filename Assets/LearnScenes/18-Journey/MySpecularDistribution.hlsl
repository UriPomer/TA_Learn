float MySpecularDistribution(float roughness, float3 lightDir, float3 view, float3 normal, float3 normalDetail, float _Glossiness)
{
    float3 halfDirection = normalize(view + lightDir);
    float baseShine = pow(max(0, dot(halfDirection, normal)), 100 / _Glossiness);
    float shine = pow(max(0, dot(halfDirection, normalDetail)), 10 / roughness);
    return baseShine * shine;
}
