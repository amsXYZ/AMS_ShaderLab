Shader "Hidden/Bloom"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	////////////////////////////////////////////////
	// Basic Bloom Shader using Unity's BlitMultiTap
	////////////////////////////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Threshold substraction
		Pass
		{	
			Name "THRESHOLD_SUBSTRACTION"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _BloomThreshold;

			float4 frag(v2f_img i) : COLOR
			{
				// Sample the colors and substract the threshold.
				float4 color = tex2D(_MainTex, i.uv) - _BloomThreshold;

				// Clamp the negative values to 0.
				color.x = max(0, color.x);
				color.y = max(0, color.y);
				color.z = max(0, color.z);
				color.w = 1;

				return color;
			}
			ENDCG
		}

		// 1 : Final composition
		Pass
		{
			Name "FINAL_COMPOSITION"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform sampler2D _OriginalTex;
			uniform float4 _OriginalTex_TexelSize;

			uniform float _BloomIntensity;

			float4 frag(v2f_img i) : COLOR
			{
				float4 color = tex2D(_MainTex, i.uv);

				half2 originalTexUV = i.uv;
				// Flip the original texture's UV if they are flipped (it can happen sometimes).
				#if UNITY_UV_STARTS_AT_TOP
					if (_OriginalTex_TexelSize.y < 0.0) originalTexUV.y = 1.0 - originalTexUV.y;
				#endif

				// Multiply the bloom by the original pixels' colors.
				return _BloomIntensity * color + tex2D(_OriginalTex, originalTexUV);
			}
			ENDCG
		}
	}
}
