using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class SobelDepthEdgeDetection : MonoBehaviour
    {
        [Header("Edge Sensitivity Settings")]
        [Tooltip("Adjust the importance of the depth in the edge calculation.")]
        public float sensitivityDepth = 1.0f;
        [Tooltip("Adjust the importance of the normals in the edge calculation.")]
        public float sensitivityNormals = 1.0f;
        [Range(0,4), Tooltip("Adjust the width of the calculated edge.")]
        public int edgeWidth = 1;

        [Header("Other")]
        public Color outlineColor = Color.black;
        public bool debug = false;

        private Material _material;
        private Camera _camera;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        // Creates a private material used to the effect.
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/SobelDepth"));
        }

        // Methods used to take care of the materials when enabling/disabling the effects in the inspector.
        void OnDisable()
        {
            if (_material) DestroyImmediate(_material);
            _material = null;
        }
        void OnEnable()
        {
            if (!_material) _material = new Material(Shader.Find("Hidden/SobelDepth"));
            if (!_camera) _camera = GetComponent<Camera>();
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Postprocess the image
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            _material.SetVector("_Sensitivity", new Vector2(sensitivityDepth, sensitivityNormals));
            _material.SetFloat("_EdgeWidth", edgeWidth * 0.5f);
            _material.SetColor("_EdgeColor", outlineColor);
            _material.SetInt("_Debug", debug ? 1 : 0);
            Graphics.Blit(source, destination, _material);
        }
    }
}