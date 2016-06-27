using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DesaturateEffect : MonoBehaviour {

    [Range(0, 1)]
    public float intensity;

    private Material material;

    //Creates a private material used to the effect
    void Awake()
    {
        material = new Material(Shader.Find("Hidden/Desaturate"));
    }

	//Postprocess the image
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {

        material.SetFloat("_bwBlend", intensity);
        Graphics.Blit(source, destination, material);
    }
}
