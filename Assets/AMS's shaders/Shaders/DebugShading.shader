Shader "Hidden/DebugShading"
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

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;

			sampler2D_float _CameraDepthTexture;

			float4 frag(v2f_img i) : COLOR
			{
				float4 c = tex2D(_MainTex, i.uv);

				return c.w;
			}
			ENDCG
		}
	}
}