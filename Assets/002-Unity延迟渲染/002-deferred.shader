Shader "Unlit/002-deferred"
{
    Properties
    {

    }
    SubShader
    {
        ZWrite Off
		Blend One One

        Pass
        {
            CGPROGRAM
			#pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
			//延迟渲染必须
			#pragma multi_compile_lightpass
			//排除不支持MRT的硬件
			#pragma exclude_renderers norm

            #include "UnityCG.cginc"
			#include "UnityDeferredLibrary.cginc"
			#include "UnityGBuffer.cginc"

			sampler2D _CameraGBufferTexture0;
			sampler2D _CameraGBufferTexture1;
			sampler2D _CameraGBufferTexture2;
			sampler2D _CameraGBufferTexture3;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			/*struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};*/

            unity_v2f_deferred vert(a2v v)
			{
                unity_v2f_deferred o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = ComputeScreenPos(o.pos);
				o.ray = UnityObjectToViewPos(v.vertex) * float3(-1, -1, 1);
				// _LightAsQuad,当处理四边形时，也就是直射光时返回1，否则返回0
				o.ray = lerp(o.ray, v.normal, _LightAsQuad);
				return o;
			}

            fixed4 frag(unity_v2f_deferred i) : SV_Target
            {
                /*float3 worldPos;
                float2 uv;
                half3 lightDir;
                float atten;
                float fadeDist;
                UnityDeferredCalculateLightParams(i, worldPos, uv, lightDir, atten, fadeDist);*/

				float2 uv = i.uv.xy / i.uv.w;

				//通过深度和方向重新构建世界坐标系
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = Linear01Depth(depth);

				//ray 只能表示方向，大小不一定，_ProjectionParams.z/i.ray.z表示ray到远平面的距离
				float3 rayToFarPlane = i.ray * (_ProjectionParams.z/i.ray.z);
				float4 viewPos = float4(rayToFarPlane * depth, 1);
				float3 worldPos = mul(unity_CameraToWorld, viewPos).xyz;

				float fadeDist = UnityComputeShadowFadeDistance(worldPos, viewPos.z);


				//对不同的光进行衰减计算，包括阴影计算
                if defined(SPOT)
                    float3 toLight = _LightPos.xyz - worldPos;
                    half3 lightDir = normalize(tolight);

                    float4 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1));
                    float atten = tex2Dbias(_LightTexture0, float4(uvCookie.xy / uvCookie.w, 0, -8)).w;

                    atten *= uvCookie < 0;

                    atten *= tex2D(_LightTextureB0, dot(toLight, toLight) * _LightPos.w).r;

                    atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);

                #elif defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
                    half3 lightDir = -_LightDir.xyz;
                    float atten = 1.0;

                    atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);

                    #if defined(DIRECTIONAL_COOKIE)
                    float4 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1));
                    atten *= tex2Dbias(_LightTexture0, float4(uvCookie.xy, 0, -8)).w;
                    #endif

                #elif defined(POINT) || defined(POINT_COOKIE)
                    float3 toLight = _LightPos.xyz - worldPos;
                    half3 lightDir = normalize(toLight);

                    float atten = tex2D(_LightTextureB0, dot(toLight, toLight) * _LightPos.w).r;

                    atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);

                    #if defined(POINT_COOKIE)
                    float4 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1));
                    atten *= texCUBEbias(_LightTexture0, float4(uvCookie.xyz, -8)).w;
                    #endif
                #else
                    half3 lightDir = 0;
                    float atten = 0;
                #endif


			}

            ENDCG
        }
    }
}
