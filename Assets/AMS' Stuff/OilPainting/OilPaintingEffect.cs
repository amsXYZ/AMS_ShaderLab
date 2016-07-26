using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class OilPaintingEffect : MonoBehaviour
    {
        [Range(0,5)]
        public int samplingRadius = 3;

        [Range(1,4)]
        public float samplingDistance = 1;

        [Range(10,30)]
        public int intensity = 1;

        public Texture2D noiseTexture;

        [Range(0, 0.01f)]
        public float noiseStrength;

        private Material material;

        //Creates a private material used to the effect
        void Awake()
        {
            material = new Material(Shader.Find("Hidden/OilPainting"));
        }

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            material = new Material(Shader.Find("Hidden/OilPainting"));

            material.SetInt("_Radius", samplingRadius);
            material.SetFloat("_Distance", samplingDistance);
            material.SetInt("_Intensity", intensity);
            material.SetTexture("_NoiseTex", noiseTexture);
            material.SetFloat("_NoiseStrength", noiseStrength);

            Graphics.Blit(source, destination, material, 0);
            return;
        }
    }
}
