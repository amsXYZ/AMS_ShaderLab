Shader "Hidden/Halftone"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}

	// Halftone shader implementation based on:
	// http://webstaff.itn.liu.se/~stegu/webglshadertutorial/shadertutorial.html

	/////////////////////
	// Halftone Shader //
	/////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Halftone
		Pass
		{
			Name "HALFTONE"

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0
			
			#include "UnityCG.cginc"
			#include "HalftoningCG.cginc"
			
			uniform sampler2D _MainTex;
			uniform sampler2D _paper;
			uniform float _frequency;
			uniform int _BW;

			float4 frag(v2f_img i) : COLOR
			{
				// Calculate the relationship between the camera's width and height.
				float2 aspectRatio = (_ScreenParams.x < _ScreenParams.y) ? float2(1, _ScreenParams.y / _ScreenParams.x) : float2(_ScreenParams.x / _ScreenParams.y, 1);

				// Sample the screen color and calculate the size of the radius based on its luminance value.
				float3 texColor = tex2D(_MainTex, i.uv).rgb;
				float radius = sqrt(1.0 - Luminance(texColor));

				// Fractal noise
				float n = 0.1*snoise(i.uv*200.0); 
				n += 0.05*snoise(i.uv*400.0);
				n += 0.025*snoise(i.uv*800.0);

				// Define black and white (affected by the noise)
				float3 white = float3(n*0.5 + 0.98, n*0.5 + 0.98, n*0.5 + 0.98);
				float3 black = float3(n + 0.1, n + 0.1, n + 0.1);

				// Perform a rough RGB-to-CMYK conversion
				float4 cmyk = float4(0,0,0,0);
				cmyk.w = 1 - max(max(texColor.r, texColor.g), texColor.b);
				cmyk.x = (1 - texColor.r - cmyk.w) / (1 - cmyk.w);
				cmyk.y = (1 - texColor.g - cmyk.w) / (1 - cmyk.w);
				cmyk.z = (1 - texColor.b - cmyk.w) / (1 - cmyk.w);

				// Distance to nearest point in a grid of
				// (frequency x frequency) points over the unit square
				float2x2 rotK = { 0.707, -0.707, 0.707, 0.707 };
				float2x2 rotC = { 0.966, -0.259, 0.259, 0.966 };
				float2x2 rotM = { 0.966, 0.259, -0.259, 0.966 };

				float2 Kst = mul(mul(_frequency, rotK), i.uv * aspectRatio);
				float2 Kuv = 2.0*frac(Kst) - 1.0;
				float k = aastep(0.0, sqrt(cmyk.w) - length(Kuv) + n);

				float2 Cst = mul(mul(_frequency, rotC), i.uv * aspectRatio);
				float2 Cuv = 2.0*frac(Cst) - 1.0;
				float c = aastep(0.0, sqrt(cmyk.x) - length(Cuv) + n);

				float2 Mst = mul(mul(_frequency, rotM), i.uv * aspectRatio);
				float2 Muv = 2.0*frac(Mst) - 1.0;
				float m = aastep(0.0, sqrt(cmyk.y) - length(Muv) + n);

				float2 Yst = _frequency * i.uv * aspectRatio;
				float2 Yuv = 2.0*frac(Yst) - 1.0;
				float y = aastep(0.0, sqrt(cmyk.z) - length(Yuv) + n);

				float3 rgbscreen = 1.0 - 0.9*float3(c, m, y) + n;
				if (_BW == 1) rgbscreen = float3(1, 1, 1);
				rgbscreen = lerp(rgbscreen, black, 0.85*k + 0.3*n);

				return float4(rgbscreen, 1) * tex2D(_paper, i.pos / _ScreenParams);
			}
			ENDCG
		}
	}
}
