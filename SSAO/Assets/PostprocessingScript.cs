using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostprocessingScript : MonoBehaviour {

	[SerializeField] Material ssao;

	Matrix4x4 inverseProjMat;

	void Awake () {
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;
		inverseProjMat = GL.GetGPUProjectionMatrix(GetComponent<Camera>().projectionMatrix, false).inverse;
		ssao.SetMatrix("inverseProjMat", inverseProjMat);
	}
	
	void OnRenderImage(RenderTexture source, RenderTexture destination){
		Graphics.Blit(source, destination, ssao);
	}
}
