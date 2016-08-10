using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class ColorGrading : MonoBehaviour {

    [Range(-2, 2)]
    public float temperature;
    [Range(-2, 2)]
    public float tilt;

    [Space, Range(-0.5f, 0.5f)]
    public float hue = 0;
    [Range(0f, 2f)]
    public float saturation = 1;
    [Range(-1f, 1f)]
    public float vibrance = 0;
    [Range(0f, 10f)]
    public float value = 1;

    [Space, Range(0f, 2f)]
    public float contrast = 1;
    [Range(0.01f, 5f)]
    public float gain = 1;
    [Range(0.01f, 5f)]
    public float gamma = 1;

    public Texture2D userLUT;

    private Material material;
    private Texture3D internaLUT;

    // An analytical model of chromaticity of the standard illuminant, by Judd et al.
    // http://en.wikipedia.org/wiki/Standard_illuminant#Illuminant_series_D
    // Slightly modifed to adjust it with the D65 white point (x=0.31271, y=0.32902).
    private float StandardIlluminantY(float x)
    {
        return 2.87f * x - 3f * x * x - 0.27509507f;
    }

    // CIE xy chromaticity to CAT02 LMS.
    // http://en.wikipedia.org/wiki/LMS_color_space#CAT02
    private Vector3 CIExyToLMS(float x, float y)
    {
        float Y = 1f;
        float X = Y * x / y;
        float Z = Y * (1f - x - y) / y;

        float L = 0.7328f * X + 0.4296f * Y - 0.1624f * Z;
        float M = -0.7036f * X + 1.6975f * Y + 0.0061f * Z;
        float S = 0.0030f * X + 0.0136f * Y + 0.9834f * Z;

        return new Vector3(L, M, S);
    }

    private Vector3 GetWhiteBalance()
    {
        float t1 = temperature;
        float t2 = tilt;

        // Get the CIE xy chromaticity of the reference white point.
        // Note: 0.31271 = x value on the D65 white point
        float x = 0.31271f - t1 * (t1 < 0f ? 0.1f : 0.05f);
        float y = StandardIlluminantY(x) + t2 * 0.05f;

        // Calculate the coefficients in the LMS space.
        Vector3 w1 = new Vector3(0.949237f, 1.03542f, 1.08728f); // D65 white point
        Vector3 w2 = CIExyToLMS(x, y);
        return new Vector3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);
    }

    private static Texture2D GenerateIdentityLut(int dim)
    {
        Color[] newC = new Color[dim * dim * dim];
        float oneOverDim = 1f / ((float)dim - 1f);

        for (int i = 0; i < dim; i++)
            for (int j = 0; j < dim; j++)
                for (int k = 0; k < dim; k++)
                    newC[i + (j * dim) + (k * dim * dim)] = new Color((float)i * oneOverDim, Mathf.Abs((float)k * oneOverDim), (float)j * oneOverDim, 1f);

        Texture2D tex2D = new Texture2D(dim * dim, dim, TextureFormat.RGBAFloat, false, true)
        {
            name = "Identity LUT",
            filterMode = FilterMode.Bilinear,
            anisoLevel = 0,
            hideFlags = HideFlags.DontSave
        };
        tex2D.SetPixels(newC);
        tex2D.Apply();

        return tex2D;
    }

    private static Texture3D LUT2DTo3D(Texture2D LUT)
    {
        int dim = LUT.height;
        if (LUT.width != dim * dim) Debug.LogError("This LUT hasn't the right size (x,x*x)");

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

        Texture3D LUT3D = new Texture3D(dim, dim, dim, TextureFormat.RGBA32, false);
        LUT3D.wrapMode = TextureWrapMode.Clamp;
        LUT3D.SetPixels(depthTextures);
        LUT3D.Apply();

        return LUT3D;

    }

    void Awake()
    {
        material = new Material(Shader.Find("Hidden/ColorGrading"));
    }

    void OnValidate()
    {
        if (userLUT)
            internaLUT = LUT2DTo3D(userLUT);
        else
            internaLUT = LUT2DTo3D(GenerateIdentityLut(32));
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if(!internaLUT)
        {
            if (userLUT)
                internaLUT = LUT2DTo3D(userLUT);
            else
                internaLUT = LUT2DTo3D(GenerateIdentityLut(32));
        }

        material.SetTexture("_LUT", internaLUT);
        material.SetFloat("_Scale", (internaLUT.width - 1) / (1.0f * internaLUT.width));
        material.SetFloat("_Offset", 1.0f / (2.0f * internaLUT.width));
        material.SetVector("_WhiteBalance", GetWhiteBalance());
        material.SetVector("_ContrastGainGamma", new Vector3(contrast, gain, 1f / gamma));
        material.SetFloat("_Vibrance", vibrance);
        material.SetVector("_HSV", new Vector4(hue, saturation, value));
        Graphics.Blit(source, destination, material);
        return;
    }
}
