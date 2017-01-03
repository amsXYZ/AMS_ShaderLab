Shader "Custom/TessSmearSurface" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Tess ("Tessellation", Range(1,32)) = 4
		_Intensity ("Smear intensity", Float) = 1
		_NoiseTex ("Noise", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:disp addshadow tessellate:tessDistance

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 5.0

		#include "UnityCG.cginc"
		#include "Tessellation.cginc"

		struct appdata {
            float4 vertex : POSITION;
            float4 color : COLOR;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        float _Tess;

        float4 tessDistance (appdata v0, appdata v1, appdata v2) {
            float minDist = 10.0;
            float maxDist = 25.0;
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
        }

        sampler2D _NoiseTex;
        float _Intensity;

        void disp (inout appdata v){
        	float noise = tex2Dlod(_NoiseTex, float4(v.texcoord.xy, 0,0));
        	float3 worldNormal = UnityObjectToWorldNormal(v.normal);

        	float dispNormalIntensity = max(0, dot(v.color.xyz, worldNormal));
			float displacement = _Intensity * noise * dispNormalIntensity;

			v.vertex.xyz += float3(mul((float3x3)unity_WorldToObject, displacement * v.color.xyz));
        }

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
