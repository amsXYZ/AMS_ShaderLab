// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/AlphaShadows"
{
	Properties
	{
		_MainTex("Albedo Map", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.1
		_NormalMap("Normal Map", 2D) = "bump" {}
		_NormalIntensity("Normal Intensity", Range(0,10)) = 1
		_EmissionMap("Emission Map", 2D) = "black" {}
		_EmissionColor("Emission Color", Color) = (1,1,1,1)
		_EmissionIntensity("Emission Intensity", Float) = 1
		_Hue("Hue",Range(-0.5,0.5)) = 0
		_Saturation("Saturation",Range(-1,1)) = 0
		_Value("Value",Range(-1,1)) = 0
		[HideInSpector]_Mode("_Mode", Float) = 0

		_Color("Color", Color) = (1,1,1,1)
	}

	//////////////////////////
	// Alpha Shadows Shader //
	//////////////////////////
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }
		
		// 0: ShadowCaster
		Pass{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual
			Cull Off

			CGPROGRAM
			#pragma target 5.0

			#pragma shader_feature _ _ALPHATEST_ON
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "UnityCG.cginc"

			half		_Cutoff;
			sampler2D	_MainTex;
			float4		_MainTex_ST;

			struct VertexInput
			{
				float4 vertex	: POSITION;
				float3 normal	: NORMAL;
				float2 uv0		: TEXCOORD0;
			};

			struct VertexOutputShadowCaster
			{
				V2F_SHADOW_CASTER_NOPOS
				float2 tex : TEXCOORD1;
			};

			void vertShadowCaster (VertexInput v, out VertexOutputShadowCaster o, out float4 opos : SV_POSITION)
			{
				TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
				o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
			}

			//Simple shaodw caster who takes in to account the alpha depending on the rendering mode.
			half4 fragShadowCaster (VertexOutputShadowCaster i) : SV_Target
			{
				half alpha = tex2D(_MainTex, i.tex).a;
				#if defined(_ALPHATEST_ON)
						clip(alpha - _Cutoff);
				#endif

				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}

		// 1: Forward Base pass
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			Blend One Zero
			ZWrite On
			Cull Off

			CGPROGRAM
			#pragma target 5.0

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			#include "ComicShadowsCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform fixed _Cutoff;
			uniform sampler2D _NormalMap;
			uniform float _NormalIntensity;
			uniform sampler2D _EmissionMap;
			uniform float4 _EmissionColor;
			uniform float _Hue;
			uniform float _Saturation;
			uniform float _Value;
			uniform int _Mode;

			float _Levels;
			float4 _LightColor0;
			
			v2f vert(a2v v)
			{
				v2f o;

				// Initialize screen position, normal, color and uvs
				o.pos = mul(UNITY_MATRIX_MVP, v.pos);
				o.normal = v.normal;
				o.color = v.color;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.position = mul(unity_ObjectToWorld, v.pos).xyz;

				// Calculate normal, tangent and bitangent world vectors
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				o.tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);

				// Calculate vertex lighting
				o.vertexlighting = float3(0.0, 0.0, 0.0);
				#ifdef VERTEXLIGHT_ON
					o.vertexlighting = Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, o.position, normalize(UnityObjectToWorldNormal(v.normal)));
				#endif

				// Transfer shadows from shadow map
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				return o;
			}
			
			float4 frag(v2f i) : SV_Target
			{
				// Sample the texture and modify the color
				float3 baseColor = rgb_to_hsv(tex2D(_MainTex, i.uv));
				baseColor.r += _Hue;
				baseColor.g += _Saturation;
				baseColor.b += _Value;

				// Calculate the tangent space matrix
				float3x3 tangentToWorldSpace = float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld);

				// Calculate world Normal, Eye and Light vector
				float3 N = mul(normalize(UnpackNormal(tex2D(_NormalMap, i.uv))), tangentToWorldSpace);
				float3 E = -normalize(UnityWorldSpaceViewDir(i.position));
				float3 L = normalize(UnityWorldSpaceLightDir(i.position));

				// Get shadows from shadow map
				float attenuation = LIGHT_ATTENUATION(i);

				// Calculate shadows
				float vertexLum = max(i.vertexlighting.x, max(i.vertexlighting.y, i.vertexlighting.z));
				float mainLightLum = max(_LightColor0.x, max(_LightColor0.y, _LightColor0.z));
				float3 shadow = max(0, dot(L, N)) * attenuation * mainLightLum + vertexLum/8;
				float shadowLum = Luminance(shadow);
				
				// Calculate toon shadows
				_Levels = floor(_Levels);
				float scaleFactor = 1 / _Levels;
				float toonShadow = round(shadowLum * _Levels) * scaleFactor;
				float3 toonLight = toonShadow * (_LightColor0 + i.vertexlighting);

				// Read the emissive value
				float emissiveValue = tex2D(_EmissionMap, i.uv).r;

				// Sample the ambient color of the skybox and multiply and add the main light's color to it
				float3 reflectedDir = reflect(E, N);
				float4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, 5);
				float3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);
				float3 colouredSkyColor = lerp(skyColor, skyColor + toonLight, toonShadow);

				// Composite the final color
				float4 finalColor = float4(_EmissionColor * _EmissionColor.w * emissiveValue + hsv_to_rgb(baseColor) * colouredSkyColor, 1);
				finalColor.w = lerp(toonShadow, 1, emissiveValue * _EmissionColor.w);

				// Clip the fragment if necessary
				clip(tex2D(_MainTex, i.uv).w - _Cutoff * _Mode);

				return finalColor;
			}
			ENDCG
		}

		// 2: Forward Additive pass
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }

			Blend One One
			ZWrite Off

			CGPROGRAM
			#pragma target 5.0

			#pragma multi_compile_fwdadd_fullshadows

			#pragma vertex vertAdd
			#pragma fragment fragAdd
			#include "UnityStandardCore.cginc"

			uniform sampler2D _NormalMap;
			uniform float _Levels;
			uniform int _Mode;

			// Initialization of the main values we'll use on the fragment shader.
			VertexOutputForwardAdd vertAdd(VertexInput v)
			{
				// We used these unity structs and methods to later calculate properly both attenuation and intensity.
				VertexOutputForwardAdd o;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.tex = TexCoords(v);
				o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);

				#ifdef _TANGENT_TO_WORLD
					float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

					float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
					o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
					o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
					o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
				#else
					o.tangentToWorldAndLightDir[0].xyz = 0;
					o.tangentToWorldAndLightDir[1].xyz = 0;
					o.tangentToWorldAndLightDir[2].xyz = normalWorld;
				#endif

				//We need this for shadow receiving
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
				#ifndef USING_DIRECTIONAL_LIGHT
					lightDir = NormalizePerVertexNormal(lightDir);
				#endif
				o.tangentToWorldAndLightDir[0].w = lightDir.x;
				o.tangentToWorldAndLightDir[1].w = lightDir.y;
				o.tangentToWorldAndLightDir[2].w = lightDir.z;

				return o;
			}

			half4 fragAdd(VertexOutputForwardAdd i) : SV_Target
			{
				FRAGMENT_SETUP_FWDADD(s)

				// Creation of the tangent to world matrix to apply normal maps correctly
				float3 N = normalize(UnpackNormal(tex2D(_NormalMap, i.tex)));
				float3x3 tangentToWorld = float3x3(i.tangentToWorldAndLightDir[0].xyz, i.tangentToWorldAndLightDir[1].xyz, i.tangentToWorldAndLightDir[2].xyz);

				// Definition of out Unity's additive light
				UnityLight light = AdditiveLight(mul(N, tangentToWorld), IN_LIGHTDIR_FWDADD(i), LIGHT_ATTENUATION(i));

				half lum = max(light.color.r, max(light.color.g, light.color.b))*light.ndotl/32;

				// Calculation of the light's intensity
				_Levels = floor(_Levels);
				float scaleFactor = 1 / _Levels;
				float toonShadow = round(lum * _Levels) * scaleFactor;
				half3 toonColor = light.color * light.ndotl * toonShadow;

				half4 color = half4(toonColor, toonShadow);

				// Clip the fragment if needed
				clip(tex2D(_MainTex, i.tex).w - _Cutoff * _Mode);

				return color;
			}

			ENDCG 
		}
	}
	Fallback "Standard"
	CustomEditor "CustomAlphaShadowsInspector"
}
