using UnityEngine;
using System.Collections;

public class HatchingDemo : MonoBehaviour {

    public Texture2D TAM1;
    public Texture2D TAM2;
    public Texture2D TAM3;
    public Texture2D TAM4;
    public Texture2D TAM5;
    public Texture2D TAM6;

    public MeshRenderer sphere;

	void Start () {
        Texture2DArray texArray = new Texture2DArray(TAM1.width, TAM1.height, 8, TextureFormat.RGB24, true);
        texArray.filterMode = FilterMode.Trilinear;
        texArray.anisoLevel = 16;
        texArray.wrapMode = TextureWrapMode.Repeat;

        texArray.SetPixels(((Texture2D)TAM1).GetPixels(), 0);
        texArray.SetPixels(((Texture2D)TAM2).GetPixels(), 1);
        texArray.SetPixels(((Texture2D)TAM3).GetPixels(), 2);
        texArray.SetPixels(((Texture2D)TAM4).GetPixels(), 3);
        texArray.SetPixels(((Texture2D)TAM5).GetPixels(), 4);
        texArray.SetPixels(((Texture2D)TAM6).GetPixels(), 5);
        texArray.Apply();

        sphere.sharedMaterial.SetTexture("_TAMTexArray", texArray);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(0);
        }
        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(2);
        }
    }
}
