Shader "Hidden/ColorGrading"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	//////////////////////////
	// Color Grading Shader //
	//////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Standard
		Pass
		{
			Name "STANDARD"
			
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "ColorGradingCG.cginc"
			
			ENDCG
		}
		
		// 1 : Debug
		Pass
		{
			Name "DEBUG"
			
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag_debug

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "ColorGradingCG.cginc"
			
			ENDCG
		}
	}
}
