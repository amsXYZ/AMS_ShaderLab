Shader "Hidden/ToonShading"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_levels("Levels", Range(2,30)) = 2
		_angle("Angle", Range(0,180)) = 30
		_frequency("Frequency", Range(0,1)) = 0.75
		_size("Frequency", Range(1,10)) = 1
		_shadowColor("Shadow Color", Color) = (0,0,0,1)
		_lightColor("Light Color", Color) = (1,1,1,1)

	}
	
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _levels;
			uniform float _angle;
			uniform float _frequency;
			uniform float _size;
			uniform float4 _shadowColor;
			uniform float4 _lightColor;

			float aastep(float threshold, float value) {
				float afwidth = 0.7 * length(float2(ddx(value), ddy(value)));
				return smoothstep(threshold - afwidth, threshold + afwidth, value);
			}

			float4 frag(v2f_img i) : COLOR
			{
				float4 c = tex2D(_MainTex, i.uv);

				return lerp(lerp(c, _shadowColor, _shadowColor.w), c, saturate(c.w));
			}
			ENDCG
		}
	}
}