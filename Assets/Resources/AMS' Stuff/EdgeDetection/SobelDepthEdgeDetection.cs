using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SobelDepthEdgeDetection : MonoBehaviour {

    public float sensitivityDepth = 1.0f;
    public float sensitivityNormals = 1.0f;
    public Color outlineColor;

    public bool debug;

    private Material material;

    //Creates a private material used to the effect
    void Awake()
    {
        material = new Material(Shader.Find("Hidden/SobelDepth"));
    }

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

	//Postprocess the image
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {

        Vector2 sensitivity = new Vector2(sensitivityDepth, sensitivityNormals);
        material.SetVector("_Sensitivity", new Vector4(sensitivity.x, sensitivity.y, 1.0f, sensitivity.y));
        material.SetColor("_EdgeColor", outlineColor);
        material.SetInt("_Debug", debug ? 1 : 0);
        Graphics.Blit(source, destination, material);
    }
}
