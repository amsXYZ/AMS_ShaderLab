using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class OilPaintingEffect : MonoBehaviour
    {
        [Range(0, 2), Tooltip("How much will the camera's render texture will be downsampled (1/2^downsampling).")]
        public int downsampling = 2;
        [Range(1,5), Tooltip("Width of the sampling kernel.")]
        public int samplingKernelWidth = 3;
        [Range(1,4), Tooltip("Width (in pixels) of the sampling kernel.")]
        public float samplingDistance = 1;
        [Range(10,30), Tooltip("Number of posterized colors we'll use.")]
        public int colors = 10;

        private Material _material;
        private Camera _camera;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        // Creates a private material used to the effect.
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/OilPainting"));
            _camera = GetComponent<Camera>();
        }

        // Methods used to take care of the materials when enabling/disabling the effects in the inspector.
        void OnDisable()
        {
            if (_material) DestroyImmediate(_material);
            _material = null;
        }
        void OnEnable()
        {
            if (!_material) _material = new Material(Shader.Find("Hidden/OilPainting"));
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Postprocess the image
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            //Determine the size of the render texture we'll use.
            int rtW = source.width / (int)Mathf.Pow(2, downsampling);
            int rtH = source.height / (int)Mathf.Pow(2, downsampling);

            //Determine the format of the render texture we'll use.
            RenderTextureFormat rtFormat;
            if (_camera.hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBFloat)) rtFormat = RenderTextureFormat.ARGBFloat;
                else rtFormat = RenderTextureFormat.DefaultHDR;
            }
            else rtFormat = RenderTextureFormat.Default;

            //Downsample the camera's RenderTexture and store it in a smaller new one.
            RenderTexture finalBuffer = RenderTexture.GetTemporary(rtW, rtH, 0, rtFormat, RenderTextureReadWrite.sRGB);
            Graphics.BlitMultiTap(source, finalBuffer, _material,
                                   new Vector2(-1, -1),
                                   new Vector2(-1, 1),
                                   new Vector2(1, 1),
                                   new Vector2(1, -1));

            _material.SetInt("_SamplingKernelWidth", samplingKernelWidth);
            _material.SetFloat("_Distance", samplingDistance);
            _material.SetInt("_ColorIntensities", colors);

            Graphics.Blit(finalBuffer, destination, _material);
            RenderTexture.ReleaseTemporary(finalBuffer);
            return;
        }
    }
}
