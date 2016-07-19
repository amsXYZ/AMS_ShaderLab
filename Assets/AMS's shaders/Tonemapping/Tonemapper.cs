using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class Tonemapper : MonoBehaviour {

    enum TonemappingMethod { LINEAR, REINHARD, HPDUIKER, HEJL_DAWSON, HABLE, ACES};

    [SerializeField]
    private TonemappingMethod method;

    [SerializeField]
    [Range(0,16)]
    private float exposure = 1;

    private Material material;
    [SerializeField]
    private Texture filmLut;

    void Awake()
    {
        material = new Material(Shader.Find("Hidden/Tonemapper"));
        //TODO Find filmlut by assets, don't serialize it
    }

    // Called by the camera to apply the image effect
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetFloat("_Exposure", exposure);
        if (method == TonemappingMethod.HPDUIKER) material.SetTexture("FilmLut", filmLut);
        Graphics.Blit(source, destination, material, (int)method);
    }
}
