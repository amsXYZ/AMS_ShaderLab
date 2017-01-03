Shader "Hidden/OilPainting"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		/////////////////////////
		// Oil Painting Shader //
		/////////////////////////

		// 0 : Oil Painting
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform int _SamplingKernelWidth;
			uniform float _Distance;
			uniform int _ColorIntensities;

			sampler2D _CameraDepthTexture;

			// Struct used to store how many times a color intensity is repeated.
			struct pixelIntensity {
				int count;
				float3 sum;
			};

			// Struct initialization.
			pixelIntensity PixelIntensity(int c, float3 s) {
				pixelIntensity p;
				p.count = c;
				p.sum = s;
				return p;
			}

			float4 frag(v2f_img i) : SV_TARGET
			{
				// Sample the pixel depth
				float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));

				// Declare and initialize all the color intensities we'll check.
				pixelIntensity pixels[30];
				pixels[0] = pixels[1] = pixels[2] = pixels[3] = pixels[4] = pixels[5] = pixels[6] = pixels[7] = pixels[8] = pixels[9] = pixels[10] = pixels[11] = pixels[12] = pixels[13] = pixels[14] = pixels[15] =
					pixels[16] = pixels[17] = pixels[18] = pixels[19] = pixels[20] = pixels[21] = pixels[22] = pixels[23] = pixels[24] = pixels[25] = pixels[26] = pixels[27] = pixels[28] = pixels[29] = PixelIntensity(0, float3(0, 0, 0));

				for (float y = -_SamplingKernelWidth/2; y <= _SamplingKernelWidth/2; y++)
				{
					for (float x = -_SamplingKernelWidth/2; x <= _SamplingKernelWidth/2; x++) {

						// Calculate the sampling UV coordinates.
						float2 samplingUV = i.uv + float2(x, y) * _MainTex_TexelSize * (1 - depth) * _Distance;

						// Sample the color
						float3 pixelColor = tex2D(_MainTex, samplingUV).rgb;

						// Calculate the color's intensity and update its struct values.
						int intensity = floor((pixelColor.r + pixelColor.g + pixelColor.b)/3 * _ColorIntensities);
						intensity = clamp(intensity, 0, _ColorIntensities - 1);
						pixels[intensity].sum += pixelColor;
						pixels[intensity].count++;
					}
				}

				// Look for the predominant color intensity
				int currMax = 0;
				int maxIndex = 0;
				for (uint j = 0; j < 30; j++)
				{
					if (pixels[j].count > currMax) {
						currMax = pixels[j].count;
						maxIndex = j;
					}
				}

				// Output it
				return float4(pixels[maxIndex].sum / currMax, 1);
			}
			ENDCG
		}
	}
}
