Shader "Hidden/Blur"
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
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform half4 _BlurOffsets;

			sampler2D_float _CameraDepthTexture;

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half2 taps[4] : TEXCOORD1;
			};

			v2f vert(appdata_img i) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
				o.uv = i.texcoord - _BlurOffsets.xy * _MainTex_TexelSize.xy;
				o.taps[0] = o.uv + _MainTex_TexelSize * _BlurOffsets.xy;
				o.taps[1] = o.uv - _MainTex_TexelSize * _BlurOffsets.xy;
				o.taps[2] = o.uv + _MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1);
				o.taps[3] = o.uv - _MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				/*float4 blurA = float4(0,0,0,1);

				int kernelASize = _kernelAWidth + (1 - fmod(_kernelAWidth, 2));

				for (int y = -(kernelASize - 1) / 2; y <= (kernelASize - 1) / 2; y++)
				{
					for (int x = -(kernelASize - 1) / 2; x <= (kernelASize - 1) / 2; x++) {

						float2 texCoords = float2(i.uv.x + x * _MainTex_TexelSize.x, i.uv.y + y * _MainTex_TexelSize.y);
						blurA += Gauss(length(texCoords - i.uv), SIGMA) * tex2D(_MainTex, texCoords);
					}
				}

				return blurA;*/

				half4 color = tex2D(_MainTex, i.taps[0]);
				color += tex2D(_MainTex, i.taps[1]);
				color += tex2D(_MainTex, i.taps[2]);
				color += tex2D(_MainTex, i.taps[3]);

				return color * 0.25;
			}
			ENDCG
		}
	}
}
