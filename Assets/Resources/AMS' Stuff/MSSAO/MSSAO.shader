Shader "Hidden/MSSAO"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	////////////////////////////////////////////////////////
	// Multi-scale Screen Space Ambient Occlusion (MSSAO) //
	////////////////////////////////////////////////////////

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Normal texture computation
		Pass
		{	
			Name "NORMAL"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragNorm

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"

			ENDCG
		}

		// 1 : World position texture computation
		Pass
		{	
			Name "POS"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragPos

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"
			
			ENDCG
		}

		// 2 : AO - First Pass
		Pass
		{
			Name "AOFIRST"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragAOFirst

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"

			ENDCG
		}

		// 3 : AO - Intermedium passes
		Pass
		{
			Name "AO"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragAO

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"
			
			ENDCG
		}

		// 4 : AO - Last passes
		Pass
		{
			Name "AOLAST"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragAOLast

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"
			
			ENDCG
		}

		// 5 : Final composition
		Pass
		{
			Name "FINAL"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform sampler2D _AOFinal;

			uniform int _singleAO;
			uniform int _Debug;
			uniform float _Intensity;

			float4 frag(v2f_img i) : COLOR
			{
				float4 color = tex2D(_MainTex, i.uv);
				if (_Debug) color = float4(1, 1, 1, 1);

				half2 aoUV = i.uv;
				// Flip the original texture's UV if they are flipped (it can happen sometimes).
				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0.0) aoUV.y = 1.0 - aoUV.y;
				#endif

				float4 ao;
				if (_singleAO) {
					ao = 1 - tex2D(_AOFinal, aoUV).x;
				}
				else ao = tex2D(_AOFinal, aoUV).x;
				
				return color * pow(ao, _Intensity);
			}
			ENDCG
		}
	}
}
