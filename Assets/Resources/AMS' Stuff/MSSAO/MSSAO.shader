Shader "Hidden/MSSAO"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		//DOWNSAMPLING NORMAL
		Pass
		{	
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraGBufferTexture2;

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			void SampleDepthNormal(float2 uv, out float3 normal, out float depth)
			{
				float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = LinearEyeDepth(d) + CheckBounds(uv, d);

				float3 norm = tex2D(_CameraGBufferTexture2, uv).xyz;
				norm = norm * 2 - any(norm); // gets (0,0,0) when norm == 0
				normal = mul((float3x3)unity_WorldToCamera, norm);
			}

			// Reconstruct view-space position from UV and depth.
			// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
			// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
			float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
			{
				return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
			}

			float4 frag(v2f_img i) : COLOR
			{
				float2 sample0UV = i.uv;
				float2 sample1UV = i.uv + float2(1, 0) * _MainTex_TexelSize.xy;
				float2 sample2UV = i.uv + float2(0, 1) * _MainTex_TexelSize.xy;
				float2 sample3UV = i.uv + float2(1, 1) * _MainTex_TexelSize.xy;

				float3 normal[4];
				float depth[4];

				SampleDepthNormal(sample0UV, normal[0], depth[0]);
				SampleDepthNormal(sample1UV, normal[1], depth[1]);
				SampleDepthNormal(sample2UV, normal[2], depth[2]);
				SampleDepthNormal(sample3UV, normal[3], depth[3]);

				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				float3 pos[4];

				// Reconstruct the view-space position.
				pos[0] = ReconstructViewPos(sample0UV, depth[0], p11_22, p13_31);
				pos[1] = ReconstructViewPos(sample1UV, depth[1], p11_22, p13_31);
				pos[2] = ReconstructViewPos(sample2UV, depth[2], p11_22, p13_31);
				pos[3] = ReconstructViewPos(sample3UV, depth[3], p11_22, p13_31);

				int depth0Index = 0;
				int depth1Index = 0;
				int depth2Index = 0;
				int depth3Index = 0;
				for (uint i = 1; i < 4; i++)
				{
					if (min(depth[depth0Index], depth[i]) == depth[i]) depth0Index = i;
					if (max(depth[depth3Index], depth[i]) == depth[i]) depth3Index = i;
				}

				int candidate = -1;
				for (int i = 0; i < 4; i++)
				{
					if (depth[i] != depth[depth0Index] && depth[i] != depth[depth3Index]) {
						if(candidate == -1) candidate = i;
						else {
							if (min(depth[candidate], depth[i]) == depth[i]) { depth1Index = i; depth2Index = candidate; }
							else { depth1Index = candidate; depth2Index = i; }
						}
					}
				}

				float3 finalNormal;

				//1 = dThreshold
				if (depth[depth3Index] - depth[depth0Index] <= 1) {
					finalNormal = (normal[depth1Index] + normal[depth2Index]) / 2;
				}
				else {
					finalNormal = normal[depth1Index];
				}

				if (depth[0] >= _ProjectionParams.z - (1.0 / 65025.0) * _ProjectionParams.z) finalNormal = float3(0,0,0);

				return float4(finalNormal, 1);
			}
			ENDCG
		}

		//DOWNSAMPLING POS
		Pass
		{	
			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraGBufferTexture2;

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			void SampleDepthNormal(float2 uv, out float3 normal, out float depth)
			{
				float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = LinearEyeDepth(d) + CheckBounds(uv, d);

				float3 norm = tex2D(_CameraGBufferTexture2, uv).xyz;
				norm = norm * 2 - any(norm); // gets (0,0,0) when norm == 0
				normal = mul((float3x3)unity_WorldToCamera, norm);
			}

			// Reconstruct view-space position from UV and depth.
			// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
			// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
			float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
			{
				return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
			}

			float4 frag(v2f_img i) : COLOR
			{
				float2 sample0UV = i.uv;
				float2 sample1UV = i.uv + float2(1, 0) * _MainTex_TexelSize.xy;
				float2 sample2UV = i.uv + float2(0, 1) * _MainTex_TexelSize.xy;
				float2 sample3UV = i.uv + float2(1, 1) * _MainTex_TexelSize.xy;

				float3 normal[4];
				float depth[4];

				SampleDepthNormal(sample0UV, normal[0], depth[0]);
				SampleDepthNormal(sample1UV, normal[1], depth[1]);
				SampleDepthNormal(sample2UV, normal[2], depth[2]);
				SampleDepthNormal(sample3UV, normal[3], depth[3]);

				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				float3 pos[4];

				// Reconstruct the view-space position.
				pos[0] = ReconstructViewPos(sample0UV, depth[0], p11_22, p13_31);
				pos[1] = ReconstructViewPos(sample1UV, depth[1], p11_22, p13_31);
				pos[2] = ReconstructViewPos(sample2UV, depth[2], p11_22, p13_31);
				pos[3] = ReconstructViewPos(sample3UV, depth[3], p11_22, p13_31);

				int depth0Index = 0;
				int depth1Index = 0;
				int depth2Index = 0;
				int depth3Index = 0;
				for (uint i = 1; i < 4; i++)
				{
					if (min(depth[depth0Index], depth[i]) == depth[i]) depth0Index = i;
					if (max(depth[depth3Index], depth[i]) == depth[i]) depth3Index = i;
				}

				int candidate = -1;
				for (int i = 0; i < 4; i++)
				{
					if (depth[i] != depth[depth0Index] && depth[i] != depth[depth3Index]) {
						if(candidate == -1) candidate = i;
						else {
							if (min(depth[candidate], depth[i]) == depth[i]) { depth1Index = i; depth2Index = candidate; }
							else { depth1Index = candidate; depth2Index = i; }
						}
					}
				}

				float3 finalPos;

				//1 = dThreshold
				if (depth[depth3Index] - depth[depth0Index] <= 1) {
					finalPos = (pos[depth1Index] + pos[depth2Index]) / 2;

				}
				else {
					finalPos = pos[depth1Index];
				}

				finalPos += ReconstructViewPos(float2(0,0), _ScreenParams.z, p11_22, p13_31);

				return float4(finalPos, 1);
			}
			ENDCG
		}

		//COMPUTE AO - FIRST PASS
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _FOV;
			uniform float _maxDist;
			uniform int _maxKernelSize;
			uniform float _r;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraGBufferTexture2;

			uniform float _PoissonDisks[32];

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			void SampleDepthNormal(float2 uv, out float3 normal, out float depth)
			{
				float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = LinearEyeDepth(d) + CheckBounds(uv, d);

				float3 norm = tex2D(_CameraGBufferTexture2, uv).xyz;
				norm = norm * 2 - any(norm); // gets (0,0,0) when norm == 0
				normal = mul((float3x3)unity_WorldToCamera, norm);
			}

			// Reconstruct view-space position from UV and depth.
			// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
			// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
			float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
			{
				return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
			}

			float ComputeOcclusion(float2 sampleUV, float3 centerPos, float3 centerNorm) {
				float3 sampleNorm;
				float sampleDepth;
				SampleDepthNormal(sampleUV, sampleNorm, sampleDepth);

				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				// Reconstruct the view-space position.
				float3 samplePos = ReconstructViewPos(sampleUV, sampleDepth, p11_22, p13_31);

				float d = distance(centerPos, samplePos);
				float t = 1 - min(1, (d * d) / (_maxDist * _maxDist));

				float3 diff = normalize(samplePos - centerPos);
				float cosTheta = max(dot(centerNorm, diff), 0);

				return t * cosTheta;
			}

			float4 frag(v2f_img i) : COLOR
			{
				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				// Pixel's viewspace normal and depth
				float3 centerNorm;
				float centerDepth;
				SampleDepthNormal(i.uv, centerNorm, centerDepth);

				// Reconstruct the view-space position.
				float3 centerPos = ReconstructViewPos(i.uv, centerDepth, p11_22, p13_31);

				float AONear = 0;
				float AOSamples = 0.0001;

				float rangeMax = min(_r / abs(centerPos.z), _maxKernelSize);

				//Adjust to rangeMax
				for (float k = -5; k <= 5; k += 2)
				{
					for (float q = -5; q <= 5; q += 2)
					{
						AONear += ComputeOcclusion(i.uv + float2(floor(1.0001 * q), floor(1.0001 * k)) * _MainTex_TexelSize, centerPos, centerNorm);
						AOSamples++;
					}
				}

				return float4(centerPos, 1);

				return 1 - AONear / AOSamples;
				return float4(AONear / AOSamples, AONear, AOSamples, 0);
			}
			ENDCG
		}

		//COMPUTE AO - INTERMEDIUM PASSES
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform sampler2D _AOFar;
			uniform float4 _AOFar_TexelSize;

			uniform float _FOV;
			uniform float _maxDist;
			uniform int _maxKernelSize;
			uniform float _r;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraGBufferTexture2;

			uniform float _PoissonDisks[32];

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			void SampleDepthNormal(float2 uv, out float3 normal, out float depth)
			{
				float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = LinearEyeDepth(d) + CheckBounds(uv, d);

				float3 norm = tex2D(_CameraGBufferTexture2, uv).xyz;
				norm = norm * 2 - any(norm); // gets (0,0,0) when norm == 0
				normal = mul((float3x3)unity_WorldToCamera, norm);
			}

			// Reconstruct view-space position from UV and depth.
			// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
			// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
			float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
			{
				return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
			}

			float ComputeOcclusion(float2 sampleUV, float3 centerPos, float3 centerNorm) {
				float3 sampleNorm;
				float sampleDepth;
				SampleDepthNormal(sampleUV, sampleNorm, sampleDepth);

				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				// Reconstruct the view-space position.
				float3 samplePos = ReconstructViewPos(sampleUV, sampleDepth, p11_22, p13_31);

				float d = distance(centerPos, samplePos);
				float t = 1 - min(1, (d * d) / (_maxDist * _maxDist));

				float3 diff = normalize(samplePos - centerPos);
				float cosTheta = max(dot(centerNorm, diff), 0);

				return t * cosTheta;
			}

			float3 Upsample(sampler2D downsampledTexture, float4 texelSize, float2 sampleUV)
			{
				float2 lowResSamples[4];

				float2 realPixels = sampleUV * texelSize.zw;

				lowResSamples[0] = (floor((sampleUV * texelSize.zw + float2(-1.0, 1.0)) / 2.0) + float2(0.5, 0.5)) * texelSize.xy;
				lowResSamples[1] = (floor((sampleUV * texelSize.zw + float2(1.0, 1.0)) / 2.0) + float2(0.5, 0.5)) * texelSize.xy;
				lowResSamples[2] = (floor((sampleUV * texelSize.zw + float2(-1.0, -1.0)) / 2.0) + float2(0.5, 0.5)) * texelSize.xy;
				lowResSamples[3] = (floor((sampleUV * texelSize.zw + float2(1.0, -1.0)) / 2.0) + float2(0.5, 0.5)) * texelSize.xy;

				float3 lowResAO[4];
				float3 lowResNorm[4];
				float lowResDepth[4];

				//I NEED TO HAVE THE LOW RES TEXTURES
				/*for (int i = 0; i < 4; ++i)
				{
					loResNorm[i] = texture2DRect(loResNormTex, loResCoord[i]).xyz;
					loResDepth[i] = texture2DRect(loResPosTex, loResCoord[i]).z;
					loResAO[i] = texture2DRect(loResAOTex, loResCoord[i]).xyz;
				}
				float normWeight[4];
				for (int i = 0; i < 4; ++i)
				{
					normWeight[i] = (dot(loResNorm[i], n) + 1.1) / 2.1;
					normWeight[i] = pow(normWeight[i], 8.0);
				}
				float depthWeight[4];
				for (int i = 0; i < 4; ++i)
				{
					depthWeight[i] = 1.0 / (1.0 + abs(p.z - loResDepth[i]) * 0.2);
					depthWeight[i] = pow(depthWeight[i], 16.0);
				}
				float totalWeight = 0.0;
				vec3 combinedAO = vec3(0.0);
				for (int i = 0; i < 4; ++i)
				{
					float weight = normWeight[i] * depthWeight[i] * (9.0 / 16.0) /
						(abs((gl_FragCoord.x - loResCoord[i].x * 2.0) * (gl_FragCoord.y - loResCoord[i].y * 2.0)) * 4.0);
					totalWeight += weight;
					combinedAO += loResAO[i] * weight;
				}
				combinedAO /= totalWeight;
				return combinedAO;*/

				return 1;
			}

			float4 frag(v2f_img i) : COLOR
			{
				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				// Pixel's viewspace normal and depth
				float3 centerNorm;
				float centerDepth;
				SampleDepthNormal(i.uv, centerNorm, centerDepth);

				// Reconstruct the view-space position.
				float3 centerPos = ReconstructViewPos(i.uv, centerDepth, p11_22, p13_31);

				float AONear = 0;
				float AOSamples = 0.0001;

				float rangeMax = min(_r / abs(centerPos.z), _maxKernelSize);

				//Adjust to rangeMax
				for (float k = -5; k <= 5; k += 2)
				{
					for (float q = -5; q <= 5; q += 2)
					{
						AONear += ComputeOcclusion(i.uv + float2(floor(1.0001 * q), floor(1.0001 * k)) * _MainTex_TexelSize, centerPos, centerNorm);
						AOSamples++;
					}
				}

				return float4(centerPos, 1);

				return tex2D(_AOFar, i.uv) * (1 - AONear / AOSamples);

				float3 upsample = Upsample(_AOFar, _AOFar_TexelSize, i.uv);
				return float4(max(upsample.x, AONear / AOSamples), upsample.y + AONear, upsample.z + AOSamples, 0.0);
			}
			ENDCG
		}

		//COMPUTE AO - LAST PASS
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform sampler2D _AOFar;

			uniform float _FOV;
			uniform float _maxDist;
			uniform int _maxKernelSize;
			uniform float _r;

			sampler2D _CameraDepthTexture;
			sampler2D _CameraGBufferTexture2;

			uniform float _PoissonDisks[32];

			// Boundary check for depth sampler
			// (returns a very large value if it lies out of bounds)
			float CheckBounds(float2 uv, float d)
			{
				float ob = any(uv < 0) + any(uv > 1);
				#if defined(UNITY_REVERSED_Z)
					ob += (d <= 0.00001);
				#else
					ob += (d >= 0.99999);
				#endif
				return ob * 1e8;
			}

			void SampleDepthNormal(float2 uv, out float3 normal, out float depth)
			{
				float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = LinearEyeDepth(d) + CheckBounds(uv, d);

				float3 norm = tex2D(_CameraGBufferTexture2, uv).xyz;
				norm = norm * 2 - any(norm); // gets (0,0,0) when norm == 0
				normal = mul((float3x3)unity_WorldToCamera, norm);
			}

			// Reconstruct view-space position from UV and depth.
			// p11_22 = (unity_CameraProjection._11, unity_CameraProjection._22)
			// p13_31 = (unity_CameraProjection._13, unity_CameraProjection._23)
			float3 ReconstructViewPos(float2 uv, float depth, float2 p11_22, float2 p13_31)
			{
				return float3((uv * 2 - 1 - p13_31) / p11_22, 1) * depth;
			}

			float ComputeOcclusion(float2 sampleUV, float3 centerPos, float3 centerNorm) {
				float3 sampleNorm;
				float sampleDepth;
				SampleDepthNormal(sampleUV, sampleNorm, sampleDepth);

				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				// Reconstruct the view-space position.
				float3 samplePos = ReconstructViewPos(sampleUV, sampleDepth, p11_22, p13_31);

				float d = distance(centerPos, samplePos);
				float t = 1 - min(1, (d * d) / (_maxDist * _maxDist));

				float3 diff = normalize(samplePos - centerPos);
				float cosTheta = max(dot(centerNorm, diff), 0);

				return t * cosTheta;
			}

			float4 frag(v2f_img i) : COLOR
			{
				// Parameters used in coordinate conversion
				float3x3 proj = (float3x3)unity_CameraProjection;
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				float2 p13_31 = float2(unity_CameraProjection._13, unity_CameraProjection._23);

				// Pixel's viewspace normal and depth
				float3 centerNorm;
				float centerDepth;
				SampleDepthNormal(i.uv, centerNorm, centerDepth);

				// Reconstruct the view-space position.
				float3 centerPos = ReconstructViewPos(i.uv, centerDepth, p11_22, p13_31);

				float AONear = 0;
				float AOSamples = 0;

				float rangeMax = min(_r / abs(centerPos.z), _maxKernelSize);

				//Adjust to rangeMax
				for (int x = 0; x < 32; x += 2)
				{
					float2 sampleUV = i.uv + float2(_PoissonDisks[x], _PoissonDisks[x + 1]) * _maxKernelSize * _MainTex_TexelSize.xy;
					AONear += ComputeOcclusion(sampleUV, centerPos, centerNorm);
					AOSamples++;
				}

				return float4(centerPos, 1);

				return tex2D(_AOFar, i.uv) * (1 - AONear / AOSamples);

				if (floor(i.uv.x * 200) % 2 == 0)
					return tex2D(_MainTex, i.uv) * (1 - AONear / AOSamples);
				else
					return tex2D(_MainTex, i.uv);
			}
			ENDCG
		}

		//COMPOSITING
		Pass
		{
			//Blend One One

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag

			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;

			uniform sampler2D _AOFar;

			float4 frag(v2f_img i) : COLOR
			{
				float4 color = tex2D(_MainTex, i.uv) * tex2D(_AOFar, i.uv);

				return color;
			}
				ENDCG
		}
	}
}
