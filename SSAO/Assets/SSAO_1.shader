Shader "Postprocessing/SSAO_1" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		[Toggle]_occlusionOnly("Show only Occlusion", int) = 0
	}
	SubShader {
		
		Cull Off ZWrite Off ZTest Always

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _CameraDepthNormalsTexture;
			uniform float _KernelLength;

			uniform uint _KernelSize = 1024;
			uniform float4 _Kernel[1024];

			uint _NoiseSqrtSize = 8;
			uniform float4 _Noise[8*8];

			uniform uint _OcclusionOnly;
			uniform float4x4 projMat;
			uniform float4x4 inverseProjMat;
			
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			void readDepthNormals(float2 screenUV, out float depth, out float3 normal){
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, screenUV),depth,normal);
				//depth = Linear01Depth(depth);
				depth = lerp(_ProjectionParams.y, _ProjectionParams.z, depth);

				normal = normalize(normal);
			}

			v2f vert (appdata v){
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float4 frag(v2f input) : COLOR {
				float depth;
				float3 normal;
				readDepthNormals(input.uv, depth, normal);

				//render depth
				//return input.uv.xyxy;
				
				float4 renderSpacePoint = float4(input.uv * 2 - 1, depth, 1);
				//position of the fragment in viewSpace
				float4 origin = mul(inverseProjMat, renderSpacePoint);
				origin.z = depth;

				//return origin.xyzy;

				int2 pixelPos = input.uv * _ScreenParams.xy;
				uint noisePos = (pixelPos.x % _NoiseSqrtSize) + (pixelPos.y % _NoiseSqrtSize) * _NoiseSqrtSize;
				float3 noiseRotation = _Noise[noisePos].xyz;

				// shows the index of the noise
				//return (float)noisePos / ((float)_NoiseSqrtSize*(float)_NoiseSqrtSize);

				//construct a rotation matrix
				float3 tangent = normalize(noiseRotation - normal * dot(noiseRotation, normal));
				float3 biTangent = cross(normal, tangent);
				float3x3 rotMat = float3x3(tangent, biTangent, normal);

				//check all kernels
				float occlusion = 0;
				for(uint i = 0; i < _KernelSize; i++){
					
					//rotate the kernel around the matrix and get the viewspace position
					float4 kernelPos = float4(mul(rotMat, _Kernel[i]), 1);
					kernelPos = kernelPos * _KernelLength + origin;

					float4 kernelScreenPos = float4(kernelPos);
					kernelScreenPos = mul(projMat, kernelScreenPos);
					kernelScreenPos.xy /= kernelScreenPos.w;
					kernelScreenPos.xy = (kernelScreenPos.xy + 1)*0.5;
					//return kernelScreenPos.x > 1 || kernelScreenPos.y > 1 ? 1 : 0;
					//return float4((renderSpacePoint.xy+1)/2, 0, 1);

					//get the sample depth
					float kernelDepth;
					float3 tmpNormal;
					readDepthNormals(kernelScreenPos.xy, kernelDepth, tmpNormal);

					//occlude
					float rangeCheck = 1;//abs(origin.z - kernelDepth) < _KernelLength ? 1 : 0;
					
					occlusion += (kernelDepth <= kernelPos.z ? 1 : 0) * rangeCheck;
				}
				float darkness = 1.0 - (occlusion / _KernelSize);
				if(_OcclusionOnly)
					return float4(darkness, darkness, darkness, 1);
				return darkness * tex2D(_MainTex, input.uv);
			}
			ENDCG
		}
	}
}