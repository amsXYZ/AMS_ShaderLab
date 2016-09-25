Shader "Hidden/SobelDepth"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	///////////////////////////////////////
	// Sobel Depth Edge Detection Shader //
	///////////////////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Edge Detection
		Pass
		{
			Name "EDGE_DETECTION"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform half2 _Sensitivity;
			uniform float4 _EdgeColor;
			uniform float _EdgeWidth;
			uniform int _Debug;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraDepthNormalsTexture;

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			// This function takes care of the sampling of both the depth and normal textures.
			void SampleDepthNormal(float2 uv, out float3 normal, out float depth)
			{
				float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = LinearEyeDepth(d) + CheckBounds(uv, d);

				float4 cdn = tex2D(_CameraDepthNormalsTexture, uv);
				normal = DecodeViewNormalStereo(cdn) * float3(1, 1, -1);
			}

			half CheckEdge(float3 centerNormal, float centerDepth, float3 sampleNormal, float sampleDepth)
			{
				// The comparison values here have been set up based on manually tweaking them.
				// Feel free to change them, however, you can also effectively modify them by changing the sensitivity settings.
				float3 diff = abs(centerNormal - sampleNormal) * _Sensitivity.y;
				int isSameNormal = (diff.x + diff.y + diff.z) * _Sensitivity.y < 2;

				float zdiff = abs(centerDepth - sampleDepth);
				int isSameDepth = zdiff * _Sensitivity.x < 0.09 * centerDepth;

				// return:
				// 1 - if normals and depth are similar enough
				// 0 - otherwise

				return isSameNormal * isSameDepth ? 1.0 : 0.0;
			}

			float4 frag(v2f_img i) : COLOR
			{
				// Grab the original screen color.
				float4 original = tex2D(_MainTex, i.uv);

				// Flip the sampling uvs if necessary.
				float2 sampleCenterUV = i.uv;
				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0.0) sampleCenterUV.y = 1.0 - sampleCenterUV.y;
				#endif

				// Sample the depth and normal of the center pixel and the four corners.
				float3 centerNormal, sample0Normal, sample1Normal, sample2Normal, sample3Normal;
				float centerDepth, sample0Depth, sample1Depth, sample2Depth, sample3Depth;

				SampleDepthNormal(sampleCenterUV, centerNormal, centerDepth);
				SampleDepthNormal(clamp(sampleCenterUV + float2(-_EdgeWidth, -_EdgeWidth) * _MainTex_TexelSize.xy, 0, 1), sample0Normal, sample0Depth);
				SampleDepthNormal(clamp(sampleCenterUV + float2(-_EdgeWidth, +_EdgeWidth) * _MainTex_TexelSize.xy, 0, 1), sample1Normal, sample1Depth);
				SampleDepthNormal(clamp(sampleCenterUV + float2(+_EdgeWidth, -_EdgeWidth) * _MainTex_TexelSize.xy, 0, 1), sample2Normal, sample2Depth);
				SampleDepthNormal(clamp(sampleCenterUV + float2(+_EdgeWidth, +_EdgeWidth) * _MainTex_TexelSize.xy, 0, 1), sample3Normal, sample3Depth);

				// Check if the center pixel is an edge.
				half edge = 1.0;
				edge *= CheckEdge(centerNormal, centerDepth, sample0Normal, sample0Depth);
				edge *= CheckEdge(centerNormal, centerDepth, sample1Normal, sample1Depth);
				edge *= CheckEdge(centerNormal, centerDepth, sample2Normal, sample2Depth);
				edge *= CheckEdge(centerNormal, centerDepth, sample3Normal, sample3Depth);

				// Return the final composite color.
				return _Debug * edge + (1-_Debug) * lerp(lerp(original,_EdgeColor,_EdgeColor.w), original, edge);
			}
			ENDCG
		}
	}
}
