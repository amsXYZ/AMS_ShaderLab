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

        public enum ToonShadows { Dots, Diamonds, Lines, Debug };

        public ToonShadows shadowType = ToonShadows.Dots;
        public Color shadowColor = Color.black;
        
        public float levels = 100;
        public float angle = 45;
        public float frequency = 100;
        public float size = 1;
        public float separation = 1;

        private Material material;

        private void SetupMaterial()
        {
            switch (shadowType)
            {
                case ToonShadows.Dots:
                    material = new Material(Shader.Find("Hidden/ShadingDots"));
                    break;
                case ToonShadows.Diamonds:
                    material = new Material(Shader.Find("Hidden/ShadingDiamonds"));
                    break;
                case ToonShadows.Lines:
                    material = new Material(Shader.Find("Hidden/ShadingLines"));
                    break;
                case ToonShadows.Debug:
                    material = new Material(Shader.Find("Hidden/DebugShading"));
                    break;
            }
        }

        //Creates a private material used to the effect
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

        [ImageEffectOpaque]
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            material.SetFloat("_angle", angle);
            material.SetFloat("_frequency", frequency);
            material.SetFloat("_size", size);
            material.SetFloat("_separation", separation);
            material.SetColor("_shadowColor", shadowColor);

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

            Graphics.Blit(source, destination, material);
        }
    }
}
