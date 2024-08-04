// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Shadertoy/Raymarched" {
    Properties{
        iMouse("Mouse Pos", Vector) = (100, 100, 0, 0)
        iChannel0("iChannel0", 2D) = "white" {}
        iChannelResolution0("iChannelResolution0", Vector) = (100, 100, 0, 0)
    }
 
        CGINCLUDE
#include "UnityCG.cginc"   
#pragma target 3.0      
 
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat2 float2x2
#define mat3 float3x3
#define mat4 float4x4
#define iGlobalTime _Time.y
#define iTime _Time.y
#define mod fmod
#define mix lerp
#define fract frac
#define texture2D tex2D
#define iResolution _ScreenParams
#define gl_FragCoord ((_iParam.scrPos.xy/_iParam.scrPos.w) * _ScreenParams.xy)
 
#define PI2 6.28318530718
#define pi 3.14159265358979
#define halfpi (pi * 0.5)
#define oneoverpi (1.0 / pi)
 
            fixed4 iMouse;
        sampler2D iChannel0;
        fixed4 iChannelResolution0;
 
        struct v2f {
            float4 pos : SV_POSITION;
            float4 scrPos : TEXCOORD0;
        };
 
        v2f vert(appdata_base v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.scrPos = ComputeScreenPos(o.pos);
            return o;
        }

        float heightMap(in vec2 p) { 
    
            p *= 3.;
            
            // Hexagonal coordinates.
            vec2 h = vec2(p.x + p.y*.57735, p.y*1.1547);
            
            // Closest hexagon center.
            vec2 f = fract(h); h -= f;
            float c = fract((h.x + h.y)/3.);
            h =  c<.666 ?   c<.333 ?  h  :  h + 1.  :  h  + step(f.yx, f); 
        
            p -= vec2(h.x - h.y*.5, h.y*.8660254);
            
            c = fract(cos(dot(h, vec2(41, 289)))*43758.5453); // Reusing "c."
            p -= p*step(c, .5)*2.; // Equivalent to: if (c<.5) p *= -1.;
            
            // Minimum squared distance to neighbors. Taking the square root after comparing, for speed.
            // Three partitions need to be checked due to the flipping process.
            p -= vec2(-1, 0);
            c = dot(p, p); // Reusing "c" again.
            p -= vec2(1.5, .8660254);
            c = min(c, dot(p, p));
            p -= vec2(0, -1.73205);
            c = min(c, dot(p, p));
            
            return sqrt(c);
        
        }
        
        // Raymarching an XY-plane - raised a little by the hexagonal Truchet heightmap. Pretty standard.
        float map(vec3 p){
            
            
            float c = heightMap(p.xy); // Height map.
            // Wrapping, or folding the height map values over, to produce the nicely lined-up, wavy patterns.
            c = cos(c*6.283*1.) + cos(c*6.283*2.);
            c = (clamp(c*.6+.5, 0., 1.));
        
            
            // Back plane, placed at vec3(0., 0., 1.), with plane normal vec3(0., 0., -1).
            // Adding some height to the plane from the heightmap. Not much else to it.
            return 1. - p.z - c*.025;
        
            
        }
        
        // The normal function with some edge detection and curvature rolled into it. Sometimes, it's possible to 
        // get away with six taps, but we need a bit of epsilon value variance here, so there's an extra six.
        vec3 getNormal(vec3 p, inout float edge, inout float crv) { 
            
            vec2 e = vec2(.01, 0); // Larger epsilon for greater sample spread, thus thicker edges.
        
            // Take some distance function measurements from either side of the hit point on all three axes.
            float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
            float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
            float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
            float d = map(p)*2.;	// The hit point itself - Doubled to cut down on calculations. See below.
             
            // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
            // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
            // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface 
            // curves that register a discernible difference.
            edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
            //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.
            
            // Once you have an edge value, it needs to normalized, and smoothed if possible. How you 
            // do that is up to you. This is what I came up with for now, but I might tweak it later.
            edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
            
            // We may as well use the six measurements to obtain a rough curvature value while we're at it.
            crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .6, 0., 1.);
            
            // Redoing the calculations for the normal with a more precise epsilon value.
            e = vec2(.0025, 0);
            d1 = map(p + e.xyy), d2 = map(p - e.xyy);
            d3 = map(p + e.yxy), d4 = map(p - e.yxy);
            d5 = map(p + e.yyx), d6 = map(p - e.yyx); 
            
            
            // Return the normal.
            // Standard, normalized gradient mearsurement.
            return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
        }


        
        // I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
        // Anyway, I like this one. I'm assuming it's based on IQ's original.
        float calculateAO(in vec3 p, in vec3 n)
        {
            float sca = 2., occ = 0.;
            for(float i=0.; i<5.; i++){
            
                float hr = .01 + i*.5/4.;        
                float dd = map(n * hr + p);
                occ += (hr - dd)*sca;
                sca *= 0.7;
            }
            return clamp(1.0 - occ, 0., 1.);    
        }

        
        // Compact, self-contained version of IQ's 3D value noise function.
        float n3D(vec3 p){
            
            const vec3 s = vec3(7, 157, 113);
            vec3 ip = floor(p); p -= ip; 
            vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
            p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
            h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
            h.xy = mix(h.xz, h.yw, p.y);
            return mix(h.x, h.y, p.z); // Range: [0, 1].
        }
        
        // Simple environment mapping. Pass the reflected vector in and create some
        // colored noise with it. The normal is redundant here, but it can be used
        // to pass into a 3D texture mapping function to produce some interesting
        // environmental reflections.
        vec3 envMap(vec3 rd, vec3 sn){
            
            vec3 sRd = rd; // Save rd, just for some mixing at the end.
            
            // Add a time component, scale, then pass into the noise function.
            rd.xy -= iTime*.25;
            rd *= 3.;
            
            float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15; // Noise value.
            c = smoothstep(0.4, 1., c); // Darken and add contast for more of a spotlight look.
            
            vec3 col = vec3(c, c*c, c*c*c*c); // Simple, warm coloring.
            //vec3 col = vec3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)); // More color.
            
            // Mix in some more red to tone it down and return.
            return mix(col, col.yzx, sRd*.25+.25); 
            
        }
        
        // vec2 to vec2 hash.
        vec2 hash22(vec2 p) { 
        
            // Faster, but doesn't disperse things quite as nicely as other combinations. :)
            float n = sin(dot(p, vec2(41, 289)));
            return fract(vec2(262144, 32768)*n)*.75 + .25; 

        }
        float Voronoi(in vec2 p){
            
            vec2 g = floor(p), o; p -= g;
            
            vec3 d = vec3(1,1,1); // 1.4, etc. "d.z" holds the distance comparison value.
            
            for(int y = -1; y <= 1; y++){
                for(int x = -1; x <= 1; x++){
                    
                    o = vec2(x, y);
                    o += hash22(g + o) - p;
                    
                    d.z = dot(o, o); 
                    
                    d.y = max(d.x, min(d.y, d.z));
                    d.x = min(d.x, d.z); 
                }
            }
            
            return max(d.y/1.2 - d.x*1., 0.)/1.2;
        }
 
        vec4 main(vec2 fragCoord);
 
        fixed4 frag(v2f _iParam) : SV_Target {
            vec2 fragCoord = gl_FragCoord;
            return main(gl_FragCoord);
        }
 
        vec4 main(vec2 fragCoord) {
            vec3 rd = normalize(vec3(2.*fragCoord - iResolution.xy, iResolution.y));
        
            float tm = iTime/2.0;
            // Rotate the XY-plane back and forth. Note that sine and cosine are kind of rolled into one.
            vec2 a = sin(vec2(1.570796, 0) + sin(tm/4.0)*0.3); // Fabrice's observation.
            rd.xy = mul(mat2(a.x, -a.y, a.y, a.x) , rd.xy);
            // Ray origin. Moving in the X-direction to the right.
            vec3 ro = vec3(tm, cos(tm/4.0), 0.0);
            
            
            // Light position, hovering around behind the camera.
            vec3 lp = ro + vec3(cos(tm/2.0)*.5, sin(tm/2.0)*0.5, -0.5);
            
            // Standard raymarching segment. Because of the straight forward setup, not many iterations are necessary.
            float d, t=0.;
            for(int j=0;j<32;j++){
              
                d = map(ro + rd*t); // distance to the function.
                t += d*0.7; // Total distance from the camera to the surface.
                
                // The plane "is" the far plane, so no far=plane break is needed.
                if(d<0.001) break; 
            
            }
            
            // Edge and curve value. Passed into, and set, during the normal calculation.
            float edge, crv;
           
            // Surface postion, surface normal and light direction.
            vec3 sp = ro + rd*t;
            vec3 sn = getNormal(sp, edge, crv);
            vec3 ld = lp - sp;
            
            
            
            // Coloring and texturing the surface.
            //
            // Height map.
            float c = heightMap(sp.xy); 
            
            // Folding, or wrapping, the values above to produce the snake-like pattern that lines up with the randomly
            // flipped hex cells produced by the height map.
            vec3 fold = cos(vec3(1, 2, 4)*c*6.283);
            
            // Using the height map value, then wrapping it, to produce a finer grain Truchet pattern for the overlay.
            float c2 = heightMap((sp.xy + sp.z*.025)*6.);
            c2 = cos(c2*6.283*3.);
            c2 = (clamp(c2+.5, 0., 1.)); 
        
            
            // Function based bump mapping. I prefer none in this example, but it's there if you want it.   
            //if(temp.x>0. || temp.y>0.) sn = dbF(sp, sn, .001);
            
            // Surface color value.
            vec3 oC = vec3(1,1,1);
        
            if(fold.x>0.) oC = vec3(1, .05, .1)*c2; // Reddish pink with finer grained Truchet overlay.
            
            if(fold.x<0.05 && (fold.y)<0.) oC = vec3(1, .7, .45)*(c2*.25 + .75); // Lighter lined borders.
            else if(fold.x<0.) oC = vec3(1, .8, .4)*c2; // Gold, with overlay.
                
            //oC *= n3D(sp*128.)*.35 + .65; // Extra fine grained noisy texturing.
        
             
            // Sending some greenish particle pulses through the snake-like patterns. With all the shininess going 
            // on, this effect is a little on the subtle side.
            float p1 = 1.0 - smoothstep(0., .1, fold.x*.5+.5); // Restrict to the snake-like path.
            // Other path.
            //float p2 = 1.0 - smoothstep(0., .1, cos(heightMap(sp.xy + 1. + iTime/4.)*6.283)*.5+.5);
            float p2 = 1.0 - smoothstep(0., .1, Voronoi(sp.xy*4. + vec2(tm, cos(tm/4.))));
            p1 = (p2 + .25)*p1; // Overlap the paths.
            oC += oC.yxz*p1*p1; // Gives a kind of electron effect. Works better with just Voronoi, but it'll do.
            
           
            
            
            float lDist = max(length(ld), 0.001); // Light distance.
            float atten = 1./(1. + lDist*.125); // Light attenuation.
            
            ld /= lDist; // Normalizing the light direction vector.
            
            float diff = max(dot(ld, sn), 0.); // Diffuse.
            float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 16.); // Specular.
            float fre = pow(clamp(dot(sn, rd) + 1., .0, 1.), 3.); // Fresnel, for some mild glow.
            
            // Shading. Note, there are no actual shadows. The camera is front on, so the following
            // two functions are enough to give a shadowy appearance.
            crv = crv*.9 + .1; // Curvature value, to darken the crevices.
            float ao = calculateAO(sp, sn); // Ambient occlusion, for self shadowing.
        
         
            
            // Combining the terms above to light the texel.
            vec3 col = oC*(diff + .5) + vec3(1., .7, .4)*spec*2. + vec3(.4, .7, 1)*fre;
            
            col += (oC*.5+.5)*envMap(reflect(rd, sn), sn)*6.; // Fake environment mapping.
         
            
            // Edges.
            col *= 1. - edge*.85; // Darker edges.   
            
            // Applying the shades.
            col *= (atten*crv*ao);
        
        
            // Rough gamma correction, then present to the screen.
            return  vec4(sqrt(clamp(col, 0., 1.)), 1.);
        }
 
        ENDCG
 
            SubShader{
                Pass {
                    CGPROGRAM
 
                    #pragma vertex vert    
                    #pragma fragment frag    
                    #pragma fragmentoption ARB_precision_hint_fastest     
 
                    ENDCG
                }
        }
            FallBack Off
}