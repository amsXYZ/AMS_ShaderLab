Shader "Hidden/Blur"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	//////////////////////////////////////////////////
	// Basic Blur Shader using Unity's BlitMultiTap //
	//////////////////////////////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Blur
		Pass
		{
			Name "BLUR"

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform half4 _BlurOffsets;

			//Vert shader struct.
			struct v2f_blur {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half2 samples[4] : TEXCOORD1;
			};

			v2f_blur vert(appdata_img i) {
				v2f_blur o;
				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
				o.uv = i.texcoord - _BlurOffsets.xy * _MainTex_TexelSize.xy; //Offset the uv's to maintain pixel positions on screen when downsampling.

				//Calculate the samples' uv coordinates.
				o.samples[0] = o.uv + _MainTex_TexelSize * _BlurOffsets.xy;
				o.samples[1] = o.uv - _MainTex_TexelSize * _BlurOffsets.xy;
				o.samples[2] = o.uv + _MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1);
				o.samples[3] = o.uv - _MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1);

				return o;
			}

			float4 frag(v2f_blur i) : COLOR
			{
				//Sample the four pixel that we'll use to blur the image.
				float4 color = tex2D(_MainTex, i.samples[0]);
				color += tex2D(_MainTex, i.samples[1]);
				color += tex2D(_MainTex, i.samples[2]);
				color += tex2D(_MainTex, i.samples[3]);

				//Normalize colors.
				return color * 0.25;
			}
			ENDCG
		}
	}
}
