﻿Shader "Postprocessing/SSAO_1" {
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

			sampler2D _CameraDepthNormalsTexture;
			uniform float _KernelLength;

			uniform uint _KernelSize = 1024;
			uniform float4 _Kernel[1024];

			uint _NoiseSqrtSize = 8;
			uniform float4 _Noise[8*8];

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
				
				normal *= -1;
				//return normal.xyzz;

				//render depth
				//return input.uv.xyxy;
				
				float4 screenSpacePos = float4(input.uv * 2 - 1, depth, 1);
				//position of the fragment in viewSpace
				float4 viewSpacePos = mul(inverseProjMat, screenSpacePos);
				//viewSpacePos.z = depth;

				//return viewSpacePos.xyxy;
				//return abs(length(viewSpacePos)-2) < 1 ? 1 : 0;

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
					float4 kernelPos = float4(mul(rotMat, _Kernel[i]) * _KernelLength + normal * 0.2, 1);
					kernelPos = kernelPos + viewSpacePos;

					float4 kernelScreenPos = mul(projMat, kernelPos);
					//kernelScreenPos.xy /= kernelScreenPos.w;
					kernelScreenPos.xy = (kernelScreenPos.xy + 1) / 2;
					//return kernelScreenPos.x > 1 || kernelScreenPos.y > 1 ? 1 : 0;
					//return float4(kernelScreenPos.xy,0, 1);

					//get the sample depth
					float kernelPosDepthBufferValue;
					float3 tmpNormal;
					readDepthNormals(kernelScreenPos.xy, kernelPosDepthBufferValue, tmpNormal);

					//return float4(screenSpacePos.xy,0,1);
					//return float4(kernelPosDepthBufferValue.xxx, 1);

					//occlude
					float rangeCheck =  abs(depth - kernelPosDepthBufferValue) < _KernelLength ? 1 : 0;
					rangeCheck = (depth >= _ProjectionParams.z) ? 0 : rangeCheck;
					
					occlusion += (kernelPosDepthBufferValue <= kernelScreenPos.z ? 1 : 0) * rangeCheck;
				}
				float darkness = 1.0 - (occlusion / _KernelSize);
				return float4(darkness, darkness, darkness, 1);
			}
			ENDCG
		}
		/*
		GrabPass{ "_UnBlurred" }
		
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _UnBlurred;
			sampler2D _MainTex;
			uint _NoiseSqrtSize = 8;
			uint _OcclusionOnly = false;
			uniform float _Intensity = 1;
			
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 grab_uv : TEXCOORD1;
			};

			v2f vert (appdata v){
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.grab_uv = v.uv;
				o.grab_uv.y = 1 - o.grab_uv.y;
				return o;
			}

			float4 frag(v2f input) : COLOR {
				float2 texelSize = _ScreenParams.zw -1;
				float result = 0;
				float offsetStart = -(float)_NoiseSqrtSize * 0.5 + 0.5;
				for(uint i=0;i<_NoiseSqrtSize*_NoiseSqrtSize;i++){
					int2 index = int2(i%_NoiseSqrtSize, floor(i/_NoiseSqrtSize));
					float2 offset = (index + offsetStart) * texelSize;
					result += tex2D(_UnBlurred, input.grab_uv + offset).r;
				}
				float darkness = result / (_NoiseSqrtSize * _NoiseSqrtSize);
				if(_OcclusionOnly)
					return darkness;
				//darkness = lerp(1, darkness, _Intensity);
				darkness = pow(darkness, _Intensity);
				return darkness * tex2D(_MainTex, input.uv);
			}
			ENDCG
		}//*/
	}
}