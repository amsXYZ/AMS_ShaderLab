using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode, ImageEffectOpaque]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class ColorGrading : MonoBehaviour
    {
        [Header("LUT")]
        [Tooltip("User-defined Look-Up Texture (LUT).")]
        public Texture2D userLUT;

        [Header("White Balance Settings")]
        [Range(-2, 2), Tooltip("This value shifts the colors from cold to warmer tones (X Axis of the sRGB color space)")]
        public float temperature = 0;
        [Range(-2, 2), Tooltip("This value shifts the colors from green to magenta tones (Y Axis of the sRGB color space)")]
        public float tilt = 0;

        [Header("HSV Settings")]
        [Range(-0.5f, 0.5f), Tooltip("This value offset the pixels' hue in the HSV color space.")]
        public float hue = 0;
        [Range(0f, 2f), Tooltip("This value offset the pixels' saturation in the HSV color space.")]
        public float saturation = 1;
        [Range(-1f, 1f), Tooltip("This value changes the saturation of all lower-saturated colors with less effect on the higher-saturated colors. Vibrance also prevents skin tones from becoming oversaturated.")]
        public float vibrance = 0;
        [Range(0f, 10f), Tooltip("This value offset the pixels' brightness in the HSV color space.")]
        public float value = 1;

        [Header("Contrast Gain Curve Settings")]
        [Range(0f, 2f), Tooltip("This value decreases or increases the distance between blacks and whites.")]
        public float contrast = 1;
        [Range(0.01f, 5f), Tooltip("This value control the stepness of the contrast gain curve (which defines the how the contrast is applied).")]
        public float gain = 1;
        [Range(0.01f, 5f), Tooltip("This value increases the strength of the midtones.")]
        public float gamma = 1;

        [Header("Debug")]
        [Tooltip("Draws the internal LUT used to alter the colors.")]
        public bool renderLUT = false;

        private Material _material;
        private Texture3D _internalLUT3D;
        private Texture2D _internalLUT2D;
        
        //////////////////////////////////
        // Unity Editor related functions.
        //////////////////////////////////

        // Initialization.
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/ColorGrading"));
            _internalLUT2D = GenerateIdentityLut(32);
            _internalLUT3D = LUT2DTo3D(_internalLUT2D);
        }

        // Reset editor values manually.
        void ResetEditorValues()
        {
            temperature = tilt = hue = vibrance = 0;
            saturation = value = contrast = gain = gamma = 1;
        }

        // Check if we have to update the internal LUTs.
        void OnValidate()
        {
            if (userLUT)
            {
                if (userLUT != _internalLUT2D)
                {
                    _internalLUT2D = userLUT;
                    _internalLUT3D = LUT2DTo3D(_internalLUT2D);
                    ResetEditorValues();
                }
            }
            else
                _internalLUT2D = GenerateIdentityLut(32);
                _internalLUT3D = LUT2DTo3D(_internalLUT2D);
        }

        // Reset the internal LUTs.
        void Reset()
        {
            _internalLUT2D = GenerateIdentityLut(32);
            _internalLUT3D = LUT2DTo3D(_internalLUT2D);
        }

        //////////////////////////////////
        // White balance related functions.
        //////////////////////////////////

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

        // Find the white balance point offseted by the temperature and tilt values.
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

        /////////////////////////////////////////
        // LUT Generation/Transformation methods.
        /////////////////////////////////////////

        // Generate the identity LUT.
        private static Texture2D GenerateIdentityLut(int dim)
        {
            Color[] newC = new Color[dim * dim * dim];
            float oneOverDim = 1f / ((float)dim - 1f);

            for (int i = 0; i < dim; i++)
                for (int j = 0; j < dim; j++)
                    for (int k = 0; k < dim; k++)
                        newC[i + (j * dim) + (k * dim * dim)] = new Color((float)i * oneOverDim, Mathf.Abs((float)k * oneOverDim), (float)j * oneOverDim, 1f);

            Texture2D tex2D = new Texture2D(dim * dim, dim, TextureFormat.RGB24, false, true)
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

        // Turn our 2D intetnal LUT into a 3D one to take advantage of hardware interpolation in the shaders.
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

        ///<summary>
        /// Render the modified LUT to be saved as a file.
        ///</summary>
        public Texture2D GenerateLUT(string path)
        {
            RenderTexture buffer = RenderTexture.GetTemporary(_internalLUT2D.width, _internalLUT2D.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

            _material.SetTexture("_LUT", _internalLUT3D);
            _material.SetFloat("_Scale", (_internalLUT3D.width - 1) / (1.0f * _internalLUT3D.width));
            _material.SetFloat("_Offset", 1.0f / (2.0f * _internalLUT3D.width));
            _material.SetVector("_WhiteBalance", GetWhiteBalance());
            _material.SetVector("_ContrastGainGamma", new Vector3(contrast, gain, 1f / gamma));
            _material.SetFloat("_Vibrance", vibrance);
            _material.SetVector("_HSV", new Vector4(hue, saturation, value));
            _material.SetTexture("_DebugLUT", null);
            _material.SetInt("_Debug", 0);

            Graphics.Blit(_internalLUT2D, buffer, _material, 0);

            Texture2D lut = new Texture2D(buffer.width, buffer.height, TextureFormat.RGB24, false, true);
            RenderTexture.active = buffer;
            lut.ReadPixels(new Rect(0f, 0f, lut.width, lut.height), 0, 0);
            RenderTexture.active = null;
            return lut;
        }

        //////////////////////////////////////
        // Post-processing effect application.
        //////////////////////////////////////

        // Called by the camera to apply the image effect.
        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            _material.SetTexture("_LUT", _internalLUT3D);
            _material.SetFloat("_Scale", (_internalLUT3D.width - 1) / (1.0f * _internalLUT3D.width));
            _material.SetFloat("_Offset", 1.0f / (2.0f * _internalLUT3D.width));
            _material.SetVector("_WhiteBalance", GetWhiteBalance());
            _material.SetVector("_ContrastGainGamma", new Vector3(contrast, gain, 1f / gamma));
            _material.SetFloat("_Vibrance", vibrance);
            _material.SetVector("_HSV", new Vector4(hue, saturation, value));

            _material.SetTexture("_DebugLUT", _internalLUT2D);
            _material.SetInt("_Debug", renderLUT ? 1 : 0);

            if(renderLUT) Graphics.Blit(source, destination, _material, 1);
            else Graphics.Blit(source, destination, _material, 0);

            return;
        }
    }
}
