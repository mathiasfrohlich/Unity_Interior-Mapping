
Shader "buildingshader" {
	Properties {
		_uvMultiplier ("UV multiplier", Vector) = (1,1,0)
		_cameraPosition ("Camera position", Vector) = (1.939751,0.1998241,-4.33008)
		_wallFrequencies ("Wall freq", Vector) = (1,1,1)
		
		_ceilingTexture  ("Ceiling texture", 2D) = "white" { TexGen EyeLinear }
		_floorTexture ("Floor texture", 2D) = "red" { TexGen EyeLinear }
		_wallXYTexture ("wallXY texture", 2D) = "black" { TexGen EyeLinear } 
		_wallZYTexture ("wallZY texture", 2D) = "green" { TexGen EyeLinear } 
		_diffuseTexture ("Diffuse texture", 2D) = "green" { TexGen EyeLinear }	 
		_noiseTexture( "Noise texture", 2D) = "green" { TexGen EyeLinear }
		
		_CubeTex("Cubemap day", CUBE) = "" { TexGen CubeReflect}
		_CubeTex2("Cubemap night", CUBE) = "" { TexGen CubeReflect}		
	}
	SubShader {
		 Pass {
		 
			 CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members lighting)
#pragma exclude_renderers d3d11 xbox360
			
			#pragma target 3.0
			#pragma exclude_renderers xbox360
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			struct v2f {
			
				float4 pos:	SV_POSITION;
				float2 uv:TEXCOORD0;
				float3 positionCopy:TEXCOORD1;
				float3 reflection:TEXCOORD2;
				float4 lighting;
			};

			float3 _uvMultiplier;
			float3 _cameraPosition;
			float3 _wallFrequencies;
			float _lightThreshold;
			
			v2f vert (appdata_base v)
			{
				v2f o;
				
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex) ;
				o.uv = v.texcoord * float2(_uvMultiplier);
				o.positionCopy = float3(v.vertex);
								
				float3 cameraPosition = _WorldSpaceCameraPos;
				
				float4 worldPosition = mul(_Object2World, v.vertex);
				float3 worldNormal = mul(float3x3(_Object2World), v.normal);
				
				o.reflection = reflect(worldPosition - cameraPosition , worldNormal);
				
				// Calculate lighting on the exterior of the building with a hard-coded directed light.
				float lightStrength = dot(v.normal, float3(0.5, 0.33166, 0.8));
				o.lighting = saturate(lightStrength) * float4(1, 1, 0.9, 1) * (1-_lightThreshold);
				
				// Add some ambient lighting.
				o.lighting += float4(0.3, 0.3, 0.4, 1);
				
				return o;
			}

			
			sampler2D _ceilingTexture;
			sampler2D _floorTexture;
			sampler2D _wallXYTexture;
			sampler2D _wallZYTexture;
			sampler2D _diffuseTexture;
			sampler2D _noiseTexture;
			samplerCUBE _CubeTex;
			samplerCUBE _CubeTex2;
			
			half4 frag (v2f i) : COLOR
			{
				
				//position in object space
				float3 direction = i.positionCopy - _cameraPosition;
		
				//multiply by 0.999 to prevent last wall from beeing displayed. Fix this?
				float3 corner = floor(i.positionCopy *_wallFrequencies * 0.999); 
				float3 walls = corner + step(float3(0, 0, 0), direction);
				walls /= _wallFrequencies;
				corner /= _wallFrequencies;
				
				float3 rayFractions = (float3(walls.x, walls.y,walls.z) - _cameraPosition) / direction;
				float2 intersectionXY = (_cameraPosition + rayFractions.z * direction).xy;
				float2 intersectionXZ = (_cameraPosition + rayFractions.y * direction).xz;
				float2 intersectionZY = (_cameraPosition + rayFractions.x * direction).zy;
				
				float4 ceilingColour = tex2D(_ceilingTexture, intersectionXZ);
				float4 floorColour = tex2D(_floorTexture, intersectionXZ);
				float4 verticalColour = lerp(floorColour, ceilingColour, step(0, direction.y));
				
				//random texture on wall xy
				float zNoise = tex2D(_noiseTexture, float2(corner.z/64,0)).r;
				float yNoise = tex2D(_noiseTexture, float2(corner.y/64 + zNoise,0)).r;
				float noiseXY = tex2D(_noiseTexture, float2(corner.x/64 + yNoise,0)).r;
			
				noiseXY = floor(noiseXY * 4) / 4;
				float2 atlasIndexXY;
				atlasIndexXY[0] = floor(noiseXY * 2) / 2;
				atlasIndexXY[1] = (noiseXY - atlasIndexXY[0]) * 2;
				
				//put the intersection into room space, so that it comes within [0, 1]
				intersectionXY = (intersectionXY - corner.xy) * _wallFrequencies.xy;
				
				//use the texture coordinate to read from the correct texture in the atlas
				float4 wallXYColour = 0.8 * tex2D(_wallXYTexture, atlasIndexXY + intersectionXY / 2);
				
				//random texture on wall ZY
				float zNoise2 = tex2D(_noiseTexture, float2(corner.z/64,0)).g;
				float yNoise2 = tex2D(_noiseTexture, float2(corner.y/64 + zNoise2,0)).g;
				float noiseZY = tex2D(_noiseTexture, float2(corner.x/64 + yNoise2,0)).g;
				float2 atlasIndexZY;
				atlasIndexZY[0] = floor(noiseZY * 2) / 2;
				atlasIndexZY[1] = 0;//(noiseZY - atlasIndexZY[0]) * 2;
				
				//put the intersection into room space, so that it comes within [0, 1]
				intersectionZY = (intersectionZY - corner.zy) * _wallFrequencies.zy;
				
				//use the texture coordinate to read from the correct texture in the atlas
				float4 wallZYColour = 0.8 * tex2D(_wallZYTexture, atlasIndexZY + intersectionZY / 2);
		
				//decide wich wall is closest to camera
				float xVSz = step(rayFractions.x, rayFractions.z);
				float4 interiorColour = lerp(wallXYColour, wallZYColour, xVSz);
				float rayFraction_xVSz = lerp(rayFractions.z, rayFractions.x, xVSz);
				
				//calculate variation in the lighting per room
				float3 noises = float3(
					tex2D(_noiseTexture, float2(corner.x, corner.y)/64).r,
					tex2D(_noiseTexture, float2(corner.z, corner.x)/64).r,
					tex2D(_noiseTexture, float2(corner.y, corner.z)/64).r
				);
				
				float lightVariation = step((noises.x + noises.y + noises.z)/3, _lightThreshold*0.6f)* 0.3 + noises.x;
				
				float xzVSy = step(rayFraction_xVSz, rayFractions.y);
				//floor/ceiling or walls
				interiorColour = lerp(verticalColour, interiorColour, xzVSy)* lightVariation;
				
				//blend colors
				float4 diffuseColour = tex2D(_diffuseTexture, i.uv);
				float4 wallColour = diffuseColour * i.lighting;
				float4 cubeColour = lerp(float4(0,0,0,1), lerp(texCUBE(_CubeTex, i.reflection ),texCUBE(_CubeTex2, i.reflection ),_lightThreshold),1.0F);
				float4 windowColour = cubeColour + interiorColour;
				
				return lerp(wallColour, windowColour, diffuseColour.a);
				
			}

			ENDCG   
        }
	} 
}
