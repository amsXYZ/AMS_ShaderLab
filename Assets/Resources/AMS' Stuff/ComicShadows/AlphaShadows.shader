// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/AlphaShadows"
{
	Properties
	{
		_MainTex("Albedo Map", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_NormalIntensity("Normal Intensity", Range(0,10)) = 1
		_EmissiveMap("Emission Map", 2D) = "black" {}
		_EmissionColor("Emission Color", Color) = (1,1,1,1)
		_H("Hue",Range(-0.5,0.5)) = 0
		_S("Saturation",Range(-1,1)) = 0
		_B("Brightness",Range(-1,1)) = 0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }

		// Forward Base pass (vertex lighting)
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			Blend One Zero
			ZWrite On

			CGPROGRAM
			#pragma target 5.0

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			#include "UtilityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;
			uniform float _NormalIntensity;
			uniform sampler2D _EmissiveMap;
			uniform float4 _EmissiveMap_ST;
			uniform float4 _EmissionColor;
			uniform float _H;
			uniform float _S;
			uniform float _B;

			float _Levels;
			float4 _LightColor0;

			//Based on Unity's Shade4PointLights, adding levels for toon rendering.
			float3 Shade4PointToonLights(
				float4 lightPosX, float4 lightPosY, float4 lightPosZ,
				float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
				float4 lightAttenSq,
				float3 pos, float3 normal, float levels)
			{
				// to light vectors
				float4 toLightX = lightPosX - pos.x;
				float4 toLightY = lightPosY - pos.y;
				float4 toLightZ = lightPosZ - pos.z;
				// squared lengths
				float4 lengthSq = 0;
				lengthSq += toLightX * toLightX;
				lengthSq += toLightY * toLightY;
				lengthSq += toLightZ * toLightZ;
				// NdotL
				float4 ndotl = 0;
				ndotl += toLightX * normal.x;
				ndotl += toLightY * normal.y;
				ndotl += toLightZ * normal.z;
				// correct NdotL
				float4 corr = rsqrt(lengthSq);
				ndotl = max(float4(0, 0, 0, 0), ndotl * corr);
				// attenuation
				float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);

				float scaleFactor = 1 / levels;

				float4 diff = floor(saturate(ndotl * atten) * levels) * scaleFactor;
				// final color
				float3 col = 0;
				col += lightColor0 * diff.x;
				col += lightColor1 * diff.y;
				col += lightColor2 * diff.z;
				col += lightColor3 * diff.w;
				return col;
			}
			
			v2f vert(a2v v)
			{
				v2f o;

				// Initialize screen position, normal, color and uvs
				o.pos = mul(UNITY_MATRIX_MVP, v.pos);
				o.normal = v.normal;
				o.color = v.color;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.emissionuv = TRANSFORM_TEX(v.uv, _EmissiveMap);
				o.normaluv = TRANSFORM_TEX(v.uv, _NormalMap);
				o.position = mul(unity_ObjectToWorld, v.pos).xyz;

				// Calculate normal, tangent and bitangent world vectors
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				o.tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);

				// Calculate vertex lighting
				o.vertexlighting = float3(0.0, 0.0, 0.0);
				#ifdef VERTEXLIGHT_ON
					o.vertexlighting = saturate(Shade4PointToonLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, o.position, normalize(UnityObjectToWorldNormal(v.normal)), floor(_Levels)));
				#endif

				// Transfer shadows from shadow map
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				return o;
			}
			
			float4 frag(v2f i) : SV_Target
			{
				// Sample the texture and modify the color
				HSBColor baseColor = RGB2HSB(tex2D(_MainTex, i.uv));
				baseColor.h += _H;
				baseColor.s += _S;
				baseColor.b += _B;

				// Calculate the tangent space matrix
				float3x3 tangentToWorldSpace = float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld);

				// Calculate world Normal, Eye and Light vector
				float3 N = mul(normalize(UnpackNormal(tex2D(_NormalMap, i.normaluv))), tangentToWorldSpace);
				float3 E = -normalize(UnityWorldSpaceViewDir(i.position));
				float3 L = normalize(UnityWorldSpaceLightDir(i.position));

				// Get shadows from shadow map
				float attenuation = LIGHT_ATTENUATION(i);

				// Calculate shadows
				float vertexLum = Luminance(i.vertexlighting);
				float3 shadow = saturate((dot(L, N) * Luminance(_LightColor0) + vertexLum) * (attenuation + vertexLum));
				float shadowLum = Luminance(shadow);
				
				// Calculate toon shadows
				_Levels = floor(_Levels);
				float scaleFactor = 1 / _Levels;
				float toonShadow = floor(shadowLum * _Levels) * scaleFactor;

				// Read the emissive value
				float emissiveValue = tex2D(_EmissiveMap, i.emissionuv).r;

				// Composite the final color
				float4 finalColor = lerp(lerp(saturate(HSB2RGB(baseColor)), saturate(HSB2RGB(baseColor)) + _LightColor0 * 0.25 + float4(i.vertexlighting, 1), shadowLum), _EmissionColor, emissiveValue);
				finalColor.w = lerp(toonShadow, 1, emissiveValue);

				return finalColor;
			}
			ENDCG
		}

		// Forward Additive pass (vertex lighting)
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

			sampler2D _NormalMap;
			sampler2D _EmissiveMap;
			float _Levels;

			VertexOutputForwardAdd vertAdd(VertexInput v)
			{
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

				float3 N = normalize(UnpackNormal(tex2D(_NormalMap, i.tex)));
				float3x3 tangentToWorld = float3x3(i.tangentToWorldAndLightDir[0].xyz, i.tangentToWorldAndLightDir[1].xyz, i.tangentToWorldAndLightDir[2].xyz);

				UnityLight light = AdditiveLight(mul(N, tangentToWorld), IN_LIGHTDIR_FWDADD(i), LIGHT_ATTENUATION(i));

				half lum = 0.3*light.color.r*light.ndotl + 0.59*light.color.g*light.ndotl + 0.11*light.color.b*light.ndotl;

				_Levels = floor(_Levels);
				float scaleFactor = 1 / _Levels;
				float toonShadow = floor(lum / 4 * _Levels) * scaleFactor;
				half3 toonColor = light.color * toonShadow;

				half4 color = half4(lerp(half3(0, 0, 0), toonColor, toonShadow * (1 - tex2D(_EmissiveMap, i.tex).r)), toonShadow);
				color.w = toonShadow;

				return color;
			}

			ENDCG 
		}
	}
	Fallback "VertexLit"
}
