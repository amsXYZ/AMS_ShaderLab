// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/CrossHatching"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_TAM0("Tonal Art Map: Level 0", 2D) = "white" {}
		_TAM1("Tonal Art Map: Level 1", 2D) = "white" {}
		_TAM2("Tonal Art Map: Level 2", 2D) = "white" {}
		_TAM3("Tonal Art Map: Level 3", 2D) = "white" {}
		_TAM4("Tonal Art Map: Level 4", 2D) = "white" {}
		_TAM5("Tonal Art Map: Level 5", 2D) = "white" {}
		_InkColor("Ink Color", Color) = (0,0,0,0)

		_TAM("Tex", 2DArray) = "" {}
	}

	//////////////////////////
	// Cross-Hatching Shader //
	//////////////////////////
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }

		// 1: Forward Base pass
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
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldPos : COLOR0;
				float3 normalWorld : TEXCOORD2;
				float3 tangentWorld : TEXCOORD3;
				float3 binormalWorld : TEXCOORD4;
				float2 uv : TEXCOORD5;
				float2 hatchingUV : TEXCOORD6;
				

				LIGHTING_COORDS(0, 1)
			};

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _NormalMap;

			uniform sampler2D _TAM0;
			uniform float4 _TAM0_ST;
			uniform sampler2D _TAM1;
			uniform sampler2D _TAM2;
			uniform sampler2D _TAM3;
			uniform sampler2D _TAM4;
			uniform sampler2D _TAM5;

			uniform float4 _InkColor;

			uniform float4 _LightColor0;

			UNITY_DECLARE_TEX2DARRAY(_TAMTexArray);

			v2f vert(appdata v)
			{
				v2f o;

				// Initialize screen position and world position
				o.pos = mul(UNITY_MATRIX_MVP, v.pos);
				o.worldPos = mul(unity_ObjectToWorld, v.pos);

				// Initialize uvs
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.hatchingUV = TRANSFORM_TEX(v.uv, _TAM0);

				// Calculate normal, tangent and bitangent world vectors
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				o.tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);

				// Transfer shadows from shadow map
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				// Calculate the tangent space matrix
				float3x3 tangentToWorldSpace = float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld);

				// Calculate world Normal, Eye and Light vector
				float3 N = mul(normalize(UnpackNormal(tex2D(_NormalMap, i.uv))), tangentToWorldSpace);
				float3 E = -normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 L = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// Get shadows from shadow map
				float attenuation = LIGHT_ATTENUATION(i);

				// Calculate shadows
				float mainLightLum = max(_LightColor0.x, max(_LightColor0.y, _LightColor0.z));
				float shadow = max(0, dot(L, N)) * attenuation * mainLightLum;

				// Sample two layers of the texArray and lerp them
				float t = fmod(shadow * 6, 1);
				float4 a = UNITY_SAMPLE_TEX2DARRAY(_TAMTexArray, float3(i.hatchingUV.xy, floor(shadow * 6.0)));
				float4 b = UNITY_SAMPLE_TEX2DARRAY(_TAMTexArray, float3(i.hatchingUV.xy, floor(shadow * 6.0) + 1.0));
				float c = lerp(a, b, t);

				// Sample the ambient color of the skybox and multiply and add the main light's color to it
				float3 reflectedDir = reflect(E, N);
				float4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, 5);
				float3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);
				float3 colouredSkyColor = lerp(skyColor, skyColor + shadow * _LightColor0, shadow);

				//Calculate the final color
				float4 color = tex2D(_MainTex, i.uv) * float4(colouredSkyColor, 1);
				float3 shadowColor = lerp(color.rgb, _InkColor.rgb, _InkColor.w);
				return float4(lerp(shadowColor, color.rgb, c), 1);
			}
			ENDCG
		}
	}
	Fallback "Standard"
	CustomEditor "CustomCrossHatchingInspector"
}
