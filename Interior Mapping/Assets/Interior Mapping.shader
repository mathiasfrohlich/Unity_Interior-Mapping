Shader "Custom/Interior Mapping" {
	Properties {
		//Standard UNITY_5 Variables --------
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		//-----------------------------------
		_ceilingTexture ("Ceiling Texture (RGB)", 2D) = "white" {}
		_wallFrequencies ("Wall Frequencie", Vector) = (1,1,1)

		// _Cube ("Cubemap", CUBE) = "" {}
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 4.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldPos;
			float4 screenPos;
			float3 objPos;
			float4 cameraPosition;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		
		sampler2D	_ceilingTexture;
   		float3		_wallFrequencies;
	    float3		cameraPosition;		//object space
		samplerCUBE _Cube;
		 void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.objPos = (float3)v.vertex;
        }
		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			
			
		//get the vector from camera to surface
		//	float3 direction = position - cameraPosition;

		float3 direction = IN.objPos - mul(float3x3(_World2Object), _WorldSpaceCameraPos);// IN.objPos - _WorldSpaceCameraPos;// mul(_World2Object, _WorldSpaceCameraPos);  // IN.viewDir;//mul(modelMatrix, IN.worldPos) - _WorldSpaceCameraPos;
		

		//ceiling height
		float height = (floor(IN.screenPos.y * 2) + step(0, direction.y)) / 2;

		//how much of the ray is needed to get from the cameraPosition to the ceiling
		float rayFraction = (height - _WorldSpaceCameraPos.y) / direction.y;

		//(x,z)-coordinate of intersection with ceiling
		float2 intersection = 4 * (_WorldSpaceCameraPos + rayFraction * direction).xz;

		//use the intersection as the texture coordinates for the ceiling
		o.Albedo = tex2D(_ceilingTexture, intersection).rgb;
			
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
