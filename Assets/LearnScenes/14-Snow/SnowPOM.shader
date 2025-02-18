Shader "Learn/Snow/SnowPOM"
{
    Properties
    {
        _MainTex ("Diffuse map (RGB)", 2D) = "white" {}
        _HeightMap ("Height map (R)", 2D) = "white" {}
        _Parallax ("Height scale", Range (0.005, 0.1)) = 0.08
        _ParallaxSamples ("Parallax samples", Range (10, 100)) = 40

        _GroundTex ("Ground Texture", 2D) = "white" {}
        _GroundColor("Ground Color", Color) = (1,1,1,1)

    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "RenderType"="Opaque"
            }
            CGPROGRAM
            #pragma vertex vertex_shader
            #pragma fragment pixel_shader

            sampler2D _MainTex;
            sampler2D _HeightMap;
            float _Parallax;
            float _ParallaxSamples;
            uniform float4 _LightColor0;

            sampler2D _GroundTex;
            float4 _GroundColor;

            struct vertexInput
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 texcoord: TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct vertexOutput
            {
                float4 pos: SV_POSITION;
                float2 tex: TEXCOORD0;
                float4 posWorld: TEXCOORD1;
                float3 tSpace0 : TEXCOORD2;
                float3 tSpace1 : TEXCOORD3;
                float3 tSpace2 : TEXCOORD4;
                float3 normal : TEXCOORD5;
            };

            vertexOutput vertex_shader(vertexInput v)
            {
                vertexOutput o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                fixed3 worldNormal = mul(v.normal.xyz, (float3x3)unity_WorldToObject);
                fixed3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                o.tSpace0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
                o.tSpace1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
                o.tSpace2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.tex = v.texcoord;
                o.normal = v.normal;
                return o;
            }

            float4 pixel_shader(vertexOutput i): SV_TARGET
            {
                float3 normalDirection = normalize(i.normal);
                fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                fixed3 viewDir = i.tSpace0.xyz * worldViewDir.x + i.tSpace1.xyz * worldViewDir.y + i.tSpace2.xyz *
                    worldViewDir.z; // Transform view direction to tangent space
                float2 vParallaxDirection = normalize(viewDir.xy); // Get parallax direction

                float fParallaxLength = sqrt(length(viewDir) * length(viewDir) - viewDir.z * viewDir.z) / viewDir.z;
                float2 vParallaxOffsetTS = vParallaxDirection * fParallaxLength * _Parallax;


                float nMinSamples = 6;
                float nMaxSamples = min(_ParallaxSamples, 100);
                //根据视角和法线的夹角来决定采样次数
                int nNumSamples = (int)(lerp(nMinSamples, nMaxSamples, 1 - dot(worldViewDir, i.normal)));

                float fStepSize = 1.0 / (float)nNumSamples;

                float fCurrHeight = 0.0; //当前的高度
                float fPrevHeight = 1.0;
                float2 vTexOffsetPerStep = fStepSize * vParallaxOffsetTS; //每一步的偏移量
                float2 vTexCurrentOffset = i.tex.xy; //当前的纹理坐标
                float fCurrentBound = 1.0; //当前的限制高度，如果比这个高度高，就停止。是三角形相似的原理
                float fParallaxAmount = 0.0;
                float2 pt1 = 0;
                float2 pt2 = 0;
                float2 dx = ddx(i.tex.xy);
                float2 dy = ddy(i.tex.xy);
                for (int nStepIndex = 0; nStepIndex < nNumSamples; nStepIndex++)
                {
                    vTexCurrentOffset -= vTexOffsetPerStep;
                    fCurrHeight = 1 - tex2D(_HeightMap, vTexCurrentOffset, dx, dy).r;
                    fCurrentBound -= fStepSize;
                    if (fCurrHeight > fCurrentBound)
                    {
                        pt1 = float2(fCurrentBound, fCurrHeight);
                        pt2 = float2(fCurrentBound + fStepSize, fPrevHeight);
                        nStepIndex = nNumSamples + 1; //Exit loop
                        fPrevHeight = fCurrHeight;
                    }
                    else
                    {
                        fPrevHeight = fCurrHeight;
                    }
                }
                float fDelta2 = pt2.x - pt2.y;
                float fDelta1 = pt1.x - pt1.y;
                float fDenominator = fDelta2 - fDelta1;
                if (fDenominator == 0.0f)
                {
                    fParallaxAmount = 0.0f;
                }
                else
                {
                    fParallaxAmount = (pt1.x * fDelta2 - pt2.x * fDelta1) / fDenominator;
                }
                i.tex.xy -= vParallaxOffsetTS * (1 - fParallaxAmount);


                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 diffuseReflection = _LightColor0.rgb * saturate(dot(normalDirection, lightDirection));
                float3 color = diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.rgb;


                float4 tex = tex2D(_MainTex, i.tex.xy);
                float4 groundTex = tex2D(_GroundTex, i.tex.xy) * _GroundColor;
                tex.xyz = lerp(groundTex.xyz, tex.xyz, saturate(fParallaxAmount));


                // no lighting
                return tex;

                // lighting
                return float4(tex.xyz * color, 1.0);
            }
            ENDCG
        }
    }
}