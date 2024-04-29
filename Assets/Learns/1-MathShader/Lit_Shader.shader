// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Lit_Shader"
{
    Properties
    {
       _Smoothness ("Smoothness", Range(0,1)) = 0.5
    }
    SubShader
    {
        CGPROGRAM
        #pragma surface ConfigureSurface Standard fullforwardshadows
        #pragma target 3.0

        struct Input
        {
            float3 worldPos;
        };

        float _Smoothness;

        void ConfigureSurface(Input input, inout SurfaceOutputStandard surface)
        {
            surface.Albedo = saturate(input.worldPos * 0.5 + 0.5);
            surface.Smoothness = _Smoothness;
            
            // surface.Metallic = _Metallic;
            // surface.Smoothness = _Glossiness;
            // surface.Alpha = _Color.a;
        }
        
        ENDCG
    }
    FallBack "Diffuse"
}