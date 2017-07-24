using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SSAOScript : MonoBehaviour
{

    [SerializeField] Material ssao;
    [SerializeField][Range(0, 1023)] int kernelSize = 64;
    [SerializeField] [Range(1, 8)] int noiseSqrtSize = 4;
    [SerializeField] float kernelLength = 1;
    [SerializeField] bool occlusionOnly = false;
    [SerializeField] bool updateEveryFrame = false;
    [SerializeField] [Range(0, 2)] float intensity;

    int cachedKS = 64;
    int cachedNSS = 4;
    float cachedKL = 1;
    bool cachedOO = false;
    float cachedI = 1;

    Matrix4x4 inverseProjMat;
    Matrix4x4 projMat;

    void Awake()
    {
        Camera cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
        projMat = GL.GetGPUProjectionMatrix(cam.projectionMatrix, true);
        Matrix4x4.Perspective(cam.fieldOfView, cam.aspect, cam.nearClipPlane, cam.farClipPlane);

        inverseProjMat = projMat.inverse;
        ssao.SetMatrix("projMat", projMat);
        ssao.SetMatrix("inverseProjMat", inverseProjMat);

        //set random kernels
        Vector4[] kernel = new Vector4[kernelSize];
        for (int i = 0; i < kernelSize;i++){
            Vector3 newKernel = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(0f, 1f));
            newKernel.Normalize();
            float scale = (float)i / (float)kernelSize;
            scale = Mathf.Lerp(0.1f, 1f, scale * scale);
            kernel[i] = newKernel * scale;
        }
        ssao.SetInt("_KernelSize", kernelSize);
        ssao.SetVectorArray("_Kernel", kernel);

        int noiseSize = noiseSqrtSize * noiseSqrtSize;
        Vector4[] noise = new Vector4[noiseSize];
        for (int i = 0; i < noiseSize;i++){
            noise[i] = new Vector4(Random.Range(-1, 1), Random.Range(-1, 1), 0, 1);
            noise[i].Normalize();
        }
        ssao.SetInt("_NoiseSqrtSize", noiseSqrtSize);
        ssao.SetVectorArray("_Noise", noise);

        ssao.SetFloat("_KernelLength", kernelLength);
        ssao.SetFloat("_Intensity", intensity);

        ssao.SetInt("_OcclusionOnly", occlusionOnly ? 1 : 0);

        cachedKL = kernelLength;
        cachedKS = kernelSize;
        cachedNSS = noiseSqrtSize;
        cachedOO = occlusionOnly;
        cachedI = intensity;
    }

    void Update(){
        if(kernelLength != cachedKL || 
                kernelSize != cachedKS || 
                noiseSqrtSize != cachedNSS || 
                occlusionOnly != cachedOO || 
                intensity != cachedI ||
                updateEveryFrame)
            Awake();
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, ssao);
    }

}
