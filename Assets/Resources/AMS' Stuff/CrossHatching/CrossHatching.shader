// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/CrossHatching"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_InkColor("Ink Color", Color) = (0,0,0,0)
		_Hatch0("Hatch: Level 0", 2D) = "white" {}
		_Hatch1("Hatch: Level 1", 2D) = "white" {}
		_Hatch2("Hatch: Level 2", 2D) = "white" {}
		_Hatch3("Hatch: Level 3", 2D) = "white" {}
		_Hatch4("Hatch: Level 4", 2D) = "white" {}
		_Hatch5("Hatch: Level 5", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			Blend One Zero
			ZWrite On	

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0

			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 hatchingUV : TEXCOORD3;
				float3 normal : NORMAL;
				float4 pos : SV_POSITION;
				float3 worldPos : COLOR0;

				LIGHTING_COORDS(1, 2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4 _InkColor;

			sampler2D _Hatch0;
			float4 _Hatch0_ST;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.pos);
				o.worldPos = mul(unity_ObjectToWorld, v.pos);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.hatchingUV = TRANSFORM_TEX(v.uv, _Hatch0);

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float attenuation = max(0,dot(i.normal, _WorldSpaceLightPos0) * LIGHT_ATTENUATION(i));

				float4 c;
				float step = 1. / 6.;
				if (attenuation <= step) {
					c = lerp(tex2D(_Hatch5, i.hatchingUV), tex2D(_Hatch4, i.hatchingUV), 6. * attenuation);
				}
				if (attenuation > step && attenuation <= 2. * step) {
					c = lerp(tex2D(_Hatch4, i.hatchingUV), tex2D(_Hatch3, i.hatchingUV), 6. * (attenuation - step));
				}
				if (attenuation > 2. * step && attenuation <= 3. * step) {
					c = lerp(tex2D(_Hatch3, i.hatchingUV), tex2D(_Hatch2, i.hatchingUV), 6. * (attenuation - 2 * step));
				}
				if (attenuation > 3. * step && attenuation <= 4. * step) {
					c = lerp(tex2D(_Hatch2, i.hatchingUV), tex2D(_Hatch1, i.hatchingUV), 6. * (attenuation - 3 * step));
				}
				if (attenuation > 4. * step && attenuation <= 5. * step) {
					c = lerp(tex2D(_Hatch1, i.hatchingUV), tex2D(_Hatch0, i.hatchingUV), 6. * (attenuation - 4 * step));
				}
				if (attenuation > 5. * step) {
					c = lerp(tex2D(_Hatch0, i.hatchingUV), float4(1,1,1,1), 6. * (attenuation - 5 * step));
				}

				float4 src = lerp(lerp(_InkColor, float4(1,1,1,1), c.r), c, .5);

				

				return tex2D(_MainTex,i.uv) * saturate(src);

			}
			ENDCG
		}
	}
	Fallback "Standard"
}
