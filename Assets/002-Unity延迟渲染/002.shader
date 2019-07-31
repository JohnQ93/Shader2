Shader "Unlit/002"
{
    Properties
    {
		_MainTex ("Texture", 2D) = "white"{}
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8, 255)) = 15
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		Pass
		{
			Tags { "LightMode"="Deferred" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct appdata 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			struct defferedOutPut
			{
				float4 gBuffer0 : SV_TARGET0;
				float4 gBuffer1 : SV_TARGET1;
				float4 gBuffer2 : SV_TARGET2;
				float4 gBuffer3 : SV_TARGET3;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			};

			defferedOutPut frag(v2f i)
			{
				defferedOutPut o;
				fixed3 color = tex2D(_MainTex, i.uv).rgb;
				o.gBuffer0.rgb = color * _Diffuse.rgb;
				o.gBuffer0.a = 1;
				o.gBuffer1.rgb = _Specular;
				o.gBuffer1.a = _Gloss / 255.0;
				o.gBuffer2 = float4(normalize(i.worldNormal) * 0.5 + 0.5, 1);
				o.gBuffer3 = float4(color, 1);

				return o;
			}

			ENDCG
		}
    }
}
