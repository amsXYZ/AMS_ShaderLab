#ifndef DOF_CG_INCLUDED
#define DOF_CG_INCLUDED
	
	uniform sampler2D _MainTex;
	uniform float4 _MainTex_TexelSize;

	uniform float _FocusDepth;
	uniform float _FocalSize;
	uniform float _Aperture;
	uniform float _MaxBlurDistance;
	uniform int _Debug;

	uniform sampler2D _downsampledBlurredB;
	uniform sampler2D _downsampledBlurredF;

	uniform float _PoissonDisks[32];

	sampler2D_float _CameraDepthTexture;

	// Calculates the radius of the Circle of Confusion for the imaging plane that corresponds to _FocusDepth
	// and sample the frag's depth inside it.
	float4 fragCoC(v2f_img i) : COLOR
	{
		float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
		float coc = _Aperture * abs(fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
		coc = clamp(max(0, coc - _FocalSize),0,1);

		return lerp(float4(tex2D(_MainTex, i.uv).xyz,coc), coc, _Debug);
	}

	// Samples the radius of the CoC for the fragments behind the focus plane.
	float4 fragBackCoC(v2f_img i) : COLOR
	{
		float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
		float coc = _Aperture * (fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
		coc = clamp(max(0, coc - _FocalSize),0,1);

		return float4(tex2D(_MainTex, i.uv).xyz,coc);
	}

	// Samples the radius of the CoC for the fragments in front of the focus plane.
	float4 fragFrontCoC(v2f_img i) : COLOR
	{
		float fragDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
		float coc = -_Aperture * (fragDepth - _FocusDepth) / (fragDepth + 1e-5f);
		coc = clamp(max(0, coc - _FocalSize),0,1);

		return float4(tex2D(_MainTex, i.uv).xyz,coc);
	}

	// Take four samples and weight them acording to its CoC radii.
	float4 fragDownsample(v2f_img i) : COLOR
	{
		float4 sample0 = tex2D(_MainTex, i.uv.xy + 0.75 * _MainTex_TexelSize.xy);
		float4 sample1 = tex2D(_MainTex, i.uv.xy - 0.75 * _MainTex_TexelSize.xy);
		float4 sample2 = tex2D(_MainTex, i.uv.xy + 0.75 * _MainTex_TexelSize.xy * float2(1,-1));
		float4 sample3 = tex2D(_MainTex, i.uv.xy - 0.75 * _MainTex_TexelSize.xy * float2(1,-1));

		float4 weights = float4(sample0.a, sample1.a, sample2.a, sample3.a);
		float sumWeights = dot(weights, 1);

		float4 color = (sample0*weights.x + sample1*weights.y + sample2*weights.z + sample3*weights.w);

		float4 outColor = tex2D(_MainTex, i.uv);
		if (outColor.a * sumWeights * 8.0 > 1e-5f) outColor.rgb = color.rgb / sumWeights;

		return outColor;
	}

	// Blur the downsampled images using a Poisson Disks filter to achieve good blurring quality.
	float4 fragBlur(v2f_img i) : COLOR
	{
		float4 color = tex2D(_MainTex, i.uv);
		float weights = 1.0;

		[unroll(16)]
		for (float x = 0; x < 32; x += 2)
		{
			// Extends the radii of the disks based on _MaxBlurDistance
			float2 sampleUV = i.uv + float2(_PoissonDisks[x], _PoissonDisks[x + 1]) * _MainTex_TexelSize.xy * _MaxBlurDistance;
			float4 value = tex2D(_MainTex, sampleUV);
			// Add the weighted sample
			color += value * value.a;
			weights += value.a;
		}

		// Normalize the final color.
		color = color / weights;
		return color;
	}

	// Samples both the front and back blurred images and composites the final image from back to front.
	float4 fragFinal(v2f_img i) : COLOR
	{
		float4 centerTap = tex2D(_MainTex, i.uv.xy);

		float4 blurB = tex2D(_downsampledBlurredB, i.uv.xy);
		// Lerp between the sharp image and back blurred image averaging the CoC radii to avoid upsampling artifacts.
		float4 backBlurred = lerp(centerTap, blurB, (blurB.a + centerTap.a)/2);

		float4 blurF = tex2D(_downsampledBlurredF, i.uv.xy);
		// Lerp between the previously composited image and the front blurred image without averaging them 
		// to allow front object to correctly occlude the ones in the back.
		float4 finalImage = lerp(backBlurred, blurF, blurF.a);

		return finalImage;
	}

#endif // DOF_CG_INCLUDED
