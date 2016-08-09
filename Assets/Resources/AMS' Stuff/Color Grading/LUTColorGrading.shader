Shader "Hidden/LUTColorGrading"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
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

			uniform sampler3D _LUT;
			uniform float _Scale;
			uniform float _Offset;

			float4 frag(v2f_img i) : COLOR
			{
				float3 originalColor = tex2D(_MainTex, i.uv).rgb;
				float4 gradedColor = float4(tex3D(_LUT, originalColor.rgb * _Scale + _Offset).rgb, 1.0);

				return gradedColor;
			}
			ENDCG
		}
	}
}
