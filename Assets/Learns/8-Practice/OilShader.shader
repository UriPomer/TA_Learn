Shader "Custom/DynamicOilPainting" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Time ("Time", Float) = 0.0
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(0, 1)) = 0.5
        _SpecIntensity ("Specular Intensity", Range(0, 1)) = 0.5
        _BandCount ("Number of bands in the highlight", Range(1, 10)) = 5
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #include "Noise.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 lightDir : TEXCOORD1;
                float4 posWorld : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _SpecColor;
            float _Shininess;
            float _SpecIntensity;
            float _BandCount;
            // float4 _Time;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz - o.posWorld.xyz);
                o.viewDir = normalize(_WorldSpaceCameraPos - o.posWorld);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float ndotl = dot(i.normal, i.lightDir);
                float halfLambert = 0.5 + 0.5 * ndotl; // HalfLambert implementation
                halfLambert = halfLambert * halfLambert; // Square the result to simulate a softer lighting

                float3 halfDir = normalize(i.viewDir + i.lightDir);
                float spec = pow(max(dot(halfDir, i.normal), 0.0), _Shininess) * _SpecIntensity;

                spec = floor(spec * _BandCount) / _BandCount; // Create bands in the specular highlight


                float2 uv = i.uv * 10.0; // Scale UV to enhance noise pattern
                float noiseValue = snoise(float3(uv, _Time.y * 0.1),0.4); // Using simplex noise

                float3 color;
                if (noiseValue < -0.33) {
                    color = float3(1, 1, 0); // Yellow
                } else if (noiseValue < 0.33) {
                    color = float3(0.5, 1, 0); // Light Green
                } else {
                    color = float3(1, 1, 1); // White
                }
                // Apply lighting
                color *= halfLambert;
                color += spec * _SpecColor.rgb;

                return float4(color, 1);
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
