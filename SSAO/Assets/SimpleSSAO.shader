Shader "Postprocessing/SimpleSSAO" {
	Properties{
		//MainTex is the render so far
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader {
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass{
			CGPROGRAM
			//include default unity shader methods
			#include "UnityCG.cginc"

			//use a standart vertex shader for postprocessing
			#pragma vertex vert_img
			//use frag as a fragment shader
			#pragma fragment frag

			//samples in 1 kernel
			#define SAMPLE_COUNT 64
			//size of the width/height of the noise pattern
			#define NOISE_SIZE 4

			//z buffer texture
			sampler2D _CameraDepthTexture;

			//maximum radius of the kernel
			uniform float _KernelRadius = 1;
			//maximum radius of the kernel
			uniform float _DepthFilterThreshold = 1;
			//how actively to actually occlude
			uniform float _AttenuationPower = 1;

			//random kernel samples
			uniform float4 _Samples[SAMPLE_COUNT];
			//random noise values
			uniform float4 _Noise[NOISE_SIZE*NOISE_SIZE];

			//the actual fragment shader
			fixed4 frag (v2f_img input) : SV_Target {
				//get the z distance of the fragment
				float depth = tex2D(_CameraDepthTexture, input.uv);
				depth = Linear01Depth(depth) * _ProjectionParams.z;

				//scale to shrink the kernel as it's further away from the camera
				float scale = _KernelRadius / depth;

				//get the noise vector at the current fragment
				//get the 2d index of the current fragment
				int2 fragIndex = input.uv * _ScreenParams.xy;
				//use uint because it makes modulo use faster
				uint noiseSize = NOISE_SIZE;
				//get the index in the noise array
				uint noiseIndex = (fragIndex.x % noiseSize) + 
						(fragIndex.y % noiseSize) * noiseSize;
				//debug that visualises the noise index
				//return noiseIndex / (float)(NOISE_SIZE*NOISE_SIZE);
				//get the noise from the array
				float4 noise = _Noise[noiseIndex];

				//prepare the variable that records the occlusion of the fragment
				float occlusion = 0;
				//iterate over all samples of the kernel
				for(int i=0; i < SAMPLE_COUNT; i++) {
					//randomize the sample to minimize banding
					float4 randomizedSample = reflect(_Samples[i], noise);
					
					//offset in screenspace
					float2 uvOffset = randomizedSample.xy * scale;
					//the depth of the point tested
					float sampleTestDepth = depth - (randomizedSample.z * _KernelRadius);
					
					//get the depth of the sample in the buffer
					float sampleBufferDepth = tex2D(_CameraDepthTexture, input.uv + uvOffset);
					sampleBufferDepth = Linear01Depth(sampleBufferDepth) * _ProjectionParams.z;

					//get the difference from the test depth to the actual depth in the buffer
					float sampleTestToBufferDifference = sampleTestDepth - sampleBufferDepth;

					float depthTest = abs(depth - sampleBufferDepth) > _DepthFilterThreshold || depth == _ProjectionParams.z ? 0 : 1;
					occlusion += ((sampleTestToBufferDifference>0)?1:0) * depthTest;
				}
				//get the occlusion to a scale between 0 and 1
				occlusion /= SAMPLE_COUNT;
				//write the darkness to the screen more occlusion = less light, start with 1.5 not 1 because 
				return saturate(1 - (occlusion - 0.5) * 2);
			}
			ENDCG
		}
		
		//save the current screen (AO result) to a texture
		GrabPass{ "_UnblurredAO" }

		Pass{
			CGPROGRAM
			//include default unity shader methods
			#include "UnityCG.cginc"

			//use a standart vertex shader for postprocessing
			#pragma vertex vert_img
			//use frag as a fragment shader
			#pragma fragment frag
			//size of the width/height of the noise pattern
			#define NOISE_SIZE 4

			//the Texture the AO result is saved into
			sampler2D _UnblurredAO;
			//original render before SSAO (from the rendertexture)
			sampler2D _MainTex;

			fixed4 frag(v2f_img input) : SV_Target {
				//flip the uv for the grabpass otherwise it would be the wrong way around
				float2 grabPassUV = float2(input.uv.x, 1 - input.uv.y);
				//_ScreenParams z and 2 are 1 + 1/width and 1 + 1/height so by subtracting 1 we get the texelsize in uv space
				float2 texelSize = _ScreenParams.zw - 1;
				//get the offset of the raster so it's around the fragment
				float2 noiseRasterOffset = -(float)NOISE_SIZE/2 + 0.5;

				//prepare a variable to get the sum of all evaluated pixels
				float blurredDarkness = 0;
				//iterate over a area as big as the noise pattern, this way the noise will completely vanish
				for(int i=0;i<NOISE_SIZE;i++){
					for(int j=0;j<NOISE_SIZE;j++){
						//get the uv offset to the current pixel where we want to get the pixel from
						float2 offset = (float2(i, j) + noiseRasterOffset) * texelSize;
						//add the darkness at the pixel to our sum (only red because it's greyscale anyways)
						blurredDarkness += tex2D(_UnblurredAO, grabPassUV + offset).r;
					}
				}
				//get the blurred darkness to a scale from 0 to 1
				blurredDarkness /= (NOISE_SIZE*NOISE_SIZE);
				//multiply the blurred value with the original render
				float4 result = tex2D(_MainTex, input.uv) * blurredDarkness;
				return result;
			}
			ENDCG
		}
	}
}