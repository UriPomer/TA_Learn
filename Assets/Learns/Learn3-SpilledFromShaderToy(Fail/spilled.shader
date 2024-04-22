Shader "Unlit/spilled"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _iFrame("iFrame",int) = 0
        _iMouse("iMouse", Vector) = (100, 100, 0, 0)
        _iChannel1("iChannel1", 2D) = "white" {}
        _iChannel2("iChannel2", 2D) = "white" {}
		_iChannelResolution0("iChannelResolution0", Vector) = (100, 100, 0, 0)
        _iChannelResolution1("iChannelResolution1", Vector) = (100, 100, 0, 0)
        _KEY_I("KEY_I",int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            int  _iFrame;                // shader playback frame
            fixed4      _iChannelResolution0; // channel resolution (in pixels)
            fixed4      _iChannelResolution1; // channel resolution (in pixels)
            fixed4      _iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
            sampler2D _iChannel1;         // input channel. XX = 2D/Cube
            sampler2D _iChannel2;         // input channel. XX = 2D/Cube
            int _KEY_I;
            
 
            

            #define RotNum 5
            //#define SUPPORT_EVEN_ROTNUM
            #define Res  _iChannelResolution0
            #define Res1 _iChannelResolution1
            
            
            const float ang = 2.0*3.1415926535/float(RotNum);
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 position : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            

            // float4 randS(float2 uv) {
            //     float2 noise;
            //     noise.x = frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            //     noise.y = frac(sin(dot(uv, float2(93.9898, 67.345))) * 24634.6345);
            //     return float4(noise - 0.5, 0, 0);
            // }

            float4 randS(float2 uv)
            {
                float2 resScale = _iChannelResolution0.xy / _iChannelResolution1.xy;
                return tex2D(_iChannel1, uv * resScale) - float4(0.5, 0.5, 0.5, 0.5);
            }

            

            float getRot(float2 pos, float2 b) {
                float2 p = b;
                float rot = 0.0;
                for (int i = 0; i < RotNum; i++) {
                    float2 sample = tex2D(_MainTex, frac((pos + p) / _ScreenParams.xy)).xy - 0.5;
                    rot += dot(sample, float2(p.y, -p.x));
                    float2x2 m = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));
                    p = mul(m, p);
                }
                return rot / RotNum / dot(b, b);
            }


            float4 channel1Noise(float2 fragCoord)
            {
                float2 uv = fragCoord.xy;
                
                uv -= floor(uv / 289.0) * 289.0;
                uv += float2(223.35734, 550.56781);
                uv *= uv;
                
                float xy = uv.x * uv.y;
                
                return  float4(frac(xy * 0.00000012),
                                 frac(xy * 0.00000543),
                                 frac(xy * 0.00000192),
                                 frac(xy * 0.00000423));
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                const float2x2 m = float2x2(cos(ang),sin(ang),-sin(ang),cos(ang));
                const float2x2 mh = float2x2(cos(ang*0.5),sin(ang*0.5),-sin(ang*0.5),cos(ang*0.5));
                float2 pos = i.position.xy;
                float rnd = randS(float2(float(_iFrame)/_ScreenParams.x,0.5/Res1.y)).x;
                
                float2 b = float2(cos(ang*rnd),sin(ang*rnd));
                float2 v=float2(0,0);
                float bbMax=0.7*_ScreenParams.y; bbMax*=bbMax;
                for(int l=0;l<20;l++)
                {
                    if ( dot(b,b) > bbMax ) break;
                    float2 p = b;
                    for(int i=0;i<RotNum;i++)
                    {
                        v+=p.yx*getRot(pos+p,b);
                        p = mul(m,p);
                    }
                    b*=2.0;
                }
                                
                float4 fragColor=tex2D(_MainTex,frac((pos+v*float2(-1,1)*2.0)/_ScreenParams.xy));
                // add a little "motor" in the center
                float2 scr=(i.position.xy/_ScreenParams.xy)*2.0-float2(1.0,1.0);
                fragColor.xy += (0.01*scr.xy / (dot(scr,scr)/0.1+0.3));
                
                if(_iFrame<=4 || _KEY_I>0.5) fragColor=tex2D(_iChannel2,i.position.xy/_ScreenParams.xy);
                return fixed4(fragColor.xyz,1.0);
            }
            ENDCG
        }
    }
}
