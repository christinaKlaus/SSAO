using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostprocessingScript : MonoBehaviour {

	[SerializeField] Material ssao;
	[SerializeField] Material blur;

	Matrix4x4 inverseProjMat;

	void Start () {
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
		inverseProjMat = GL.GetGPUProjectionMatrix(GetComponent<Camera>().projectionMatrix, false).inverse;
		ssao.SetMatrix("inverseProjMat", inverseProjMat);
	}
	
	void OnRenderImage(RenderTexture source, RenderTexture destination){
		//RenderTexture temp = RenderTexture.GetTemporary(source.width, source.height, source.depth, source.format);
		Graphics.Blit(source, destination, ssao);
		
		//Graphics.Blit(temp, destination, blur);
	}

}
