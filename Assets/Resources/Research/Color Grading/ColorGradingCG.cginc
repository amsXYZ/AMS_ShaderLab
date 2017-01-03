#ifndef COLORGRADING_CG_INCLUDED
#define COLORGRADING_CG_INCLUDED

	uniform sampler2D _MainTex;
	uniform float4 _MainTex_TexelSize;

	uniform sampler3D _LUT;
	uniform float _Scale;
	uniform float _Offset;
	uniform float3 _WhiteBalance;
	uniform float3 _ContrastGainGamma;
	uniform float _Vibrance;
	uniform float3 _HSV;

	uniform sampler2D _DebugLUT;
	uniform float4 _DebugLUT_TexelSize;
	uniform int _Debug;

	static const half3x3 LIN_2_LMS_MAT = {
		3.90405e-1, 5.49941e-1, 8.92632e-3,
		7.08416e-2, 9.63172e-1, 1.35775e-3,
		2.31082e-2, 1.28021e-1, 9.36245e-1
	};

	static const half3x3 LMS_2_LIN_MAT = {
		2.85847e+0, -1.62879e+0, -2.48910e-2,
		-2.10182e-1,  1.15820e+0,  3.24281e-4,
		-4.18120e-2, -1.18169e-1,  1.06867e+0
	};

	half3 rgb_to_hsv(half3 c)
	{
		half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
		half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
		half d = q.x - min(q.w, q.y);
		half e = 1.0e-4;
		return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}

	half3 hsv_to_rgb(half3 c)
	{
		half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
	}

	// CG's fmod() is not the same as GLSL's mod() with negative values, we'll use our own
	inline half gmod(half x, half y)
	{
		return x - y * floor(x / y);
	}

	float4 frag(v2f_img i) : COLOR
	{
		// Use the original color's rgb values to sample the LUT.
		float3 originalColor = tex2D(_MainTex, i.uv).rgb;
		float3 gradedColor = tex3D(_LUT, float3(originalColor.r, 1 - originalColor.g, originalColor.b) * _Scale + _Offset).rgb;

		// White balance
		half3 lms = mul(LIN_2_LMS_MAT, gradedColor);
		lms *= _WhiteBalance;
		gradedColor = mul(LMS_2_LIN_MAT, lms);

		// Hue/saturation/value
		half3 hsv = rgb_to_hsv(gradedColor);
		hsv.x = gmod(hsv.x + _HSV.x, 1.0);
		hsv.yz *= _HSV.yz;
		gradedColor = saturate(hsv_to_rgb(hsv));

		// Vibrance
		half sat = max(gradedColor.r, max(gradedColor.g, gradedColor.b)) - min(gradedColor.r, min(gradedColor.g, gradedColor.b));
		gradedColor = lerp(Luminance(gradedColor).xxx, gradedColor, (1.0 + (_Vibrance * (1.0 - (sign(_Vibrance) * sat)))));

		// Contrast
		gradedColor = saturate((gradedColor - 0.5) * _ContrastGainGamma.x + 0.5);

		// Gain
		half f = pow(2.0, _ContrastGainGamma.y) * 0.5;
		gradedColor = (gradedColor < 0.5) ? pow(gradedColor, _ContrastGainGamma.y) * f : 1.0 - pow(1.0 - gradedColor, _ContrastGainGamma.y) * f;

		// Gamma
		gradedColor = pow(gradedColor, _ContrastGainGamma.z);

		return float4(gradedColor,1);
	}

	float4 frag_debug(v2f_img i) : COLOR
	{
		// Use the original color's rgb values to sample the LUT.
		float3 originalColor = tex2D(_MainTex, i.uv).rgb;
		float3 gradedColor = tex3D(_LUT, float3(originalColor.r, 1 - originalColor.g, originalColor.b) * _Scale + _Offset).rgb;

		// Flip the original texture's UV if they are flipped (it can happen sometimes).
		#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0.0) i.uv.y = 1.0 - i.uv.y;
		#endif

		// Calculate if the pixel should draw the debug texture.
		float scaleX = _MainTex_TexelSize.z * 0.8 / _DebugLUT_TexelSize.z;
		if ((i.uv.x <= 0.8) && (i.uv.y <= _DebugLUT_TexelSize.w / _MainTex_TexelSize.w * scaleX) && (_Debug != 0)) {
			// Calculate the uvs for the debug texture and sample it.
			float2 newUVs = i.uv / float2(0.8, _DebugLUT_TexelSize.w / _MainTex_TexelSize.w);
			gradedColor = tex2D(_DebugLUT, newUVs);
		}

		// White balance
		half3 lms = mul(LIN_2_LMS_MAT, gradedColor);
		lms *= _WhiteBalance;
		gradedColor = mul(LMS_2_LIN_MAT, lms);

		// Hue/saturation/value
		half3 hsv = rgb_to_hsv(gradedColor);
		hsv.x = gmod(hsv.x + _HSV.x, 1.0);
		hsv.yz *= _HSV.yz;
		gradedColor = saturate(hsv_to_rgb(hsv));

		// Vibrance
		half sat = max(gradedColor.r, max(gradedColor.g, gradedColor.b)) - min(gradedColor.r, min(gradedColor.g, gradedColor.b));
		gradedColor = lerp(Luminance(gradedColor).xxx, gradedColor, (1.0 + (_Vibrance * (1.0 - (sign(_Vibrance) * sat)))));

		// Contrast
		gradedColor = saturate((gradedColor - 0.5) * _ContrastGainGamma.x + 0.5);

		// Gain
		half f = pow(2.0, _ContrastGainGamma.y) * 0.5;
		gradedColor = (gradedColor < 0.5) ? pow(gradedColor, _ContrastGainGamma.y) * f : 1.0 - pow(1.0 - gradedColor, _ContrastGainGamma.y) * f;

		// Gamma
		gradedColor = pow(gradedColor, _ContrastGainGamma.z);

		return float4(gradedColor,1);
	}

#endif // COLORGRADING_CG_INCLUDED
