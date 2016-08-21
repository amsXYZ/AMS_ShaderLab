Shader "Hidden/DebugShading"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
	
	//////////////////////////////
	// Comic Shadows' Debug Shader
	//////////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Debug
		Pass
		{
			Name "DEBUG"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;

			//Just output the pixels' alpha shadows.
			float4 frag(v2f_img i) : COLOR
			{
				return tex2D(_MainTex, i.uv).w;
			}
			ENDCG
		}
	}
}