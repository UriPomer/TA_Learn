Shader "Custom/HeartfeltRain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TimeScale ("Time Scale", Float) = 1.0
        _RainAmount ("Rain Amount", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Transparent"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"


            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _TimeScale;
            float _RainAmount;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 grabUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 N13(float p)
            {
                float3 p3 = frac(float3(p, p, p) * float3(.1031, .11369, .13787));
                p3 += dot(p3, p3.yzx + 19.19);
                return frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
            }

            float4 N14(float t)
            {
                return frac(sin(t * float4(123.0, 1024.0, 1456.0, 264.0)) * float4(6547.0, 345.0, 8799.0, 1564.0));
            }

            float N(float t)
            {
                return frac(sin(t * 12345.564) * 7658.76);
            }

            float Saw(float b, float t)
            {
                return smoothstep(0.0, b, t) * smoothstep(1.0, b, t);
            }

            float StaticDrops(float2 uv, float t)
            {
                uv *= 40.0;
                float2 id = floor(uv);
                uv = frac(uv) - 0.5;
                float3 n = N13(id.x * 107.45 + id.y * 3543.654);
                float2 p = (n.xy - 0.5) * 0.7;
                float d = length(uv - p);
                float fade = Saw(0.025, frac(t + n.z));
                float c = smoothstep(0.3, 0.0, d) * frac(n.z * 10.0) * fade;
                return c;
            }

            float2 DropLayer2(float2 uv, float t)
            {
                float2 UV = uv;
                uv.y += t * 0.75;
                float2 a = float2(6.0, 1.0);
                float2 grid = a * 2.0;
                float2 id = floor(uv * grid);
                float colShift = N(id.x);
                uv.y += colShift;
                id = floor(uv * grid);
                float3 n = N13(id.x * 35.2 + id.y * 2376.1);
                float2 st = frac(uv * grid) - float2(0.5, 0);
                float x = n.x - 0.5;
                float y = UV.y * 20.0;
                float wiggle = sin(y + sin(y));
                x += wiggle * (0.5 - abs(x)) * (n.z - 0.5);
                x *= 0.7;
                float ti = frac(t + n.z);
                y = (Saw(0.85, ti) - 0.5) * 0.9 + 0.5;
                float2 p = float2(x, y);
                float d = length((st - p) * a.yx);
                float mainDrop = smoothstep(0.4, 0.0, d);
                float r = sqrt(smoothstep(1.0, y, st.y));
                float cd = abs(st.x - x);
                float trail = smoothstep(0.23 * r, 0.15 * r * r, cd);
                float trailFront = smoothstep(-0.02, 0.02, st.y - y);
                trail *= trailFront * r * r;
                y = UV.y;
                float trail2 = smoothstep(0.2 * r, 0.0, cd);
                float droplets = max(0.0, (sin(y * (1.0 - y) * 120.0) - st.y)) * trail2 * trailFront * n.z;
                y = frac(y * 10.0) + (st.y - 0.5);
                float dd = length(st - float2(x, y));
                droplets = smoothstep(0.3, 0.0, dd);
                float m = mainDrop + droplets * r * trailFront;
                return float2(m, trail);
            }

            float2 Drops(float2 uv, float t, float l0, float l1, float l2)
            {
                float s = StaticDrops(uv, t) * l0;
                float2 m1 = DropLayer2(uv, t) * l1;
                float2 m2 = DropLayer2(uv * 1.85, t) * l2;
                float c = s + m1.x + m2.x;
                c = smoothstep(0.3, 1.0, c);
                return float2(c, max(m1.y * l0, m2.y * l1));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv * 2.0 - 1.0;
                float time = _Time.y * _TimeScale;
                float rainAmount = _RainAmount;
                float t = time * 0.2;
                float maxBlur = lerp(3.0, 6.0, rainAmount);
                float minBlur = 2.0;

                float staticDrops = smoothstep(-0.5, 1.0, rainAmount) * 2.0;
                float layer1 = smoothstep(0.25, 0.75, rainAmount);
                float layer2 = smoothstep(0.0, 0.5, rainAmount);

                float2 c = Drops(uv, t, staticDrops, layer1, layer2);
                float2 n = float2(ddx(c.x), ddy(c.x));

                float focus = lerp(maxBlur - c.y, minBlur, smoothstep(0.1, 0.2, c.x));
                float3 col = tex2Dlod(_MainTex, float4(i.uv + n, 0, focus)).rgb;

                float colFade = sin((time + 3.0) * 0.5) * 0.5 + 0.5;
                col *= lerp(float3(1.0, 1.0, 1.0), float3(0.8, 0.9, 1.3), colFade);
                float fade = smoothstep(0.0, 10.0, time);
                float lightning = sin(time * sin(time * 10.0));
                lightning *= pow(max(0.0, sin(time + sin(time))), 10.0);
                col *= 1.0 + lightning * fade;
                col *= 1.0 - dot(i.uv - 0.5, i.uv - 0.5);
                return float4(col * fade, 1.0);
            }
            ENDCG
        }
    }
}