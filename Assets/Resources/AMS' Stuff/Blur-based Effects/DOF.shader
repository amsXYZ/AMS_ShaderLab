Shader "Hidden/DOF"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_FocusDepth("FocusDepth", Float) = 0
	}

	// Inspired by Nvidia's GPU Gems' 3 article: Practical Post-Process Depth of Field (and Unity's own implementation)
	// http://webstaff.itn.liu.se/~stegu/webglshadertutorial/shadertutorial.html

	///////////////////////////
	// Depth of Field Shader //
	///////////////////////////

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
		
		// 0 : CoC
		Pass
		{
			Name "COC"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment fragCoC

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "DOFCG.cginc"
			
			ENDCG
		}

		// 1 : Back CoC
		Pass
		{
			Name "BACK_COC"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment fragBackCoC

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "DOFCG.cginc"

			ENDCG
		}

		// 2 : Front CoC
		Pass
		{
			Name "FRONT_COC"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment fragFrontCoC

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "DOFCG.cginc"
			
			ENDCG
		}

		// 3 : Downsample
		Pass
		{
			Name "DOWNSAMPLE"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment fragDownsample

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "DOFCG.cginc"

			ENDCG
		}

		// 4 : Blur
		Pass
		{
			Name "BLUR"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment fragBlur

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "DOFCG.cginc"
			
			ENDCG
		}

		// 5 : Final composition
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment fragFinal

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "DOFCG.cginc"
			
			ENDCG
		}
	}
}
