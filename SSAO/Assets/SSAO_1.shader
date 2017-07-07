Shader "Postprocessing" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_KernelCount ("Kernel Count", float) = 0
		_KernelSize ("Kernel Size", Range(0, 10)) = 1
		[Toggle]_occlusionOnly("Show only Occlusion", float) = 0
	}
	SubShader {
		
		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _CameraDepthNormalsTexture;
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
			
			void readDepth(float2 screenUV, out float depth, out float3 normal){
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, screenUV),depth,normal);

				//depth = Linear01Depth(depth);
				depth = lerp(_ProjectionParams.y, _ProjectionParams.z, depth);

				normal = normalize(normal);
			}

			float4 frag(v2f_img input) : COLOR {
				float depth;
				float3 normal;
				readDepth(input.uv, depth, normal);
				
				float3 renderSpacePoint = float3(input.uv * 2 - 1, depth);
				//position of the fragment in viewSpace
				float3 viewSpacePoint = mul(inverseProjMat, renderSpacePoint);

				//generate noise to rotate kernel
				float3 noiseRotation = float3(
					rand(input.uv.yxy) * 2 - 1,
					rand(input.uv.yxx) * 2 - 1,
					0
				);
				noiseRotation = normalize(noiseRotation);

				//construct a rotation matrix
				float3 tangent = normalize(noiseRotation - normal * dot(noiseRotation, normal));
				float3 biTangent = cross(normal, tangent);
				float3x3 rotMat = float3x3(tangent, biTangent, normal);

				//check all kernels
				float occlusion = 0;
				for(int i = 0; i < _KernelCount; i++){
					//generate kernel
					float3 kernel = float3(rand(input.uv.xxy * i) * 2 - 1, 
											rand(input.uv.yyx * i) * 2 - 1, 
											rand(input.uv.xyx * i));
					kernel = normalize(kernel);

					//set kernel size, more points closer to the center
					float scale = (float)i/ (float)_KernelCount;
					scale = lerp(0.1f, 1.0f, scale * scale);
					kernel *= scale;

					//rotate the kernel around the matrix and get the viewspace position
					float3 kernelPos = mul(rotMat, kernel);
					kernelPos = kernelPos * _KernelSize + viewSpacePoint;

					float2 kernelScreenPos = (mul(UNITY_MATRIX_P, kernelPos).xy *0.5) + 0.5;

					//get the sample depth
					float kernelDepth;
					float3 tmpNormal;
					readDepth(clamp(kernelScreenPos, 0, 1), kernelDepth, tmpNormal);

					//occlude
					float range = abs(kernelDepth - viewSpacePoint.z) < _KernelSize ? 1 : 0;
					
					occlusion += (kernelDepth <= kernelPos.z ? 1 : 0) * range;
				}
				float darkness = lerp(1, 0, clamp(((float)occlusion / (float)_KernelCount), 0, 1));
				if(_occlusionOnly)
					return darkness.xxxx;
				return darkness * tex2D(_MainTex, input.uv);
			}
			ENDCG
		}
	}
}