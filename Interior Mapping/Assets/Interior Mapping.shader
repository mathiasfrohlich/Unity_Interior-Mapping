Shader "Custom/Interior Mapping" {
	Properties {
		_cameraPosition ("Camera position", Vector) = (1.939751,0.1998241,-4.33008)
		_wallFrequencies ("Wall freq", Vector) = (1,1,1)
		
		_ceilingTexture  ("Ceiling texture", 2D) = "white" {}
		_floorTexture ("Floor texture", 2D) = "red" {}
//
//		_diffuseTexture ("Diffuse texture", 2D) = "green" {}	 		
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
				
				OUT.pos = mul (UNITY_MATRIX_MVP, v.vertex) ;
				OUT.uv = v.texcoord;
				OUT.positionCopy = float3(v.vertex);

				return OUT;
			}

			
			sampler2D _ceilingTexture;
			sampler2D _floorTexture;
			
			float4 frag (INPUT IN) : COLOR
			{
				//Vector from camera to intersection point
				float3 direction = IN.positionCopy - _cameraPosition;
		
				//ceiling height
				float3 height = floor(IN.positionCopy) / _wallFrequencies;
				
				float3 rayFractions = (height - _cameraPosition.y) / direction.y;
//				float2 intersectionXY = (_cameraPosition + rayFractions.z * direction).xy;
				float2 intersectionXZ = (_cameraPosition + rayFractions.y * direction).xz;
//				float2 intersectionZY = (_cameraPosition + rayFractions.x * direction).zy;
				
				float4 ceilingColour = tex2D(_ceilingTexture, intersectionXZ);
				float4 floorColour = tex2D(_floorTexture, intersectionXZ);
				
				float4 verticalColour = lerp(floorColour, ceilingColour, step(0, direction.y));

				
				return verticalColour;
			}

			ENDCG   
        }
	} 
	FallBack "Diffuse"
}
