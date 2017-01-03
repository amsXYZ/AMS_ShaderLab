using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class DOFEffect : MonoBehaviour
    {

        [Tooltip("Focus object (focal distance = focus object's depth).")]
        public Transform focusObject;
        [Tooltip("Focal distance.")]
        public float focalDistance = 10;

        [Range(0,2), Tooltip("Width of the volume in focus.")]
        public float focalSize = 0.05f;
        [Range(0, 1), Tooltip("Camera's aperture (diameter of the lens).")]
        public float aperture = 0.5f;
        [Range(0, 3), Tooltip("Maximum distance of the blurring samples.")]
        public float maxBlurDistance = 1f;
        [Tooltip("Performs a few extra passes of near blur to obtain a better quality result.")]
        public bool HighQualityNearBlur;
        [Tooltip("Visualize camera's Circle of Confusion for the current settings.")]
        public bool Debug;

        private Material _material;
        private Camera _camera;

        float[] _poissonDisks = {-0.6116678f,  0.04548655f, -0.26605980f, -0.6445347f,
                                                -0.4798763f,  0.78557830f, -0.19723210f, -0.1348270f,
                                                -0.7351842f, -0.58396650f, -0.35353550f,  0.3798947f,
                                                0.1423388f,  0.39469180f, -0.01819171f,  0.8008046f,
                                                0.3313283f, -0.04656135f,  0.58593510f,  0.4467109f,
                                                0.8577477f,  0.11188750f,  0.03690137f, -0.9906120f,
                                                0.4768903f, -0.84335800f,  0.13749180f, -0.4746810f,
                                                0.7814927f, -0.48938420f,  0.38269190f,  0.8695006f };

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        //Creates a private material used to the effect
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/DOF"));
            _camera = GetComponent<Camera>();
        }
        void OnDisable()
        {
            if (_material) DestroyImmediate(_material);
            _material = null;
        }
        void OnEnable()
        {
            if (!_material) _material = new Material(Shader.Find("Hidden/DOF"));
            if (!_camera) _camera = GetComponent<Camera>();
        }

        private float CalculateDepth(float worldDist)
        {
            return _camera.WorldToViewportPoint((worldDist - _camera.nearClipPlane) * _camera.transform.forward + _camera.transform.position).z / (_camera.farClipPlane - _camera.nearClipPlane);
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Postprocess the image
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {

            // Setup all the materials.
            _material.SetFloat("_FocusDepth", (focusObject) ? (_camera.WorldToViewportPoint(focusObject.position)).z / (_camera.farClipPlane) : CalculateDepth(focalDistance));
            _material.SetFloat("_FocalSize", focalSize);
            _material.SetFloat("_Aperture", 1.0f / (1.0f - aperture) - 1.0f);
            _material.SetFloat("_MaxBlurDistance", maxBlurDistance);
            _material.SetInt("_Debug", Debug ? 1 : 0);

            _material.SetFloatArray("_PoissonDisks", _poissonDisks);

            //Determine the format of the render texture we'll use.
            RenderTextureFormat rtFormat;
            if (_camera.hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBFloat)) rtFormat = RenderTextureFormat.ARGBFloat;
                else rtFormat = RenderTextureFormat.DefaultHDR;
            }
            else rtFormat = RenderTextureFormat.Default;

            if (!Debug)
            {
                // Calculate the front CoC radius and blur the image accordingly.
                RenderTexture FcocBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(source, FcocBuffer, _material, 2);
                RenderTexture FdownsampledBufffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(FcocBuffer, FdownsampledBufffer, _material, 3);
                RenderTexture FblurredBuffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(FdownsampledBufffer, FblurredBuffer, _material, 4);

                RenderTexture FblurredBuffer2 = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, rtFormat, RenderTextureReadWrite.sRGB);
                RenderTexture FblurredBuffer3 = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, rtFormat, RenderTextureReadWrite.sRGB);
                if (HighQualityNearBlur)
                {
                    Graphics.Blit(FblurredBuffer, FblurredBuffer2, _material, 4);
                    Graphics.Blit(FblurredBuffer2, FblurredBuffer3, _material, 4);
                }

                // Do the same for the back CoC radius.
                RenderTexture BcocBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(source, BcocBuffer, _material, 1);
                RenderTexture BdownsampledBufffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(BcocBuffer, BdownsampledBufffer, _material, 3);
                RenderTexture BblurredBuffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(BdownsampledBufffer, BblurredBuffer, _material, 4);

                // Get the image CoC radius.
                RenderTexture cocBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, rtFormat, RenderTextureReadWrite.sRGB);
                Graphics.Blit(source, cocBuffer, _material, 0);

                // Composite the final image.
                _material.SetTexture("_downsampledBlurredB", BblurredBuffer);
                if(HighQualityNearBlur) _material.SetTexture("_downsampledBlurredF", FblurredBuffer3);
                else _material.SetTexture("_downsampledBlurredF", FblurredBuffer);
                Graphics.Blit(cocBuffer, destination, _material, 5);

                RenderTexture.ReleaseTemporary(FcocBuffer);
                RenderTexture.ReleaseTemporary(FdownsampledBufffer);
                RenderTexture.ReleaseTemporary(FblurredBuffer);
                RenderTexture.ReleaseTemporary(FblurredBuffer2);
                RenderTexture.ReleaseTemporary(FblurredBuffer3);
                RenderTexture.ReleaseTemporary(BcocBuffer);
                RenderTexture.ReleaseTemporary(BdownsampledBufffer);
                RenderTexture.ReleaseTemporary(BblurredBuffer);
                RenderTexture.ReleaseTemporary(cocBuffer);
            }

            else
            {
                // Get the image CoC radius.
                Graphics.Blit(source, destination, _material, 0);
            }
            
        }
    }
}
