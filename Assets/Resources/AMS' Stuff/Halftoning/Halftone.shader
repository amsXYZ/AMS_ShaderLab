Shader "Hidden/Halftone"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_frequency ("Frecuency", Range(1,1000)) = 10
	}

	// Halftone shader implementation based on:
	// http://webstaff.itn.liu.se/~stegu/webglshadertutorial/shadertutorial.html

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#define FRAGMENT_P highp

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0
			
			#include "UnityCG.cginc"
			
			uniform sampler2D _MainTex;
			uniform float _frequency;
			uniform float _radius;
			uniform float _angle;

			uniform float4 _uDims;

			uniform int _BW;

			float aastep(float threshold, float value) {
				float afwidth = 0.7 * length(float2(ddx(value), ddy(value)));
				return smoothstep(threshold - afwidth, threshold + afwidth, value);
			}

			float4 texture2D_bilinear(sampler2D tex, float2 st) {
				float2 dims = _uDims.xy;
				float2 one = _uDims.zw;

				float2 uv = st * dims;
				float2 uv00 = floor(uv - float2(0.5,0.5)); // Lower left corner of lower left texel
				float2 uvlerp = uv - uv00 - float2(0.5,0.5); // Texel-local lerp blends [0,1]
				float2 st00 = (uv00 + float2(0.5,0.5)) * one;
				float4 texel00 = tex2D(tex, st00);
				float4 texel10 = tex2D(tex, st00 + float2(one.x, 0.0));
				float4 texel01 = tex2D(tex, st00 + float2(0.0, one.y));
				float4 texel11 = tex2D(tex, st00 + one);
				float4 texel0 = lerp(texel00, texel01, uvlerp.y);
				float4 texel1 = lerp(texel10, texel11, uvlerp.y);
				return lerp(texel0, texel1, uvlerp.x);
			}

			// Description : Array- and textureless GLSL 2D simplex noise.
			// Author : Ian McEwan, Ashima Arts. Version: 20110822
			// Copyright (C) 2011 Ashima Arts. All rights reserved.
			// Distributed under the MIT License. See LICENSE file.
			// https://github.com/ashima/webgl-noise

			float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
			float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
			float3 permute(float3 x) { return mod289(((x * 34.0) + 1.0) * x); }

			float snoise(float2 v) {
				const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
					0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
					-0.577350269189626,  // -1.0 + 2.0 * C.x
					0.024390243902439); // 1.0 / 41.0
										// First corner
				float2 i = floor(v + dot(v, C.yy));
				float2 x0 = v - i + dot(i, C.xx);
				// Other corners
				float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				// Permutations
				i = mod289(i); // Avoid truncation effects in permutation
				float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
					+ i.x + float3(0.0, i1.x, 1.0));
				float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy),
					dot(x12.zw, x12.zw)), 0.0);
				m = m*m; m = m*m;
				// Gradients
				float3 x = 2.0 * frac(p * C.www) - 1.0;
				float3 h = abs(x) - 0.5;
				float3 a0 = x - floor(x + 0.5);
				// Normalise gradients implicitly by scaling m
				m *= 1.792843 - 0.853735 * (a0*a0 + h*h);
				// Compute final noise value at P
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot(m, g);
			}

			float4 frag(v2f_img i) : COLOR
			{
				float2 aspectRatio = (_ScreenParams.x < _ScreenParams.y) ? float2(1, _ScreenParams.y / _ScreenParams.x) : float2(_ScreenParams.x / _ScreenParams.y, 1);

				float3 texColor = texture2D_bilinear(_MainTex, i.uv).rgb;
				float radius = sqrt(1.0 - texColor.g);

				float n = 0.1*snoise(i.uv*200.0); // Fractal noise
				n += 0.05*snoise(i.uv*400.0);
				n += 0.025*snoise(i.uv*800.0);

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

				float afwidth = 2 * _frequency * max(length(ddx(i.uv * aspectRatio)), length(ddy(i.uv * aspectRatio)));
				float blend = smoothstep(0.7, 1.4, afwidth);

				return float4(lerp(rgbscreen, texColor, blend), 1.0);
			}
			ENDCG
		}
	}
}
