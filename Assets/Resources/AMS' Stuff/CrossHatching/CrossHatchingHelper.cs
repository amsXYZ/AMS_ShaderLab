using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class CrossHatchingHelper : MonoBehaviour {

	// Helper used to set up the texture array in play mode without having to open the material inspector.
	void Awake () {
        Renderer renderer = GetComponent<Renderer>();
        Material[] materials = renderer.sharedMaterials;
        for (int i = 0; i < materials.Length; i++)
        {
            string s = materials[i].shader.name;

            if (s == "Custom/CrossHatching")
            {
                Texture2D t0 = (Texture2D)materials[i].GetTexture("_TAM0");
                Texture2D t1 = (Texture2D)materials[i].GetTexture("_TAM1");
                Texture2D t2 = (Texture2D)materials[i].GetTexture("_TAM2");
                Texture2D t3 = (Texture2D)materials[i].GetTexture("_TAM3");
                Texture2D t4 = (Texture2D)materials[i].GetTexture("_TAM4");
                Texture2D t5 = (Texture2D)materials[i].GetTexture("_TAM5");

                if (t0 && t1 && t2 && t3 && t4 && t5)
                {
                    Texture2DArray texArray = new Texture2DArray(t0.width, t0.height, 8, TextureFormat.RGB24, true);
                    texArray.filterMode = FilterMode.Trilinear;
                    texArray.anisoLevel = 16;
                    texArray.wrapMode = TextureWrapMode.Repeat;

                    texArray.SetPixels(((Texture2D)t0).GetPixels(), 0);
                    texArray.SetPixels(((Texture2D)t1).GetPixels(), 1);
                    texArray.SetPixels(((Texture2D)t2).GetPixels(), 2);
                    texArray.SetPixels(((Texture2D)t3).GetPixels(), 3);
                    texArray.SetPixels(((Texture2D)t4).GetPixels(), 4);
                    texArray.SetPixels(((Texture2D)t5).GetPixels(), 5);
                    texArray.Apply();

                    materials[i].SetTexture("_TAMTexArray", texArray);
                }
            }
        }
    }

    void Start()
    {
        Renderer renderer = GetComponent<Renderer>();
        Material[] materials = renderer.sharedMaterials;
        for (int i = 0; i < materials.Length; i++)
        {
            string s = materials[i].shader.name;

            if (s == "Custom/CrossHatching")
            {
                Texture2D t0 = (Texture2D)materials[i].GetTexture("_TAM0");
                Texture2D t1 = (Texture2D)materials[i].GetTexture("_TAM1");
                Texture2D t2 = (Texture2D)materials[i].GetTexture("_TAM2");
                Texture2D t3 = (Texture2D)materials[i].GetTexture("_TAM3");
                Texture2D t4 = (Texture2D)materials[i].GetTexture("_TAM4");
                Texture2D t5 = (Texture2D)materials[i].GetTexture("_TAM5");

                if (t0 && t1 && t2 && t3 && t4 && t5)
                {
                    Texture2DArray texArray = new Texture2DArray(t0.width, t0.height, 8, TextureFormat.RGB24, true);
                    texArray.filterMode = FilterMode.Trilinear;
                    texArray.anisoLevel = 16;
                    texArray.wrapMode = TextureWrapMode.Repeat;

                    texArray.SetPixels(((Texture2D)t0).GetPixels(), 0);
                    texArray.SetPixels(((Texture2D)t1).GetPixels(), 1);
                    texArray.SetPixels(((Texture2D)t2).GetPixels(), 2);
                    texArray.SetPixels(((Texture2D)t3).GetPixels(), 3);
                    texArray.SetPixels(((Texture2D)t4).GetPixels(), 4);
                    texArray.SetPixels(((Texture2D)t5).GetPixels(), 5);
                    texArray.Apply();

                    materials[i].SetTexture("_TAMTexArray", texArray);
                }
            }
        }
    }
}
