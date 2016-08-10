Shader "Hidden/LowPassFilterAO"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		//LOW PASS FILTER FOR THE AO
		Pass
		{	
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform sampler2D _AOTexture;
			uniform float4 _AOTexture_TexelSize;
			uniform sampler2D _NormalTexture;
			uniform sampler2D _PosTexture;

			// Reconstruct view-space position from UV and depth.
			// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
			// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
			float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
			{
				return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
			}

			float3 SamplePosition(sampler2D posTex, float2 sampleUV) {
				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				return tex2D(posTex, sampleUV) - ReconstructViewPos(float2(0, 0), _ScreenParams.z, p11_22, p13_31);
			}

			float4 frag (v2f_img input) : SV_Target
			{
				float3 centerNorm = tex2D(_NormalTexture, input.uv);
				float centerDepth = SamplePosition(_PosTexture, input.uv).z;

				float3 blur;
				float weight;

				for (float i = -1.0; i <= 1.0; i += 1.0)
				{
					for (float j = -1.0; j <= 1.0; j += 1.0)
					{
						float2 sampleUV = input.uv + float2(i, j) * _AOTexture_TexelSize;

						float3 sampleAO = tex2D(_AOTexture, sampleUV);
						float3 sampleNorm = tex2D(_NormalTexture, sampleUV);
						float sampleDepth = SamplePosition(_PosTexture, sampleUV).z;

						float normalWeight = (dot(sampleNorm, centerNorm) + 1.2) / 2.2;
						normalWeight = pow(normalWeight, 8.0);

						float depthWeight = 1.0 / (1.0 + abs(centerDepth - sampleDepth) * 0.2);
						depthWeight = pow(depthWeight, 16.0);

						float gaussianWeight = 1.0 / ((abs(i) + 1.0) * (abs(j) + 1.0));

						weight += normalWeight * depthWeight * gaussianWeight;
						blur += sampleAO * normalWeight * depthWeight * gaussianWeight;
					}
				}

				return float4(blur / weight, 1);
			}
			ENDCG
		}
	}
}
