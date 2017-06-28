using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostprocessingScript : MonoBehaviour {

	public Material mat;
	Matrix4x4 ipm;

	void Start () {
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
		ipm = GL.GetGPUProjectionMatrix(GetComponent<Camera>().projectionMatrix, false).inverse;
		mat.SetMatrix("ipm", ipm);
	}
	
	void OnRenderImage(RenderTexture source, RenderTexture destination){
		Graphics.Blit(source, destination, mat);
	}

}
