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
        [Range(1,5), Tooltip("Width of the sampling kernel.")]
        public int samplingKernelWidth = 3;
        [Range(1,4), Tooltip("Width (in pixels) of the sampling kernel.")]
        public float samplingDistance = 1;
        [Range(10,30), Tooltip("Number of posterized colors we'll use.")]
        public int colors = 10;

        private Material _material;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        // Creates a private material used to the effect.
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/OilPainting"));
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
            _material.SetInt("_SamplingKernelWidth", samplingKernelWidth);
            _material.SetFloat("_Distance", samplingDistance);
            _material.SetInt("_ColorIntensities", colors);

            Graphics.Blit(source, destination, _material);
            return;
        }
    }
}
