Shader "Custom/DarkRed"
{
    Properties
    {
        _SpecColor ("Specular Color", Color) = (0.5, 0, 0, 1)
        _SpecIntensity ("Specular Intensity", Range(0, 1)) = 0.5
        _Shininess ("Shininess", Range(1, 100)) = 20
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 viewDir : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            float4 _SpecColor;
            float _SpecIntensity;
            float _Shininess;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                o.worldPos = worldPos;
                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float3 halfDir = normalize(IN.viewDir + UnityWorldSpaceLightDir(IN.worldPos));
                float spec = pow(max(dot(halfDir, IN.worldNormal), 0), _Shininess) * _SpecIntensity;
                fixed4 specColor = fixed4(_SpecColor.rgb * spec, 1);
                return specColor;
            }
            ENDCG
        }
    }

    FallBack "Universal Forward"
}
