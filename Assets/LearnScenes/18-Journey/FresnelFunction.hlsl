     // float SchlickFresnel(float i)
// {
//     float x = clamp(1.0 - i, 0.0, 1.0);
//     float x2 = x * x;
//     return x2 * x2 * x;
// }

float3 FresnelFunction(float3 SpecularColor, float3 light, float3 viewDirection)
{
    float3 halfDirection = normalize(light + viewDirection);
    // float power = SchlickFresnel(max(0, dot(light, halfDirection)));
    float power = clamp(1.0 - max(0, dot(light, halfDirection)), 0.0, 1.0);
    float x2 = power * power;
    float v = x2 * x2 * power;
    return float4(SpecularColor + (1 - SpecularColor) * v, 1);
}
