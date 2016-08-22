using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class HalftoneEffect : MonoBehaviour
    {
        [Tooltip("Printing paper texture used to achieve a better effect.")]
        public Texture2D printingPaper;
        [Tooltip("Number of halftone dots that fill the screen. It's clamped to a fifth of the minimum screen size (in pixels).")]
        public float frequency;
        [Tooltip("Enables BW halftone rendering.")]
        public bool BW;

        private Material _material;
        private Camera _camera;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        //Creates a private _material used to the effect
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/Halftone"));
            _camera = GetComponent<Camera>();
        }
        void OnDisable()
        {
            if (_material) DestroyImmediate(_material);
            _material = null;
        }
        void OnEnable()
        {
            if (!_material) _material = new Material(Shader.Find("Hidden/Halftone"));
            if (!_camera) _camera = GetComponent<Camera>();
        }

        ///<summary>
        /// Get the effect's camera.
        ///</summary>
        public Camera GetCamera()
        {
            return _camera;
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        //Postprocess the image
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            _material.SetTexture("_paper", (printingPaper) ? printingPaper : Texture2D.whiteTexture);
            _material.SetFloat("_frequency", frequency);
            _material.SetVector("_uDims", new Vector4(Screen.width, Screen.height, 1.0f / Screen.width, 1.0f / Screen.height));
            _material.SetInt("_BW", BW ? 1 : 0);
            Graphics.Blit(source, destination, _material);
        }
    }
}
