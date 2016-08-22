using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class Tonemapper : MonoBehaviour
    {
        public enum TonemappingMethod { Photographic, Reinhard, HPDuiker, HejlDawson, Hable, ACES };

        public TonemappingMethod method;
        [Range(0, 16)]
        public float exposure = 1;

        private Material _material;
        [SerializeField, Tooltip("Look-up texture used in Haarm-Peter Duiker’s tonemapping method")]
        private Texture filmLut;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/Tonemapper"));
        }
        void OnDisable()
        {
            if (_material) DestroyImmediate(_material);
            _material = null;
        }
        void OnEnable()
        {
            if (!_material) _material = new Material(Shader.Find("Hidden/Tonemapper"));
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            _material.SetFloat("_Exposure", exposure);
            _material.SetTexture("_FilmLut", filmLut);
            Graphics.Blit(source, destination, _material, (int)method);
        }
    }
}
