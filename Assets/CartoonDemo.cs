using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using AMSPostprocessingEffects;

public class CartoonDemo : MonoBehaviour {

    public Camera camera;

    [Space]
    public Toggle HalftoneEnabled;
    public Toggle ComicEnabled;
    public Toggle EdgeEnabled;

    [Space]
    public Slider HalftoneFrequency;
    public Toggle HalftoneBW;
    public Toggle HalftonePaper;
    public Texture2D PaperTexture;

    [Space]
    public Slider ComicFrequency;
    public Slider ComicAngle;
    public Slider ComicSize;
    public Slider ComicSeparation;
    public Dropdown ComicStyle;

    [Space]
    public Slider EdgeWidth;
    public Toggle EdgeDebug;

    private HalftoneEffect halftoneEffect = new HalftoneEffect();
    private ComicShadows comicEffect = new ComicShadows();
    private SobelDepthEdgeDetection edgeEffect = new SobelDepthEdgeDetection();

    public void UpdateValues()
    {
        //Halftone
        float minScreenSide = Mathf.Min(camera.pixelWidth, camera.pixelHeight);
        halftoneEffect.frequency = HalftoneFrequency.value * minScreenSide / 4;

        halftoneEffect.BW = HalftoneBW.isOn;

        if (HalftonePaper.isOn)
            halftoneEffect.printingPaper = PaperTexture;
        else
            halftoneEffect.printingPaper = null;

        //Comic
        comicEffect.frequency = ComicFrequency.value * 200;
        comicEffect.angle = ComicAngle.value * 180;
        comicEffect.size = ComicSize.value * 10;
        comicEffect.separation = ComicSeparation.value * 3;
        comicEffect.shadowType = (ComicShadows.ToonShadows)ComicStyle.value;

        //Edge
        edgeEffect.edgeWidth = (int)(EdgeWidth.value * 4);
        edgeEffect.debug = EdgeDebug.isOn;
    }


	// Use this for initialization
	void Start () {
        halftoneEffect = camera.GetComponent<HalftoneEffect>();
        comicEffect = camera.GetComponent<ComicShadows>();
        edgeEffect = camera.GetComponent<SobelDepthEdgeDetection>();

        UpdateValues();
	}

    void Update()
    {
        halftoneEffect.enabled = HalftoneEnabled.isOn;
        comicEffect.enabled = ComicEnabled.isOn;
        edgeEffect.enabled = EdgeEnabled.isOn;

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(1);
        }
    }
}
