Shader "Hidden/MSSAO"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		//DOWNSAMPLING NORMAL
		Pass
		{	
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragNorm

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"

			ENDCG
		}

		//DOWNSAMPLING POS
		Pass
		{	
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragPos

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"
			
			ENDCG
		}

		//COMPUTE AO - FIRST PASS
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragAOFirst

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"

			ENDCG
		}

		//COMPUTE AO - INTERMEDIUM PASSES
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragAO

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"
			
			ENDCG
		}

		//COMPUTE AO - LAST PASS
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment fragAOLast

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"
			
			ENDCG
		}

		//COMPOSITING
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _AOFinal;

			uniform int _singleAO;
			uniform int _Debug;
			uniform float _Intensity;

			float4 frag(v2f_img i) : COLOR
			{
				float4 ao;
				if (_singleAO) {
					ao = 1 - tex2D(_AOFinal, i.uv).x;
				}
				else ao = tex2D(_AOFinal, i.uv).x;

				float4 color = tex2D(_MainTex, i.uv);
				if (_Debug) color = float4(1, 1, 1, 1);
				
				return color * pow(ao, _Intensity);
			}
			ENDCG
		}
	}
}
