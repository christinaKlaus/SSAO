using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SimpleSSAO : MonoBehaviour {
	[SerializeField] Material ssao;
    [SerializeField] float radius;
    [SerializeField] float threshold;
    [SerializeField] float attenuation;

    const int noise_size = 4;
    const int sample_count = 64;

    void Start () {
        Vector4[] samples = new Vector4[sample_count];
        for (int i = 0; i < sample_count;i++){
            Vector3 s = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f));
            s.Normalize();
            float scale = (float)i / (float)sample_count;
            scale = Mathf.Lerp(0.1f, 1f, scale * scale);
            s *= scale;
            samples[i] = new Vector4(s.x, s.y, s.z, 1);
        }
        ssao.SetVectorArray("_Samples", samples);

		Vector4[] noise = new Vector4[noise_size * noise_size];
        for (int i = 0; i < noise_size * noise_size; i++)
        {
            Vector3 n = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f));
            n.Normalize();
            noise[i] = new Vector4(n.x, n.y, n.z, 1);
        }
        ssao.SetVectorArray("_Noise", noise);

        ssao.SetFloat("_KernelRadius", radius);
        ssao.SetFloat("_DepthFilterThreshold", threshold);
        ssao.SetFloat("_AttenuationPower", attenuation);
    }
	
	void Update(){
        Start();
    }

	void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, ssao);
    }
}
