using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode, ImageEffectOpaque]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class ComicShadows : MonoBehaviour
    {
        // Enum to determine the type of shadow.
        public enum ToonShadows { Dots, Diamonds, Lines, Debug };

        [Tooltip("Shape of the pattern that will define the shadow.")]
        public ToonShadows shadowType = ToonShadows.Dots;
        [Tooltip("Color of the shadow pattern (alpha controls strength).")]
        public Color shadowColor = Color.black;
        [Tooltip("Controls how smooth or toony the shadow looks.")]
        public float levels = 100;

        [Tooltip("Pattern's rotation angle.")]
        public float angle = 45;
        [Tooltip("Pattern's frequency.")]
        public float frequency = 100;
        [Tooltip("Applies a power to the intensity of the shadow: pow(shadow, 10 - size).")]
        public float size = 1;
        [Tooltip("Pattern's separation between elements.")]
        public float separation = 1;

        private Material _material;

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        void Awake()
        {
            SetupMaterial();
        }
        void OnValidate()
        {
            SetupMaterial();
        }
        void Reset() {
            SetupMaterial();
        }

        // Setups a private material used to the effect based on the shading style selected.
        private void SetupMaterial()
        {
            switch (shadowType)
            {
                case ToonShadows.Dots:
                    _material = new Material(Shader.Find("Hidden/ShadingDots"));
                    break;
                case ToonShadows.Diamonds:
                    _material = new Material(Shader.Find("Hidden/ShadingDiamonds"));
                    break;
                case ToonShadows.Lines:
                    _material = new Material(Shader.Find("Hidden/ShadingLines"));
                    break;
                case ToonShadows.Debug:
                    _material = new Material(Shader.Find("Hidden/DebugShading"));
                    break;
            }
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            SetupMaterial();

            _material.SetFloat("_angle", angle);
            _material.SetFloat("_frequency", frequency);
            _material.SetFloat("_size", size);
            _material.SetFloat("_separation", separation);
            _material.SetColor("_shadowColor", shadowColor);

            // Setup the "_Levels" uniform in all the materials that use the AlphaShadows shader.
            Object[] renderers = GameObject.FindObjectsOfType(typeof(Renderer));
            for (int i = 0; i < renderers.Length; i++)
            {
                Material[] materials = ((Renderer)renderers[i]).sharedMaterials;
                for (int j = 0; j < materials.Length; j++)
                {
                    string s = materials[j].shader.name;

                    if (s == "Custom/AlphaShadows")
                    {
                        materials[j].SetFloat("_Levels", levels);
                    }
                }
            }

            Graphics.Blit(source, destination, _material);
        }
    }
}
