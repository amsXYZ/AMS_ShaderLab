#ifndef HALFTONING_CG_INCLUDED
#define HALFTONING_CG_INCLUDED
	
	// Antialiased step function based on this tutorial: http://webstaff.itn.liu.se/~stegu/webglshadertutorial/shadertutorial.html
	float aastep(float threshold, float value) {
		float afwidth = 0.7 * length(float2(ddx(value), ddy(value)));
		return smoothstep(threshold - afwidth, threshold + afwidth, value);
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

#endif // HALFTONING_CG_INCLUDED
