Shader "Postprocessing" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_KernelCount ("Kernel Count", int) = 0
		_KernelSize ("Kernel Size", Range(0, 1)) = 1
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
			uniform float4x4 inverseProjMat;

			float rand(float3 co){
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

				float3 kernel [1000];
				int hittingKernels = 0;
				for(int i = 0; i < _KernelCount; i++){
					kernel[i] = float3(rand(input.uv.xxy) * 2 - 1, rand(input.uv.yyx) * 2 - 1, rand(input.uv.xyx) * 2 - 1);
					kernel[i] = normalize(kernel[i]);
					float scale = (float)i/ (float)_KernelCount;
					scale = lerp(0.1f, 1.0f, scale * scale);
					kernel[i] *= scale * _KernelSize;

					float3 kernelPos = viewSpacePoint + kernel[i];
					//float2 kernelScreenPos = (mul(UNITY_MATRIX_P, kernelPos).xy + 1) / 2;
					float2 kernelScreenPos = (kernelPos.xy + 1) / 2;
					if(kernelPos.z > readDepth(kernelScreenPos)){
						hittingKernels += 1;
					}
				}
				float darkness = 1 - (float)hittingKernels / (float)_KernelCount + 0.5f;
				
				//upcoming: Normale an dem errechneten Punkt
				return darkness.xxxx;
				return renderSpacePoint.xyzz;
			}
			ENDCG
		}
	}
}