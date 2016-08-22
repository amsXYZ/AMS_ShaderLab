using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class BlurEffect : MonoBehaviour
    {
        [Header("Blur Settings")]
        [Range(0, 3), Tooltip("How much will the camera's render texture will be downsampled (1/2^downsampling).")]
        public int downsampling = 2;
        [Range(0, 10), Tooltip("How many blur iterations will be applied.")]
        public int iterations = 3;
        [Range(0.0f, 1.0f), Tooltip("How much will be the blur samples spread.")]
        public float blurSpread = 0.6f;

        private Material _material;
        private Camera _camera;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        // Creates a private material used to the effect and get the camera component.
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/Blur"));
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
            if (!_material) _material = new Material(Shader.Find("Hidden/Blur"));
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            //Determine the size of the render texture we'll use.
            int rtW = source.width / (int) Mathf.Pow(2, downsampling);
            int rtH = source.height / (int) Mathf.Pow(2, downsampling);

            //Determine the format of the render texture we'll use.
            RenderTextureFormat rtFormat;
            if (_camera.hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBFloat)) rtFormat = RenderTextureFormat.ARGBFloat;
                else rtFormat = RenderTextureFormat.DefaultHDR;
            }
            else rtFormat = RenderTextureFormat.Default;

            //Downsample the camera's RenderTexture and store it in a smaller new one.
            RenderTexture finalBlurBuffer = RenderTexture.GetTemporary(rtW, rtH, 0, rtFormat, RenderTextureReadWrite.Linear);
            Graphics.BlitMultiTap(source, finalBlurBuffer, _material,
                                   new Vector2(-1, -1),
                                   new Vector2(-1, 1),
                                   new Vector2(1, 1),
                                   new Vector2(1, -1));

            //Blur the downsampled texture.
            for (int i = 0; i < iterations; i++)
            {
                RenderTexture temporaryBlurBuffer = RenderTexture.GetTemporary(rtW, rtH, 0, rtFormat, RenderTextureReadWrite.Linear);

                //Calculate the spread of the blur samples.
                float offset = i * blurSpread;
                Graphics.BlitMultiTap(finalBlurBuffer, temporaryBlurBuffer, _material,
                                   new Vector2(-offset, -offset),
                                   new Vector2(-offset, offset),
                                   new Vector2(offset, offset),
                                   new Vector2(offset, -offset));

                finalBlurBuffer = temporaryBlurBuffer;
                if (i == iterations - 1) RenderTexture.ReleaseTemporary(temporaryBlurBuffer);
            }

            //Blit copy to the screen.
            Graphics.Blit(finalBlurBuffer, destination);
            return;
        }
    }
}
