Shader "Hidden/SobelDepth"
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
			uniform half4 _Sensitivity;
			uniform float4 _EdgeColor;

			uniform int _Debug;

			sampler2D _CameraDepthNormalsTexture;
			sampler2D_float _CameraDepthTexture;

			int kernelSize = 3;

			inline half CheckSame(half2 centerNormal, float centerDepth, half4 theSample)
			{
				// difference in normals
				// do not bother decoding normals - there's no need here
				half2 diff = abs(centerNormal - theSample.xy) * _Sensitivity.y;
				//0.1
				int isSameNormal = (diff.x + diff.y) * _Sensitivity.y < 0.24;
				// difference in depth
				float sampleDepth = DecodeFloatRG(theSample.zw);
				float zdiff = abs(centerDepth - sampleDepth);
				// scale the required threshold by the distance
				//0.09
				int isSameDepth = zdiff * _Sensitivity.x < 0.059 * centerDepth;

				// return:
				// 1 - if normals and depth are similar enough
				// 0 - otherwise

				return isSameNormal * isSameDepth ? 1.0 : 0.0;
			}

			float4 frag(v2f_img i) : COLOR
			{
				float2 texUV = i.uv;

				/*#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0.0) texUV.y = 1.0 - texUV.y;
				#endif*/

				half4 original = tex2D(_MainTex, i.uv);

				half4 center = tex2D(_CameraDepthNormalsTexture, i.uv);

				// encoded normal
				half2 centerNormal = center.xy;
				// decoded depth
				float centerDepth = DecodeFloatRG(center.zw);

				half4 sampTL = tex2D(_CameraDepthNormalsTexture, float2(i.uv.x - 1 * _MainTex_TexelSize.x, i.uv.y - 1 * _MainTex_TexelSize.y));
				half4 sampTR = tex2D(_CameraDepthNormalsTexture, float2(i.uv.x + 1 * _MainTex_TexelSize.x, i.uv.y - 1 * _MainTex_TexelSize.y));
				half4 sampBL = tex2D(_CameraDepthNormalsTexture, float2(i.uv.x - 1 * _MainTex_TexelSize.x, i.uv.y + 1 * _MainTex_TexelSize.y));
				half4 sampBR = tex2D(_CameraDepthNormalsTexture, float2(i.uv.x + 1 * _MainTex_TexelSize.x, i.uv.y + 1 * _MainTex_TexelSize.y));

				half edge = 1.0;
				edge *= CheckSame(centerNormal, centerDepth, sampTL);
				edge *= CheckSame(centerNormal, centerDepth, sampTR);
				edge *= CheckSame(centerNormal, centerDepth, sampBL);
				edge *= CheckSame(centerNormal, centerDepth, sampBR);

				return _Debug * edge + (1-_Debug) * lerp(lerp(original,_EdgeColor,_EdgeColor.w), original, edge);
			}
			ENDCG
		}
	}
}
