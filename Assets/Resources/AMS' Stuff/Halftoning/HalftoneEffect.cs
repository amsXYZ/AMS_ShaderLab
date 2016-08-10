using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class HalftoneEffect : MonoBehaviour {

    [Range(1, 1000)]
    public float frequency;
    public bool BW;
    private Material material;

    //Creates a private material used to the effect
    void Awake()
    {
        material = new Material(Shader.Find("Hidden/Halftone"));
    }

	//Postprocess the image
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        /*if(radius == 0)
        {
            Graphics.Blit(source, destination);
            return;
        }*/

        material.SetFloat("_frequency", frequency);
        material.SetVector("_uDims", new Vector4(Screen.width, Screen.height, 1.0f / Screen.width, 1.0f / Screen.height));
        material.SetInt("_BW", BW ? 1 : 0);
        Graphics.Blit(source, destination, material);
    }
}
