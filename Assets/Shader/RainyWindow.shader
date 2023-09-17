Shader "Unlit/Window"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size("Size", float) = 5
        _T("Time", float) = 1
        _Distortion("Distortion", range(-4, 4)) = -3
        _Blur("Blur", range(0, 1)) = 0.10 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex, _CameraOpaqueTexture;
            float4 _MainTex_ST;
            float _Size, _T, _Distortion, _Blur;

            v2f vert (appdata v, out float4 outpos : SV_POSITION)
            {
                v2f o;
				outpos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float Noise(float2 p) {
               p = frac(p*float2(123.34, 345.45));
               p += dot(p, p + 34.345);
               return frac(p.x*p.y);
            }

            float3 RainDrop(float2 UV, float t) {

                float2 aspect = float2(2, 1);
                float2 uv = UV*_Size*aspect;
                uv.y += t*.3;
                float2 gv = frac(uv)-.5;
                float2 id = floor(uv);
                
                float n = Noise(id);
                t += n*6.2831;

                float w= UV.y * 12;
                float x = (n - .5)*.8;
                x += (.4-abs(x))*sin(3*w)*pow(sin(w), 6)*.45;
                float y = -sin(t+sin(t+sin(t)*.5))*.45;
                y -= (gv.x-x)*(gv.x-x);

                float2 dropPos = (gv - float2(x, y)) / aspect;
                float drop = smoothstep(.05, .03, length(dropPos));
                float2 trailPos = (gv - float2(x, 0)) / aspect;
                trailPos.y = (frac(trailPos.y * 8)-.5)/8;
                float trail = smoothstep(.03, .01, length(trailPos));
                float fogTrail = smoothstep(-.05, .05, dropPos.y);
                trail *= smoothstep(.5, y, gv.y);
                fogTrail *= smoothstep(-.05, .05, dropPos.y);
                trail *= fogTrail;
                fogTrail *= smoothstep(.05, .04, abs(dropPos.x));
                
                float2 offs = drop*dropPos + trail*trailPos;
                
                return float3(offs, fogTrail);
                
            }

            fixed4 frag (v2f i, UNITY_VPOS_TYPE vpos : VPOS) : SV_Target
            {
                float t = fmod(_Time.y + _T, 7200);
                fixed4 col = 0; 

                float3 drops = RainDrop(i.uv, t);
                drops += RainDrop(i.uv*1.34+8.9, t);
                drops += RainDrop(i.uv*1.14-3.59, t);
                drops += RainDrop(i.uv*1.73+3.34, t);
                float fade = 1 - saturate(fwidth(i.uv) * 60);
                float blur = _Blur * 7 * (1 - drops.z*fade);
                
                // screen texture uv
                float2 uv = vpos.xy / _ScreenParams.xy;
                uv += drops.xy * _Distortion * fade;
                blur *= .01;

                const float numSamples = 32;
                float a = Noise(i.uv)*6.2831;
                for (float i=0; i < numSamples; i++) {
                    float2 offs = float2(sin(a), cos(a)) * blur;
                    float d = frac(sin((i+1)*563.)*5249.);
                    d = sqrt(d);
                    offs *= d;
                    col += tex2D(_CameraOpaqueTexture, uv+offs);
                    a++;
                }
                col /= numSamples;
                return col*.85;
            }
            ENDCG
        }
    }
}
