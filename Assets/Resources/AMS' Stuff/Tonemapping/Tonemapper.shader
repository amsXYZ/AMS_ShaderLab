Shader "Hidden/Tonemapper"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_FilmLut("Film LUT", 2D) = "white" {}
	}

	// The majority of the techniques applied in this shader are based on this post
	// by John Hable : http://filmicgames.com/archives/75

	////////////////////////
	// Tonemapping Shader //
	////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Photographic
		Pass
		{
			Name "PHOTOGRAPHIC"	

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0
			
			#include "UnityCG.cginc"
			
			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag (v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;
				//gamma correction
				//float3 retColor = pow(col, 1 / 2.2);
				return 1 - exp2(-col);
			}
			ENDCG
		}

		// 1 : Reinhard
		Pass
		{
			Name "REINHARD"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;
				col = col / (1 + col);
				//gamma correction
				//float3 retColor = pow(col, 1 / 2.2);
				return col;
			}
			ENDCG
		}

		// 2 : H.P.Duiker
		Pass
		{
			Name "HPDUIKER"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;
			uniform sampler2D _FilmLut;

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
				retColor.r = tex2D(_FilmLut, float2(lerp(Padding, 1 - Padding, LogColor.r), .5)).r;
				retColor.g = tex2D(_FilmLut, float2(lerp(Padding, 1 - Padding, LogColor.g), .5)).r;
				retColor.b = tex2D(_FilmLut, float2(lerp(Padding, 1 - Padding, LogColor.b), .5)).r;

				return float4(retColor, 1);
			}
			ENDCG
		}

		// 3 : Hejl-Dawson
		Pass
		{
			Name "HEJL_DAWSON"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _Exposure;

			float4 frag(v2f_img i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				col.rgb *= _Exposure;
				float3 x = max(0, col - 0.004);
				float3 retColor = (x*(6.2*x + .5)) / (x*(6.2*x + 1.7) + 0.06);
				return float4(retColor*retColor, 1);
			}
			ENDCG
		}

		// 4 : John Hable
		Pass{
			Name "HABLE"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

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

				//gamma correction
				//float3 retColor = pow(color, 1 / 2.2);
				return float4(color, 1);
			}
			ENDCG
		}

		// Based on: https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
		// 5 : Academy Color Encoding System
		Pass
		{
			Name "ACES"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

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

				//gamma correction
				//float4 retColor = pow(col, 1 / 2.2);
				return saturate((col * (a * col + b)) / (col * (c * col + d) + e));
			}
			ENDCG
		}
	}
}
