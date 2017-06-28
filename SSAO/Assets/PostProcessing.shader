Shader "Postprocessing" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_KernelCount ("Kernel Count", int) = 0
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
			uniform float4x4 ipm;

			float rand(float3 co){
			 	return frac(sin( dot(co.xyz ,float3(12.9898,78.233,45.5432) )) * 43758.5453);
 			}


			float4 frag(v2f_img input) : COLOR {
				float3 kernel [1000];
				for(int i = 0; i < _KernelCount; i++){
					kernel[i] = float3(rand(_Time.xyz) * 2 - 1, rand(_Time.yzw) * 2 - 1, rand(_Time.wxy) * 2 - 1);
					kernel[i] = normalize(kernel[i]);
					float scale = (float)i/ (float)_KernelCount;
					scale = lerp(0.1f, 1.0f, scale * scale);
					kernel[i] *= scale;	
				}				

				float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, input.uv));
				depth = Linear01Depth(depth);
				
				float3 renderSpacePoint = float3(input.uv * 2 - 1, lerp(_ProjectionParams.y, _ProjectionParams.z, depth));
				float3 viewSpacePoint = mul(ipm, renderSpacePoint);
				
				//upcoming: Normale an dem errechneten Punkt

				return viewSpacePoint.xyzz;
			}
			ENDCG
		}
	}
}