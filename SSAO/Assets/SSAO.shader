Shader "Postprocessing/SSAO" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_KernelCount ("Kernel Count", float) = 0
		_KernelSize ("Kernel Size", Range(0, 1)) = 1
		_RangeTest ("Range Test", Range(0, 10)) = 1
		[Toggle]_occlusionOnly("Show only Occlusion", float) = 0
	}
	SubShader {
		
		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _CameraDepthTexture;
			uniform fixed _DepthLevel;
			uniform int _KernelCount;
			uniform float _KernelSize;
			uniform float _RangeTest;
			float _occlusionOnly;
			uniform float4x4 inverseProjMat;

			float rand(float3 co){
				co *= _Time.w;
			 	return frac(sin( dot(co.xyz ,float3(12.9898,78.233,45.5432) )) * 43758.5453);
 			}
			
			float readDepth(float2 screenUV){
				float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, screenUV));
				depth = Linear01Depth(depth);
				depth = lerp(_ProjectionParams.y, _ProjectionParams.z, depth);
				return depth;
			}

			float4 frag(v2f_img input) : COLOR {
				float depth = readDepth(input.uv);
				
				float3 renderSpacePoint = float3(input.uv * 2 - 1, depth);
				float3 viewSpacePoint = mul(inverseProjMat, renderSpacePoint);

				float occlusion = 0;
				for(int i = 0; i < _KernelCount; i++){
					float3 kernel = float3(rand(input.uv.xxy * i) * 2 - 1, 
										   rand(input.uv.yyx * i) * 2 - 1, 
										   rand(input.uv.xyx * i) * 2 - 1);
					kernel = normalize(kernel);
					float scale = (float)i/ (float)_KernelCount;
					scale = lerp(0.1f, 1.0f, scale * scale);
					kernel *= scale * _KernelSize * _RangeTest;

					float3 kernelPos = viewSpacePoint + kernel;
					float2 kernelScreenPos = (mul(UNITY_MATRIX_P, kernelPos).xy + 2) / 4;
					float kernelDepth = readDepth(clamp(kernelScreenPos, 0, 1));
					if(kernelPos.z > kernelDepth){
						float range = lerp(1, 0,abs(kernelDepth - kernelPos.z) / _RangeTest);
						occlusion += 1 * range;
					}
				}
				float darkness = lerp(1, 0, clamp(((float)occlusion / (float)_KernelCount - 0.5) * 2, 0, 1));
				if(_occlusionOnly)
					return darkness;
				return darkness * tex2D(_MainTex, input.uv);
			}
			ENDCG
		}
	}
}