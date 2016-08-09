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

		//#0: Oil Painting
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform sampler2D _NoiseTex;

			uniform int _Radius;
			uniform float _Distance;
			uniform int _Intensity;
			uniform float _NoiseStrength;

			sampler2D_float _CameraDepthTexture;

			struct pixelIntensity {
				int count;
				float3 sum;
			};

			v2f_img vert(appdata_img i) {
				v2f_img o;
				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
				o.uv = i.texcoord;
				return o;
			}

			float4 frag(v2f_img i) : SV_TARGET
			{
				float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
				depth = 1 - (-1 * (sqrt(1 - (depth - 1) * (depth - 1)) - 1));

				float uvDisp = tex2D(_NoiseTex, float2(i.uv.x + sin(_Time.z + sin(_Time.x)) / 50, i.uv.y + _Time.x - sin(_Time.w + sin(_Time.w)) /100 * 0.5 + 0.5)).r * _NoiseStrength * (1 - depth);;

				i.uv += uvDisp;

				float4 color = float4(0,0,0,1);

				pixelIntensity pixels[30];

				pixels[0].count = 0;
				pixels[0].sum = float3(0,0,0);
				pixels[1].count = 0;
				pixels[1].sum = float3(0, 0, 0);
				pixels[2].count = 0;
				pixels[2].sum = float3(0, 0, 0);
				pixels[3].count = 0;
				pixels[3].sum = float3(0, 0, 0);
				pixels[4].count = 0;
				pixels[4].sum = float3(0, 0, 0);
				pixels[5].count = 0;
				pixels[5].sum = float3(0, 0, 0);
				pixels[6].count = 0;
				pixels[6].sum = float3(0, 0, 0);
				pixels[7].count = 0;
				pixels[7].sum = float3(0, 0, 0);
				pixels[8].count = 0;
				pixels[8].sum = float3(0, 0, 0);
				pixels[9].count = 0;
				pixels[9].sum = float3(0, 0, 0);
				pixels[10].count = 0;
				pixels[10].sum = float3(0, 0, 0);
				pixels[11].count = 0;
				pixels[11].sum = float3(0, 0, 0);
				pixels[12].count = 0;
				pixels[12].sum = float3(0, 0, 0);
				pixels[13].count = 0;
				pixels[13].sum = float3(0, 0, 0);
				pixels[14].count = 0;
				pixels[14].sum = float3(0, 0, 0);
				pixels[15].count = 0;
				pixels[15].sum = float3(0, 0, 0);
				pixels[16].count = 0;
				pixels[16].sum = float3(0, 0, 0);
				pixels[17].count = 0;
				pixels[17].sum = float3(0, 0, 0);
				pixels[18].count = 0;
				pixels[18].sum = float3(0, 0, 0);
				pixels[19].count = 0;
				pixels[19].sum = float3(0, 0, 0);
				pixels[20].count = 0;
				pixels[20].sum = float3(0, 0, 0);
				pixels[21].count = 0;
				pixels[21].sum = float3(0, 0, 0);
				pixels[22].count = 0;
				pixels[22].sum = float3(0, 0, 0);
				pixels[23].count = 0;
				pixels[23].sum = float3(0, 0, 0);
				pixels[24].count = 0;
				pixels[24].sum = float3(0, 0, 0);
				pixels[25].count = 0;
				pixels[25].sum = float3(0, 0, 0);
				pixels[26].count = 0;
				pixels[26].sum = float3(0, 0, 0);
				pixels[27].count = 0;
				pixels[27].sum = float3(0, 0, 0);
				pixels[28].count = 0;
				pixels[28].sum = float3(0, 0, 0);
				pixels[29].count = 0;
				pixels[29].sum = float3(0, 0, 0);

				for (int y = -_Radius; y <= _Radius; y++)
				{
					for (int x = -_Radius; x <= _Radius; x++) {

						float2 texCoords = float2(i.uv.x + x * _MainTex_TexelSize.x * (1-depth) * _Distance, i.uv.y + y * _MainTex_TexelSize.y * (1-depth) * _Distance);

						float3 pixelColor = tex2D(_MainTex, texCoords).rgb;

						int intensity = floor((pixelColor.r + pixelColor.g + pixelColor.b)/3 * _Intensity);
						intensity = clamp(intensity, 0, _Intensity - 1);
						pixels[intensity].count++;
						pixels[intensity].sum += pixelColor;
					}
				}

				int currMax = 0;
				int maxIndex = 0;
				for (uint i = 0; i < 30; i++)
				{
					if (pixels[i].count > currMax) {
						currMax = pixels[i].count;
						maxIndex = i;
					}
				}

				return float4(pixels[maxIndex].sum / currMax, 1);
			}
			ENDCG
		}

		//#1: Normal Map generation and lighting
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;

			v2f_img vert(appdata_img i) {
				v2f_img o;
				o.pos = mul(UNITY_MATRIX_MVP, float4(i.texcoord * float2(2, -2) + float2(-1, 1), 0, 1));
				o.uv = i.texcoord;
				return o;
			}

			float4 frag(v2f_img i) : SV_TARGET
			{
				float4 color = tex2D(_MainTex, i.uv);
				float lum = Luminance(color);

				float3 d1 = ddx(i.pos);
				float3 d2 = ddy(i.pos);
				float3 normal = normalize(cross(d1, d2));

				return float4(normal.xy * 0.5 + 0.5,1,1);

				return lum;
			}
			ENDCG
		}
	}
}
