Shader "Hidden/Tonemapper"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		//LINEAR TONEMAPPING
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag (v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;
				float3 retColor = pow(col, 1 / 2.2);
				return float4(retColor, 1);
			}
			ENDCG
		}

		//REINHARD TONEMAPPING
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;
				col = col / (1 + col);
				float3 retColor = pow(col, 1 / 2.2);
				return float4(retColor, 1);
			}
			ENDCG
		}

		//HPDUIKER TONEMAPPING
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;
			uniform sampler2D FilmLut;

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;

				float3 ld = 0.002;
				float linReference = 0.18;
				float logReference = 444;
				float logGamma = 0.45;

				float3 LogColor;
				LogColor = (log10(0.4*col.rgb / linReference) / ld*logGamma + logReference) / 1023.f;
				LogColor.rgb = saturate(LogColor.rgb);

				float FilmLutWidth = 256;
				float Padding = .5 / FilmLutWidth;

				float3 retColor;
				retColor.r = tex2D(FilmLut, float2(lerp(Padding, 1 - Padding, LogColor.r), .5)).r;
				retColor.g = tex2D(FilmLut, float2(lerp(Padding, 1 - Padding, LogColor.g), .5)).r;
				retColor.b = tex2D(FilmLut, float2(lerp(Padding, 1 - Padding, LogColor.b), .5)).r;

				return float4(retColor, 1);
			}
			ENDCG
		}

		//HEJL_DAWSON TONEMAPPING
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;
				float3 x = max(0, col - 0.004);
				float3 retColor = (x*(6.2*x + .5)) / (x*(6.2*x + 1.7) + 0.06);
				return float4(retColor, 1);
			}
			ENDCG
		}

		//HABLE TONEMAPPING
		Pass{

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float3 HableTonemap(float3 x) {
				float A = 0.15;
				float B = 0.50;
				float C = 0.10;
				float D = 0.20;
				float E = 0.02;
				float F = 0.30;
				float W = 11.2;

				return ((x*(A*x + C*B) + D*E) / (x*(A*x + B) + D*F)) - E / F;
			}

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;

				float ExposureBias = 2.0f;
				float3 curr = HableTonemap(ExposureBias*col);

				float W = 11.2;

				float3 whiteScale = 1.0f / HableTonemap(W);
				float3 color = curr*whiteScale;

				float3 retColor = pow(color, 1 / 2.2);
				return float4(retColor, 1);
			}
			ENDCG
		}

		//ACES TONEMAPPING
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;

				float a = 2.51;
				float b = 0.03;
				float c = 2.43;
				float d = 0.59;
				float e = 0.14;

				float4 retColor = pow(col, 1 / 2.2);
				return saturate((retColor * (a * retColor + b)) / (retColor * (c * retColor + d) + e));
			}
			ENDCG
		}
	}
}
