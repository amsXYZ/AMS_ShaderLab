using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class ComicShadows : MonoBehaviour {

    public enum ToonShadows { Plain, Dots, Diamonds, Lines, Debug};
    public enum ShadowColor { Plain, Gradient };

    public ToonShadows shadowType;
    [Range(2, 100)]
    public float levels;
    [Range(0, 180)]
    public float angle;
    [Range(0, 100)]
    public float frequency;
    [Range(0, 10)]
    public float size;
    [Range(0, 10)]
    public float separation;
    //public ShadowColor shadowColorType;
    //public Gradient shadowGradient;
    public Color shadowColor;

    private Material material;

    //Creates a private material used to the effect
    void Awake()
    {
        switch (shadowType)
        {
            case ToonShadows.Plain:
                material = new Material(Shader.Find("Hidden/ToonShading"));
                break;
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
            default:
                material = new Material(Shader.Find("Hidden/ToonShading"));
                break;
        }

        Object[] renderers = GameObject.FindObjectsOfType(typeof(Renderer));
        int i_max = renderers.Length;
        for (int i = 0; i < i_max; i++)
        {
            Material[] materials = ((Renderer)renderers[i]).sharedMaterials;
            int j_max = materials.Length;
            for (int j = 0; j < j_max; j++)
            {
                string s = materials[j].shader.name;

                if (s == "Custom/AlphaShadows" || s == "Custom/CutoutAlphaShadows")
                {
                    materials[j].SetFloat("_Levels", levels);
                }
            }
        }

    }

    void OnValidate()
    {
        switch (shadowType)
        {
            case ToonShadows.Plain:
                material = new Material(Shader.Find("Hidden/ToonShading"));
                break;
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
            default:
                material = new Material(Shader.Find("Hidden/ToonShading"));
                break;
        }

        Object[] renderers = GameObject.FindObjectsOfType(typeof(Renderer));
        int i_max = renderers.Length;
        for (int i = 0; i < i_max; i++)
        {
            Material[] materials = ((Renderer)renderers[i]).sharedMaterials;
            int j_max = materials.Length;
            for (int j = 0; j < j_max; j++)
            {
                string s = materials[j].shader.name;

                if (s == "Custom/AlphaShadows" || s == "Custom/CutoutAlphaShadows")
                {
                    materials[j].SetFloat("_Levels", levels);
                }
            }
        }

    }

    [ImageEffectOpaque]
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        material.SetFloat("_angle", angle);
        material.SetFloat("_frequency", frequency);
        material.SetFloat("_size", size);
        material.SetFloat("_separation", separation);
        material.SetColor("_shadowColor", shadowColor);
        //material.SetColor("_lightColor", shadowGradient.Evaluate(1));

        Object[] renderers = GameObject.FindObjectsOfType(typeof(Renderer));
        int i_max = renderers.Length;
        for (int i = 0; i < i_max; i++)
        {
            Material[] materials = ((Renderer)renderers[i]).sharedMaterials;
            int j_max = materials.Length;
            for (int j = 0; j < j_max; j++)
            {
                string s = materials[j].shader.name;

                if (s == "Custom/AlphaShadows" || s == "Custom/CutoutAlphaShadows")
                {
                    materials[j].SetFloat("_Levels", levels);
                }
            }
        }

        Graphics.Blit(source, destination, material);
    }
}
