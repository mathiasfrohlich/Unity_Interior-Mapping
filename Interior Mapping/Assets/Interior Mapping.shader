Shader "Custom/Interior Mapping" {
	Properties {
		_cameraPosition ("Camera position - don't touch", Vector) = (0,0,0)
		_wallFrequencies ("Wall freq", Vector) = (1,1,1)
		
		_ceilingTexture  ("Ceiling texture", 2D) = "white" {}
		_floorTexture ("Floor texture", 2D) = "red" {}
		
		_wallTextureXY ("WallXY texture", 2D) = "green"{}
		_wallTextureZY ("WallZY texture", 2D) = "blue"{}
		
		_furniturePlane ("Furniture plane", 2D) = "blue"{}

//
		_diffuseTexture ("Diffuse texture", 2D) = "green" {}	
 		
	}
	SubShader {
		 Pass {
		 
			 CGPROGRAM
			
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			struct INPUT {
			
				float4 pos:	SV_POSITION;
				float2 uv:TEXCOORD0;
				float3 positionCopy:TEXCOORD1;

			};

			float3 _cameraPosition;
			float3 _wallFrequencies;
			
			INPUT vert (appdata_base v)
			{
				INPUT OUT;
				
				OUT.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				OUT.uv = v.texcoord;
				OUT.positionCopy = v.vertex;

				return OUT;
			}

			
			sampler2D _ceilingTexture;
			sampler2D _floorTexture;
			sampler2D _wallTextureXY;
			sampler2D _wallTextureZY;
			sampler2D _diffuseTexture;
			
			sampler2D _furniturePlane;

			
			float4 frag (INPUT IN) : COLOR
			{
				//Vector from camera to intersection point
				float3 direction = IN.positionCopy - _cameraPosition;
		
				//ceiling height
				//float3 height = floor(IN.positionCopy) / _wallFrequencies;
				float3 height = floor(IN.positionCopy * _wallFrequencies ) / _wallFrequencies;
				//Walls
				float3 walls = ( step(float3(0,0,0), direction)) / _wallFrequencies;
				
				//how much of the ray is needed to get from the cameraPosition to the ceiling
				//float3 rayFractions = (height - _cameraPosition.y) / direction.y;
				float3 rayFractions = ((walls + height) - _cameraPosition) / direction;
				
				//finding the wall closest to camera
				float xORz = step(rayFractions.x, rayFractions.z);
				float rayFraction_xORz = lerp(rayFractions.z, rayFractions.x, xORz);
				float xzORy = step(rayFraction_xORz, rayFractions.y);
				
				//texture-coordinates of intersection with ceiling
				float2 intersectionXZ = (_cameraPosition + rayFractions.y * direction).xz;
				float2 intersectionXY = (_cameraPosition + rayFractions.z * direction).xy;
				float2 intersectionZY = (_cameraPosition + rayFractions.x * direction).zy;
				
				intersectionXY = (intersectionXY - height.xy) * _wallFrequencies.xy;
				intersectionZY = (intersectionZY - height.zy) * _wallFrequencies.zy;
				
				//use the intersection as the texture coordinates for the ceiling, floor and walls
				float4 ceilingColour = tex2D(_ceilingTexture, intersectionXZ);
				float4 floorColour = tex2D(_floorTexture, intersectionXZ);
				
				float4 wallColorsXY = tex2D(_wallTextureXY, intersectionXY);
				float4 wallColorsZY = tex2D(_wallTextureZY, intersectionZY);
				
				float4 furniturePlaneColor = tex2D(_furniturePlane, (intersectionXY));

				
				//choose between ceiling and floor
				float4 verticalColour = lerp(floorColour, ceilingColour, step(0, direction.y));
				//choose between back or side walls
				float4 interiorColor  = lerp(wallColorsXY, wallColorsZY, xORz);
				
				
				float4 interiorColor_furniture  = lerp( interiorColor, furniturePlaneColor, furniturePlaneColor.a);

				
				interiorColor = lerp(verticalColour, interiorColor_furniture, xzORy);
				
				
				
				//choose between wall or outcome of ceiling/floor
				//interiorColor2 = lerp(furniturePlaneColor, interiorColor2, xzORy);



				//look up the color of the vertex in the diffuse texture 
				float4 diffuseColour = tex2D(_diffuseTexture, IN.uv);
				
				//blend colors from diffuse wall texture and interior
				return lerp(diffuseColour, interiorColor, diffuseColour.a);
				
				//return verticalColour;
				//return interiorColor;
			}

			ENDCG   
        }
	} 
	FallBack "Diffuse"
}
