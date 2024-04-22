Shader "Shader/Custom/Lambert"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
            // 输入结构
            struct appdata
            {
                float4 vertex : POSITION;// 将模型顶点信息输入进来
                float4 normal : NORMAL;  // 将模型法线信息输入进来
            };
            // 输出结构
            struct v2f
            {
                float4 vertex : SV_POSITION;// 由模型顶点信息换算而来的顶点屏幕位置
                float3 nDirWS : TEXCOORD0; // 由模型法线信息换算来的世界空间法线信息
            };
            // 输入结构>>>顶点Shader>>>输出结构
            v2f vert (appdata v)
            {
                v2f o;// 新建一个输出结构
                o.vertex = UnityObjectToClipPos(v.vertex);// 变换顶点信息 并将其塞给输出结构
                o.nDirWS = UnityObjectToWorldNormal(v.normal);  // 变换法线信息 并将其塞给输出结构
                return o;
            }
            // 输出结构>>>像素
            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = i.nDirWS;                         // 获取nDir
                float3 lDir = _WorldSpaceLightPos0.xyz;         // 获取lDir
                float nDotl = dot(nDir, lDir);              // nDir点积lDir
                float lambert = max(0.0, nDotl);                  // 截断负值
                return float4(lambert, lambert, lambert, 1.0);                                   // 输出最终颜色
            }
            ENDCG
        }
    }
}