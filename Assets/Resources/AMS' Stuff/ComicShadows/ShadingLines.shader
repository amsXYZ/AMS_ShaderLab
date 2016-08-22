Shader "Hidden/ShadingLines"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
	
	/////////////////////////////////
	// Comic Shadows' Lines Shader //
	/////////////////////////////////
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _levels;
			uniform float _angle;
			uniform float _frequency;
			uniform float _size;
			uniform float _separation;
			uniform float4 _shadowColor;

			// Antialiased step function based on this tutorial: http://webstaff.itn.liu.se/~stegu/webglshadertutorial/shadertutorial.html
			float aastep(float threshold, float value) {
				float afwidth = 0.7 * length(float2(ddx(value), ddy(value)));
				return smoothstep(threshold - afwidth, threshold + afwidth, value);
			}

			float4 frag(v2f_img i) : COLOR
			{
				// Read the color from screen
				float4 c = tex2D(_MainTex, i.uv);

				// Calculate the aspect ratio (to properly determine the pattern's width/height)
				float2 aspectRatio = (_ScreenParams.x < _ScreenParams.y) ? float2(1, _ScreenParams.y / _ScreenParams.x) : float2(_ScreenParams.x / _ScreenParams.y, 1);

				// Creation of the line pattern (based on angle and frequency) and determination of the closest line to a pixel
				float2x2 rotMatrix = { cos(radians(_angle)), -sin(radians(_angle)), sin(radians(_angle)), cos(radians(_angle)) };
				float2 st2 = mul(mul(_frequency, rotMatrix), i.uv.xy *  aspectRatio);
				float2 nearest = 2.0*abs(st2%_separation) - _separation;

				// Read the shadow strength (or radius) from the pixel's value
				float radius = sqrt(1.0 - c.w);

				// Calculate half of the size of the lines' width
				float halfSizeLength = pow(radius, 10 - _size) / sqrt(2);

				// Check if the fragment is inside the line
				float X = aastep(halfSizeLength, abs(nearest.x));

				// Calculate the final shadow intensity and lerp between the shadow color and the pixel color using it
				float shadowIntensity = lerp(aastep(0.5, X), 1, saturate(c.w));
				return lerp(lerp(c, _shadowColor, _shadowColor.w), c, shadowIntensity);
			}
			ENDCG
		}
	}
}