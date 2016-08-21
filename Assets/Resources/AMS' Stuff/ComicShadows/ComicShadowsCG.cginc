#ifndef COMICSHADOWS_CG_INCLUDED
#define COMICSHADOWS_CG_INCLUDED

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

		LIGHTING_COORDS(0,1)
	};

	float3 rgb_to_hsv(float3 c)
	{
		float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
		float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
		float d = q.x - min(q.w, q.y);
		float e = 1.0e-4;
		return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}

	float3 hsv_to_rgb(float3 c)
	{
		float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
	}


#endif // COMICSHADOWS_CG_INCLUDED
