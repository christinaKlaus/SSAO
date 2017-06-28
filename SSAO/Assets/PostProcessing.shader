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


			float4 frag(v2f_img i) : COLOR {
				float3 kernel [1000];
				for(int kernelIndex = 0, kernelIndex < _KernelCount; kernelIndex++){
					kernel[kernelIndex] = float3(1,1,1);
				}
				
				float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv));
				//depth = pow(Linear01Depth(depth), _DepthLevel);
				return depth;
			}
			ENDCG
		}
	}
}