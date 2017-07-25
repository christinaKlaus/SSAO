using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//make the shader work without hitting 'play'
[ExecuteInEditMode]
public class SimpleSSAO : MonoBehaviour {
	[SerializeField] Material ssao;
    [SerializeField] float radius;
    [SerializeField] float threshold;

    const int noise_size = 4;
    const int sample_count = 64;

    void Start () {
        //generate random vectors inside of a ball with a radius of 1 with more samples towards the middle
        Vector4[] samples = new Vector4[sample_count];
        for (int i = 0; i < sample_count;i++){
            Vector3 s = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f));
            s.Normalize();
            float scale = (float)i / (float)sample_count;
            //get the power of 2 so there are more samples towards the middle also start with 0.1 because being too close to the center leads to fallse positives
            scale = Mathf.Lerp(0.1f, 1f, scale * scale);
            s *= scale;
            samples[i] = new Vector4(s.x, s.y, s.z, 1);
        }
        ssao.SetVectorArray("_Samples", samples);

        //jst generate random vectors with the length of 1 to reflect off
		Vector4[] noise = new Vector4[noise_size * noise_size];
        for (int i = 0; i < noise_size * noise_size; i++){
            Vector3 n = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f));
            n.Normalize();
            noise[i] = new Vector4(n.x, n.y, n.z, 1);
        }
        ssao.SetVectorArray("_Noise", noise);

        //set the other uniform variables for the shader
        ssao.SetFloat("_KernelRadius", radius);
        ssao.SetFloat("_DepthFilterThreshold", threshold);
    }

    //this is every time after a image is rendered
	void OnRenderImage(RenderTexture source, RenderTexture destination){
        //put the texture from source to destination using the material ssao
        Graphics.Blit(source, destination, ssao);
    }
}
