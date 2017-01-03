using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using AMSPostprocessingEffects;

public class CorridorDemo : MonoBehaviour {

    public Camera camera;

    [Space]
    public Toggle BlurEnabled;
    public Toggle BloomEnabled;
    public Toggle DOFEnabled;
    public Toggle ColorGradingEnabled;
    public Toggle ToneMappingEnabled;
    public Toggle SmearingEnabled;
    public Toggle OilPaintingEnabled;
    public Toggle AOEnabled;

    [Space]
    public Slider BlurSpread;

    [Space]
    public Slider BloomThreshold;
    public Slider BloomIntensity;
    public Slider BloomSpread;
    public Toggle BloomDebug;

    [Space]
    public Toggle DOFDebug;

    [Space]
    public Dropdown ColorGradingSetting;
    public Texture2D LUT0;
    public Texture2D LUT1;
    public Texture2D LUT2;

    [Space]
    public Slider ToneMappingExposure;

    [Space]
    public SkinnedMeshRenderer SmearingRenderer;
    public Material SmearingMaterial;
    public Material NormalMaterial;
    public Slider SmearingIntensity;
    public Toggle SmearingNoise;
    public Texture2D NoiseTexture;

    [Space]
    public Slider AOLevels;
    public Slider AOIntensiy;
    public Toggle AODebug;

    private BlurEffect blurEffect = new BlurEffect();
    private BloomEffect bloomEffect = new BloomEffect();
    private DOFEffect dofEffect = new DOFEffect();
    private ColorGrading colorgradingEffect = new ColorGrading();
    private Tonemapper tonemappingEffect = new Tonemapper();
    private OilPaintingEffect oilpaintingEffect = new OilPaintingEffect();
    private MSSAO aoEffect = new MSSAO();

    public void UpdateValues()
    {
        //Blur
        blurEffect.blurSpread = BlurSpread.value * 0.4f + 0.1f;

        //Bloom
        bloomEffect.threshold = BloomThreshold.value * 1.5f;
        bloomEffect.intensity = BloomIntensity.value * 10f + 0.75f;
        bloomEffect.blurSpread = BloomSpread.value;
        bloomEffect.debug = BloomDebug.isOn;

        //DOF
        dofEffect.Debug = DOFDebug.isOn;

        //ColorGrading
        switch (ColorGradingSetting.value)
        {
            case 0:
                colorgradingEffect.userLUT = LUT0;
                break;
            case 1:
                colorgradingEffect.userLUT = LUT1;
                break;
            case 2:
                colorgradingEffect.userLUT = LUT2;
                break;
        }
        colorgradingEffect.SetChanges();

        //Tonemapping
        tonemappingEffect.exposure = ToneMappingExposure.value * 1.5f + 0.1f;

        //Smearing
        if (SmearingEnabled.isOn)
        {
            SmearingMaterial.SetFloat("_Intensity", SmearingIntensity.value * 32);
            if(SmearingNoise.isOn)
                SmearingMaterial.SetTexture("_NoiseTex", NoiseTexture);
            else SmearingMaterial.SetTexture("_NoiseTex", Texture2D.whiteTexture);
            SmearingRenderer.sharedMaterial = SmearingMaterial;
        }
        else SmearingRenderer.sharedMaterial = NormalMaterial;


        //AO
        aoEffect.levels = (int)(AOLevels.value * 3) + 1;
        aoEffect.intensity = AOIntensiy.value * 4;
        aoEffect.debug = AODebug.isOn;
    }


    // Use this for initialization
    void Start()
    {
        blurEffect = camera.GetComponent<BlurEffect>();
        bloomEffect = camera.GetComponent<BloomEffect>();
        dofEffect = camera.GetComponent<DOFEffect>();
        colorgradingEffect = camera.GetComponent<ColorGrading>();
        tonemappingEffect = camera.GetComponent<Tonemapper>();
        oilpaintingEffect = camera.GetComponent<OilPaintingEffect>();
        aoEffect = camera.GetComponent<MSSAO>();

        UpdateValues();
    }

    // Update is called once per frame
    void Update () {
        blurEffect.enabled = BlurEnabled.isOn;
        bloomEffect.enabled = BloomEnabled.isOn;
        dofEffect.enabled = DOFEnabled.isOn;
        colorgradingEffect.enabled = ColorGradingEnabled.isOn;
        tonemappingEffect.enabled = ToneMappingEnabled.isOn;
        oilpaintingEffect.enabled = OilPaintingEnabled.isOn;
        aoEffect.enabled = AOEnabled.isOn;

        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(1);
        }
    }
}
