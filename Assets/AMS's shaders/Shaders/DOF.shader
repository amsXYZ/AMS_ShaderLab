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
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform half4 _BlurOffsets;

			uniform float _FocusDepth;
			uniform float _FocalSize;
			uniform float _Aperture;

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
				float fragDepth = abs(Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv)));
				float finalDepth = _Aperture * abs(fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
				finalDepth = clamp(max(0, finalDepth - _FocalSize),0,1);

				float2 uv0Offset = _MainTex_TexelSize * _BlurOffsets.xy * finalDepth;
				float2 uv1Offset = -_MainTex_TexelSize * _BlurOffsets.xy * finalDepth;
				float2 uv2Offset = _MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1) * finalDepth;
				float2 uv3Offset = -_MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1) * finalDepth;

				half4 color = tex2D(_MainTex, i.uv + uv0Offset);
				color += tex2D(_MainTex, i.uv + uv1Offset);
				color += tex2D(_MainTex, i.uv + uv2Offset);
				color += tex2D(_MainTex, i.uv + uv3Offset);

				return color * 0.25;
			}
			ENDCG
		}
	}
}
