Shader "JourneySand_URP_Study"
{
    Properties
    {
        _BaseColor("BaseColor" , Color) = (1,1,1,1)
        _MainTex("_MainTex", 2D) = "white" {}
        _Roughness("_Roughness", Range( 0 , 1)) = 0.5
        _NormalMapShallowX("_NormalMapShallowX", 2D) = "bump" {}
        _NormalMapShallowZ("_NormalMapShallowZ", 2D) = "bump" {}
        _ShallowBumpScale("_ShallowBumpScale", Range( 0 , 1)) = 1
        _NormalMapSteepX("_NormalMapSteepX", 2D) = "bump" {}
        _NormalMapSteepZ("_NormalMapSteepZ", 2D) = "bump" {}
        _SurfaceNormalScale("_SurfaceNormalScale", Range( 0 , 1)) = 1
        _DetailBumpMap("_DetailBumpMap", 2D) = "bump" {}
        _DetailBumpScale("_DetailBumpScale", Range( 0 , 20)) = 0
        _OceanSpecularShiness("_OceanSpecularShiness", Range(0.0001,10)) = 1
        _Glossiness("_Glossiness ", Float) = 1
        _OceanSpecularMutiplyer("_OceanSpecularMutiplyer", Float) = 0
        [HDR] _OceanSpecularColor("_OceanSpecularColor", Color) = (1,1,1,1)
        _SpecularMutiplyer("_SpecularMutiplyer", Float) = 0

        _GlitterTex( "Glitter Noise Map " , 2D ) = "white" {}
        _Glitterness("_Glitterness", Float) = 1
        _GlitterRange("_GlitterRange", Float) = 1
        _GlitterColor("_GlitterColor", Color) = (1,1,1,1)
        _GlitterMutiplyer("_GlitterMutiplyer", Float) = 1


    }

    SubShader
    {
        LOD 0


        Tags
        {
            "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"
        }

        Cull Back
        AlphaToMask Off


        Pass
        {

            Name "Forward"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            Blend One Zero, One Zero
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma multi_compile_fog


            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            #pragma vertex vert
            #pragma fragment frag

            #define SHADERPASS_FORWARD

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"


            #include "OrenNayarDiffuse.hlsl"
            #include "MySpecularDistribution.hlsl"
            #include "GGXGeometricShadowingFunction.hlsl"
            #include "FresnelFunction.hlsl"
            //  #include "GliterDistribution.hlsl"


            struct VertexInput
            {
                float4 posWS : POSITION;
                float3 normalOS : NORMAL;
                float4 uv : TEXCOORD0;
                float4 tangentOS : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 posCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float4 shadowCoord : TEXCOORD1;
                float fogFactor : TEXCOORD2;
                float4 uv : TEXCOORD3;
                float3 viewWS : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
                float3 bitangentWS : TEXCOORD6;
                float3 normalWS : TEXCOORD7;
                half4 fogFactorAndVertexLight : TEXCOORD8;
                float4 lightmapUVOrVertexSH : TEXCOORD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _GlitterColor;
                float4 _OceanSpecularColor;
                float4 _NormalMapSteepX_ST;
                float4 _NormalMapSteepZ_ST;
                float4 _DetailBumpMap_ST;
                float4 _NormalMapShallowX_ST;
                float4 _NormalMapShallowZ_ST;
                float4 _GlitterTex_ST;
                float _Roughness;
                float _OceanSpecularMutiplyer;
                float _OceanSpecularShiness;
                float _Glitterness;
                float _Glossiness;
                float _DetailBumpScale;
                float _SpecularMutiplyer;
                float _SurfaceNormalScale;
                float _GlitterRange;
                float _ShallowBumpScale;
                float _GlitterMutiplyer;
                float4 _BaseColor;

            CBUFFER_END

            sampler2D _MainTex;
            sampler2D _NormalMapShallowX;
            sampler2D _NormalMapShallowZ;
            sampler2D _NormalMapSteepX;
            sampler2D _NormalMapSteepZ;
            sampler2D _DetailBumpMap;
            sampler2D _GlitterTex;

            float3 GetSurfaceNormal(float2 uv, float3 temNormal)
            {
                float xzRate = atan(abs(temNormal.z / temNormal.x));
                xzRate = saturate(pow(xzRate, 9));

                float steepness = atan(1 / temNormal.y);
                steepness = saturate(pow(steepness, 3));
                float3 shallowX = UnpackNormal(tex2D(_NormalMapShallowX, _NormalMapShallowX_ST.xy * uv.xy + _NormalMapShallowX_ST.zw));
                float3 shallowZ = UnpackNormal(tex2D(_NormalMapShallowZ, _NormalMapShallowZ_ST.xy * uv.xy + _NormalMapShallowZ_ST.zw));
                float3 shallow = shallowX * shallowZ * _ShallowBumpScale;
                float3 steepX = UnpackNormal(tex2D(_NormalMapSteepX, _NormalMapSteepX_ST.xy * uv.xy + _NormalMapSteepX_ST.zw));
                float3 steepZ = UnpackNormal(tex2D(_NormalMapSteepZ, _NormalMapSteepZ_ST.xy * uv.xy + _NormalMapSteepZ_ST.zw));
                float3 steep = lerp(steepX, steepZ, xzRate);
                return normalize(lerp(shallow, steep, steepness));
            }


            float3 GetGlitterNoise(float2 uv)
            {
                return tex2D(_GlitterTex, _GlitterTex_ST.xy * uv.xy + _GlitterTex_ST.zw);
            }


            float GliterDistribution(float3 lightDir, float3 normal, float3 view, float2 uv, float3 pos)
            {
                float specBase = saturate(1 - dot(normal, view) * 2);
                float specPow = pow(specBase, 10 / _GlitterRange);
                // Get the glitter sparkle from the noise image
                float3 noise = GetGlitterNoise(uv);
                // A very random function to modify the glitter noise 
                float p1 = GetGlitterNoise(uv + float2(0, _Time.y * 0.0003 + view.x * 0.006)).r;
                float p2 = GetGlitterNoise(uv + float2(_Time.y * 0.00025, _Time.y * 0.0005 + view.y * 1)).g;
                float sum = 4 * p1 * p2;
                float glitter = pow(sum, _Glitterness);
                glitter = max(0, glitter * _GlitterMutiplyer - 0.5) * 2;
                float sparkle = glitter * specPow;

                return sparkle;
            }

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.worldPos = TransformObjectToWorld(v.posWS.xyz);
                o.posCS = TransformObjectToHClip(v.posWS.xyz);
                o.uv = v.uv;
                //o.view = normalize(WorldSpaceViewDir(v.vertex));
                o.viewWS = GetWorldSpaceNormalizeViewDir(o.worldPos);
                float3 positionWS = o.worldPos;

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = float4(normalInput.normalWS, positionWS.x);
                o.tangentWS = float4(normalInput.tangentWS, positionWS.y);
                o.bitangentWS = float4(normalInput.bitangentWS, positionWS.z);

                half3 vertexLight = VertexLighting(positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(o.posCS.z);
                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                return o;
            }


            half4 frag(VertexOutput i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float3 normalSurface = normalize(GetSurfaceNormal(i.uv, i.normalWS));
                //////////////////////////////////////////////////////////////////////
                float3x3 TBN = float3x3(normalize(i.tangentWS), normalize(i.bitangentWS), normalize(i.normalWS));
                TBN = transpose(TBN);
                //////////////////////////////////////////////////////////////////////
                float3 normal = TransformWorldToTangent(normalSurface, TBN);
                normal = normalize(normal * _SurfaceNormalScale + i.normalWS);
                float3 WorldPos = i.worldPos;
                ////////////////////////////////////////////////////
                float4 ShadowCoords = float4(0, 0, 0, 0);
                ShadowCoords = TransformWorldToShadowCoord(WorldPos);
                //  float3 detail = GetDetailNormal(i.uv);
                ////////////////////////////////////////////////////
                float2 uv_DetailBumpMap = i.uv.xy * _DetailBumpMap_ST.xy + _DetailBumpMap_ST.zw;
                float3 detail = UnpackNormalScale(tex2D(_DetailBumpMap, uv_DetailBumpMap), 1.0f);
                detail = mul(TBN, detail);
                float3 normalDetail = normalize(detail * _DetailBumpScale + normal);
                ////////////////////////////////////////////////////
                float2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float4 mainColor = tex2D(_MainTex, uv_MainTex) * _BaseColor;
                ////////////////////////////////////////////////////////////////////////////
                Light light = GetMainLight();
                float3 lightDirection = light.direction;
                float3 lightColor = light.color * light.distanceAttenuation;
                float3 viewDirection = normalize(i.viewWS);
               // float3 halfDirection = normalize(viewDirection + lightDirection);
                float4 ambientCol = unity_AmbientSky;
              //  float LdotH = max(0, dot(lightDirection, halfDirection));
                float3 diffuseCol = lightColor * mainColor * (OrenNayarDiffuse(lightDirection, viewDirection, normal, _Roughness));

                float3 oceanSpecularColor = lightColor * _OceanSpecularColor * MySpecularDistribution(_OceanSpecularShiness, lightDirection, viewDirection, normal, detail, _Glossiness) * GGXGeometricShadowingFunction(lightDirection, viewDirection, normalDetail, _Roughness) * FresnelFunction(_OceanSpecularColor, lightDirection, viewDirection) / abs(4 * max(0.1, dot(normalDetail, lightDirection)) * max(0.1, dot(normalDetail, viewDirection)));
                // return float4(oceanSpecularColor,1);

                float3 specularColor = float3(0, 0, 0);
                specularColor = saturate(max(_OceanSpecularMutiplyer * oceanSpecularColor, _SpecularMutiplyer * specularColor));
                // return float4(specularColor,1);
                float4 glitterColor = _GlitterColor * GliterDistribution(lightDirection, normalDetail, viewDirection, i.uv, WorldPos);
                
                float3 Albedo = (diffuseCol + specularColor + ambientCol + glitterColor).rgb;
                float3 Normal = normal;
                float3 Emission = 0;
                float3 Specular = 0.5;
                float Metallic = 0.0;
                float Smoothness = 0.0;
                float Occlusion = 1.0;
                float Alpha = 1;
                float3 BakedGI = 0;

                InputData inputData;
                inputData.positionWS = WorldPos;
                inputData.viewDirectionWS = viewDirection;
                inputData.shadowCoord = ShadowCoords;
                inputData.normalWS = Normal;
                inputData.fogCoord = i.fogFactorAndVertexLight.x;
                inputData.vertexLighting = i.fogFactorAndVertexLight.yzw;
                float3 SH = i.lightmapUVOrVertexSH.xyz;

                // inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
                inputData.bakedGI = BakedGI;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.posCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);


                half4 color = UniversalFragmentPBR(
                    inputData,
                    Albedo,
                    Metallic,
                    Specular,
                    Smoothness,
                    Occlusion,
                    Emission,
                    Alpha);
                color.rgb = MixFog(color.rgb, i.fogFactorAndVertexLight.x);
                return color;
            }
            ENDHLSL
        }


        Pass
        {

            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            AlphaToMask Off
            ColorMask 0

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #define ASE_SRP_VERSION 999999


            #pragma vertex vert
            #pragma fragment frag
            #if ASE_SRP_VERSION >= 110000
            #pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #endif
            #define SHADERPASS SHADERPASS_SHADOWCASTER

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
                #endif
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _GlitterColor;
                float4 _OceanSpecularColor;
                float4 _NormalMapSteepX_ST;
                float4 _DetailBumpMap_ST;
                float4 _NormalMapShallowX_ST;
                float _Roughness;
                float _OceanSpecularMutiplyer;
                float _OceanSpecularShiness;
                float _Glitterness;
                float _Glossiness;
                float _DetailBumpScale;
                float _SpecularMutiplyer;
                float _SurfaceNormalScale;
                float _GlitterRange;
                float _ShallowBumpScale;
                float _GlitterMutiplyer;
                #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
                #endif
            CBUFFER_END


            float3 _LightDirection;
            #if ASE_SRP_VERSION >= 110000
            float3 _LightPosition;
            #endif
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif

                v.ase_normal = v.ase_normal;

                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);

                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
                #endif

                float3 normalWS = TransformObjectToWorldDir(v.ase_normal);
                #if ASE_SRP_VERSION >= 110000
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
				float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif
                float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                #if UNITY_REVERSED_Z
                clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
                #else
				clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                #else
				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );
                #if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
                #else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                #endif
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
                #endif
                o.clipPos = clipPos;

                return o;
            }


            half4 frag(VertexOutput i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = i.worldPos;
                #endif
                float4 ShadowCoords = float4(0, 0, 0, 0);

                #if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
                #endif
                #endif


                float Alpha = 1;
                float AlphaClipThreshold = 0.5;
                float AlphaClipThresholdShadow = 0.5;

                #ifdef _ALPHATEST_ON
                #ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
                #else
						clip(Alpha - AlphaClipThreshold);
                #endif
                #endif

                #ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( i.clipPos.xyz, unity_LODFade.x );
                #endif
                return 0;
            }
            ENDHLSL
        }

        Pass
        {

            Name "DepthOnly"
            Tags
            {
                "LightMode"="DepthOnly"
            }

            ZWrite On
            ColorMask 0
            AlphaToMask Off

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #define ASE_SRP_VERSION 999999


            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
                #endif
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _GlitterColor;
                float4 _OceanSpecularColor;
                float4 _NormalMapSteepX_ST;
                float4 _DetailBumpMap_ST;
                float4 _NormalMapShallowX_ST;
                float _Roughness;
                float _OceanSpecularMutiplyer;
                float _OceanSpecularShiness;
                float _Glitterness;
                float _Glossiness;
                float _DetailBumpScale;
                float _SpecularMutiplyer;
                float _SurfaceNormalScale;
                float _GlitterRange;
                float _ShallowBumpScale;
                float _GlitterMutiplyer;
                #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
                #endif
            CBUFFER_END


            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif

                v.ase_normal = v.ase_normal;

                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);

                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
                #endif

                o.clipPos = TransformWorldToHClip(positionWS);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
                #endif
                return o;
            }


            half4 frag(VertexOutput i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                #if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = i.worldPos;
                #endif
                float4 ShadowCoords = float4(0, 0, 0, 0);

                #if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
                #endif
                #endif


                float Alpha = 1;
                float AlphaClipThreshold = 0.5;

                #ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
                #endif

                #ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( i.clipPos.xyz, unity_LODFade.x );
                #endif
                return 0;
            }
            ENDHLSL
        }

    }

    CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
    Fallback "Hidden/InternalErrorShader"
}