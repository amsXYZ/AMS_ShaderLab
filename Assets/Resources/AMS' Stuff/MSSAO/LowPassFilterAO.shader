Shader "Hidden/LowPassFilterAO"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	//////////////////////////////////////////
	// low pass filter for the MSSAO effect //
	//////////////////////////////////////////

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Low Pass Filter
		Pass
		{	
			Name "LOWPASSFILTER"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "MSSAOCG.cginc"

			uniform sampler2D _AOTexture;
			uniform float4 _AOTexture_TexelSize;
			uniform sampler2D _NormalTexture;
			uniform sampler2D _PosTexture;

			float4 frag (v2f_img input) : SV_Target
			{
				float3 centerNorm = tex2D(_NormalTexture, input.uv);
				float centerDepth = SamplePosition(_PosTexture, input.uv).z;

				float3 blur;
				float weight;

				// Perform small 3x3 kernel weighted blur affeccted by the normals, depth and gaussian weight of the samples.

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
