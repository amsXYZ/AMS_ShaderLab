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

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform half4 _BlurOffsets;

			uniform float _FocusDepth;
			uniform float _FocalSize;
			uniform float _Aperture;
			uniform int _Debug;

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
				float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
				float finalDepth = _Aperture * abs(fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
				finalDepth = clamp(max(0, finalDepth - _FocalSize),0,1);

				float2 uv0Offset = _MainTex_TexelSize * _BlurOffsets.xy * finalDepth;
				float2 uv1Offset = -_MainTex_TexelSize * _BlurOffsets.xy * finalDepth;
				float2 uv2Offset = _MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1) * finalDepth;
				float2 uv3Offset = -_MainTex_TexelSize * _BlurOffsets.xy * half2(1, -1) * finalDepth;

				float depth0 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv + uv0Offset));
				float depth1 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv + uv1Offset));
				float depth2 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv + uv2Offset));
				float depth3 = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv + uv3Offset));

				float maxDist = (1 / (_Aperture + 1)) + _FocalSize;

				float weight0 = 1 - min(1, pow(abs(depth0 - fragDepth),2) / pow(maxDist,2));
				float weight1 = 1 - min(1, pow(abs(depth1 - fragDepth), 2) / pow(maxDist, 2));
				float weight2 = 1 - min(1, pow(abs(depth2 - fragDepth), 2) / pow(maxDist, 2));
				float weight3 = 1 - min(1, pow(abs(depth3 - fragDepth), 2) / pow(maxDist, 2));

				float sumWeight = weight0 + weight1 + weight2 + weight3;

				half4 color = tex2D(_MainTex, i.uv + uv0Offset);
				color += tex2D(_MainTex, i.uv + uv1Offset);
				color += tex2D(_MainTex, i.uv + uv2Offset);
				color += tex2D(_MainTex, i.uv + uv3Offset);

				if (_Debug == 1) return finalDepth;
				//if (_Debug == 1) return maxDist;
				return color / 4;
			}
			ENDCG
		}
	}
}
