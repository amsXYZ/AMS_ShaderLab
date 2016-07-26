Shader "Custom/LocalSmear2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ShadowColor ("Shadow color", Color) = (0,0,0,1)
		_Levels ("Shadow levels", Range(1, 20)) = 5
		_Intensity ("Smear intensity", Range(0,10)) = 1
		_NoiseTexture ("Noise Texture", 2D) = "white" {}
		[MaterialToggle] _Noise("Noise?", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			
			Cull Off
			Blend One Zero
			ZWrite On

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0

			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 pos : POSITION;
				float4 colorDisplacement : COLOR0;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD3;
				float4 noiseuv : TEXCOORD4;

				LIGHTING_COORDS(1, 2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;

			float4 _ShadowColor;
			float _Levels;
			float _Intensity;
			float _Noise;
			
			v2f vert (appdata v)
			{
				v2f o;

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.noiseuv = float4(TRANSFORM_TEX(v.uv, _NoiseTex),1,1);

				float dispNormalIntensity = max(0, dot(-v.colorDisplacement.xyz, v.normal));
				o.noiseuv.z = dispNormalIntensity;
				float displacement = _Intensity * lerp(1, tex2Dlod(_NoiseTex, o.noiseuv), _Noise) * dispNormalIntensity;

				o.pos = mul(UNITY_MATRIX_MVP, v.pos + displacement);
				o.normal = UnityObjectToWorldNormal(v.normal);

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				return i.noiseuv.z;

				float attenuation = LIGHT_ATTENUATION(i);
				float ndotl = max(0, dot(i.normal, _WorldSpaceLightPos0) * attenuation);

				float4 color = lerp(_ShadowColor * tex2D(_MainTex, i.uv), tex2D(_MainTex, i.uv), floor(ndotl * _Levels) / _Levels);
				color.w = 1;

				return color;
			}
			ENDCG
		}
	}
	Fallback "Standard"
}
