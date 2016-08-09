#ifndef UTILITY_CG_INCLUDED
#define UTILITY_CG_INCLUDED

#define PI 3.141592653589793238462643383279502884197169399375105820974944592307816406286

	struct a2v {
		float4 pos : POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
		float4 color : COLOR;
		float2 uv : TEXCOORD0;
	};

	struct v2f {
		float4 pos : SV_POSITION;
		float3 normal : NORMAL;
		float4 color : COLOR0;
		float3 position : COLOR1;
		float3 vertexlighting : TEXCOORD2;
		float3 normalWorld : TEXCOORD3;
		float3 tangentWorld : TEXCOORD4;
		float3 binormalWorld : TEXCOORD5;
		float2 uv : TEXCOORD6;
		float2 emissionuv : TEXCOORD7;
		float2 normaluv : TEXCOORD8;

		LIGHTING_COORDS(0,1)
	};

	struct HSBColor {
		float h;
		float s;
		float b;
		float a;
	};

	HSBColor RGB2HSB(float4 color) {
		HSBColor ret;
		ret.h = ret.s = ret.b = 0;
		ret.a = color.a;

		float r = color.r;
		float g = color.g;
		float b = color.b;

		float M = max(r, max(g, b));

		if (M <= 0) return ret;

		float m = min(r, min(g, b));
		float dif = M - m;

		if (M > m) {
			if (g == M) ret.h = (b - r) / dif * 60 + 120;
			else if (b == M) ret.h = (r - g) / dif * 60 + 240;
			else if (b > g) ret.h = (g - b) / dif * 60 + 360;
			else ret.h = (g - b) / dif * 60;

			if (ret.h < 0) ret.h = ret.h + 360;
		}

		else ret.h = 0;

		ret.h = ret.h / 360;
		ret.s = dif / M;
		ret.b = M;

		return ret;
	}

	float4 HSB2RGB(HSBColor color) {
		float r = color.b;
		float g = color.b;
		float b = color.b;

		if (color.s != 0) {
			float M = clamp(color.b, 0, 1);
			float dif = clamp(color.b * color.s, 0, 1);
			float m = color.b - dif;

			float h = frac(color.h) * 360;

			if (h < 60) {
				r = M;
				g = h * dif / 60 + m;
				b = m;
			}
			else if (h < 120) {
				r = -(h - 120) * dif / 60 + m;
				g = M;
				b = m;
			}
			else if (h < 180) {
				r = m;
				g = M;
				b = (h - 120) * dif / 60 + m;
			}
			else if (h < 240) {
				r = m;
				g = -(h - 240) * dif / 60 + m;
				b = M;
			}
			else if (h < 300) {
				r = (h - 240) * dif / 60 + m;
				g = m;
				b = M;
			}
			else if (h <= 360) {
				r = M;
				g = m;
				b = -(h - 360) * dif / 60 + m;
			}
			else {
				r = g = b = 0;
			}
		}

		return float4(clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1), color.a);
	}

	HSBColor complementary(HSBColor color) {
		HSBColor complementary = color;
		complementary.h += 0.5;
		return complementary;
	}

	HSBColor maxSaturate(HSBColor color) {
		HSBColor sat = color;
		sat.s = 1;
		return sat;
	}

	HSBColor lighten(HSBColor color, float light) {
		HSBColor lighten = color;
		lighten.b += light;
		return lighten;
	}

	HSBColor HSBLerp(HSBColor a, HSBColor b, float t)
	{
		// Hue interpolation
		float h;
		float d = b.h - a.h;
		if (a.h > b.h)
		{
			// Swap (a.h, b.h)
			float h3 = b.h;
			b.h = a.h;
			a.h = h3;

			d = -d;
			t = 1 - t;
		}

		if (d > 0.5) // 180deg
		{
			a.h = a.h + 1; // 360deg
			h = fmod(a.h + t * (b.h - a.h), 1); // 360deg
		}
		if (d <= 0.5) // 180deg
		{
			h = a.h + t * d;
		}

		// Interpolates the rest
		HSBColor interpolatedColor;
		interpolatedColor.h = h;
		interpolatedColor.s = a.s + t * (b.s - a.s);
		interpolatedColor.b = a.b + t * (b.b - a.b);
		return interpolatedColor;
	}

	float remap(float value, float l1, float h1, float l2, float h2){
		return l2 + (value - l1) * (h2 - l2) / (h1 - l1);
	}

	float aastep(float threshold, float value) {
		float afwidth = 0.7 * length(float2(ddx(value), ddy(value)));
		return smoothstep(threshold - afwidth, threshold + afwidth, value);
	}

	float Gauss(float x, float propagationRate)
	{
		float a = 1 / (propagationRate * sqrt(2 * PI));
		float b = 0;
		float c = propagationRate;

		return a * exp(-pow(x - b, 2) / 2 * pow(c, 2));
	}

#endif // UTILITY_CG_INCLUDED
