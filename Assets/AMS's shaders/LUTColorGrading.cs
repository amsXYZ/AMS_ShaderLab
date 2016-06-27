using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class LUTColorGrading : MonoBehaviour {

    public Texture2D LUT;

    private Texture3D LUT3D;
    private Material material;

    //Creates a private material used to the effect
    void Awake()
    {
        material = new Material(Shader.Find("Hidden/LUTColorGrading"));
    }

    void OnValidate()
    {
        if (LUT)
        {
            int dim = LUT.height;
            if (LUT.width != dim * dim) Debug.LogError("This LUT hasn't the right size (x,x*x)");
            else
            {
                Color[] sourceTexture = LUT.GetPixels();
                Color[] depthTextures = new Color[dim * dim * dim];

                for (int i = 0; i < dim; i++)
                {
                    for (int j = 0; j < dim; j++)
                    {
                        for (int k = 0; k < dim; k++)
                        {
                            int j_ = dim - j - 1;
                            depthTextures[i + j * dim + k * dim * dim] = sourceTexture[k * dim + i + j_ * dim * dim];
                        }
                    }
                }

                if (LUT3D)
                    DestroyImmediate(LUT3D);

                LUT3D = new Texture3D(dim, dim, dim, TextureFormat.ARGB32, false);
                LUT3D.SetPixels(depthTextures);
                LUT3D.Apply();
            }
        }
    }

    // Called by the camera to apply the image effect
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!LUT3D)
        {
            Graphics.Blit(source, destination);
            return;
        }

        LUT3D.wrapMode = TextureWrapMode.Clamp;
        material.SetTexture("_LUT", LUT3D);
        material.SetFloat("_Scale", (LUT3D.width - 1) / (1.0f * LUT3D.width));
        material.SetFloat("_Offset", 1.0f / (2.0f * LUT3D.width));
        Graphics.Blit(source, destination, material);
    }
}
