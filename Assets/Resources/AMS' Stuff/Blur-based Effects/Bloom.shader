Shader "Hidden/Bloom"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_OriginalTex("Original Texture", 2D) = "white" {}
		_BloomThreshold("Bloom Threshold", Float) = 0
		_BloomIntensity("Bloom Intensity", Float) = 1
	}

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{	
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _BloomThreshold;
			uniform float _BloomIntensity;

			float4 frag(v2f_img i) : COLOR
			{
				half4 color = tex2D(_MainTex, i.uv) - _BloomThreshold;

				return color;
			}
			ENDCG
		}

		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform sampler2D _OriginalTex;

			uniform float _BloomThreshold;
			uniform float _BloomIntensity;

			float4 frag(v2f_img i) : COLOR
			{
				half4 color = tex2D(_MainTex, i.uv);

				return _BloomIntensity * color + tex2D(_OriginalTex, i.uv);
			}
			ENDCG
		}
	}
}
