Shader "Hidden/DOF"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_FocusDepth("FocusDepth", Float) = 0
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

			uniform float _FocusDepth;
			uniform float _FocalSize;
			uniform float _Aperture;
			uniform int _Debug;

			sampler2D_float _CameraDepthTexture;

			float4 frag(v2f_img i) : COLOR
			{
				float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
				float coc = _Aperture * abs(fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
				coc = clamp(max(0, coc - _FocalSize),0,1);

				return float4(tex2D(_MainTex, i.uv).xyz,coc);
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _FocusDepth;
			uniform float _FocalSize;
			uniform float _Aperture;
			uniform int _Debug;

			sampler2D_float _CameraDepthTexture;

			float4 frag(v2f_img i) : COLOR
			{
				float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
				float coc = _Aperture * (fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
				coc = clamp(max(0, coc - _FocalSize),0,1);

				return float4(tex2D(_MainTex, i.uv).xyz,coc);
			}
			ENDCG
		}

		// FrontCOC
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _FocusDepth;
			uniform float _FocalSize;
			uniform float _Aperture;
			uniform int _Debug;

			sampler2D_float _CameraDepthTexture;

			float4 frag(v2f_img i) : COLOR
			{
				float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
				float coc = -_Aperture * (fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
				coc = clamp(max(0, coc - _FocalSize),0,1);

				return float4(tex2D(_MainTex, i.uv).xyz,coc);
			}
			ENDCG
		}

		// Upsample
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			#define SCATTER_OVERLAP_SMOOTH (-0.265)

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform sampler2D _downsampledBlurredB;
			uniform sampler2D _downsampledBlurredF;

			uniform float _MaxBlurDistance;

			float4 frag(v2f_img i) : COLOR
			{
				float4 centerTap = tex2D(_MainTex, i.uv.xy);

				float4 bigBlurB = tex2D(_downsampledBlurredB, i.uv.xy);
				float4 backBlurred = lerp(centerTap, bigBlurB, (bigBlurB.a + centerTap.a)/2);

				//return (bigBlurB.a + centerTap.a) / 2;

				float4 bigBlurF = tex2D(_downsampledBlurredF, i.uv.xy);
				float4 frontBlurred = lerp(backBlurred, bigBlurF, bigBlurF.a);

				return frontBlurred;

				//return lerp(centerTap, bigBlur, (bigBlur.a + centerTap.a)/2);

				float4 smallBlur = centerTap;
				float4 poissonScale = _MainTex_TexelSize.xyxy * centerTap.a;//* MAX BLUR DISTANCE

				float sampleCount = max(centerTap.a * 0.25, 0.1f); // <- weighing with 0.25 looks nicer for small high freq spec
				//smallBlur *= sampleCount;

				float4 sample0 = tex2D(_MainTex, i.uv.xy + float2(1, 1) * poissonScale);
				float4 sample1 = tex2D(_MainTex, i.uv.xy + float2(1, -1) * poissonScale);
				float4 sample2 = tex2D(_MainTex, i.uv.xy + float2(-1, 1) * poissonScale);
				float4 sample3 = tex2D(_MainTex, i.uv.xy + float2(-1, -1) * poissonScale);

				float4 weight0 = smoothstep(SCATTER_OVERLAP_SMOOTH, 0.0, sample0.a - centerTap.a * sqrt(2) * poissonScale);
				float4 weight1 = smoothstep(SCATTER_OVERLAP_SMOOTH, 0.0, sample1.a - centerTap.a * sqrt(2) * poissonScale);
				float4 weight2 = smoothstep(SCATTER_OVERLAP_SMOOTH, 0.0, sample2.a - centerTap.a * sqrt(2) * poissonScale);
				float4 weight3 = smoothstep(SCATTER_OVERLAP_SMOOTH, 0.0, sample3.a - centerTap.a * sqrt(2) * poissonScale);

				//smallBlur += sample0 * weight0 + sample1 * weight1 + sample2 * weight2 + sample3 * weight3;
				sampleCount += weight0 + weight1 + weight2 + weight3;

				//smallBlur /= (sampleCount + 1e-5f);
				float blend = smoothstep(0.65, 0.85, centerTap.a);
				//float4 finalColor = lerp(smallBlur, bigBlur, blend);

				//return centerTap.a < 1e-2f ? centerTap : float4(finalColor.rgb,centerTap.a);
			}
			ENDCG
		}

		// 2 : Downsample
		Pass
		{
			Name "BLUR"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			float4 frag(v2f_img i) : COLOR
			{
				float4 sample0 = tex2D(_MainTex, i.uv.xy + 0.75 * _MainTex_TexelSize.xy);
				float4 sample1 = tex2D(_MainTex, i.uv.xy - 0.75 * _MainTex_TexelSize.xy);
				float4 sample2 = tex2D(_MainTex, i.uv.xy + 0.75 * _MainTex_TexelSize.xy * float2(1,-1));
				float4 sample3 = tex2D(_MainTex, i.uv.xy - 0.75 * _MainTex_TexelSize.xy * float2(1,-1));

				float4 weights = saturate(10.0 * float4(sample0.a, sample1.a, sample2.a, sample3.a));
				float sumWeights = dot(weights, 1);

				float4 color = (sample0*weights.x + sample1*weights.y + sample2*weights.z + sample3*weights.w);

				float4 outColor = tex2D(_MainTex, i.uv);
				if (outColor.a * sumWeights * 8.0 > 1e-5f) outColor.rgb = color.rgb / sumWeights;

				return outColor;
			}
			ENDCG
		}

		// 3 : Blur
		Pass
		{
			Name "BLUR"

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _MaxBlurDistance;

			uniform float _PoissonDisks[32];

			float4 frag(v2f_img i) : COLOR
			{
				float4 color = tex2D(_MainTex, i.uv);
				float weights = 1.0;

				[unroll(16)]
				for (float x = 0; x < 32; x += 2)
				{
					float2 sampleUV = i.uv + float2(_PoissonDisks[x], _PoissonDisks[x + 1]) * _MainTex_TexelSize.xy * _MaxBlurDistance;
					float4 value = tex2D(_MainTex, sampleUV);
					color += value * value.a;
					weights += value.a;
				}

				color = color / weights;
				return color;
			}
			ENDCG
		}
	}
}
