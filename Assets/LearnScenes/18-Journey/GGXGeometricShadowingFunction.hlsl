    float GGXGeometricShadowingFunction(float3 light, float3 view, float3 normal, float roughness)
    {
        float NdotL = max(0, dot(normal, light));
        float NdotV = max(0, dot(normal, view));
        float roughnessSqr = roughness * roughness;
        float NdotLSqr = NdotL * NdotL;
        float NdotVSqr = NdotV * NdotV;
        float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotLSqr));
        float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotVSqr));
        float Gs = (SmithL * SmithV);
        return Gs;
    }