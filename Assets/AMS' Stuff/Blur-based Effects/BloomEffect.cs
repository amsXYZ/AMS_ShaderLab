using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class BloomEffect : MonoBehaviour
    {
        [Range(0, 4)]
        public float threshold = 0.5f;

        public float intensity = 1;

        [Range(0, 3)]
        public int downsampling = 2;

        [Range(0, 10)]
        public int iterations = 3;

        [Range(0.0f, 1.0f)]
        public float blurSpread = 0.6f;

        private Material materialBlur;
        private Material materialBloom;

        //Creates a private material used to the effect
        void Awake()
        {
            materialBlur = new Material(Shader.Find("Hidden/Blur"));
            materialBloom = new Material(Shader.Find("Hidden/Bloom"));
        }

        // Performs one blur iteration.
        public void FourTapCone(RenderTexture source, RenderTexture dest, int iteration)
        {
            float off = 0.5f + iteration * blurSpread;
            Graphics.BlitMultiTap(source, dest, materialBlur,
                                   new Vector2(-off, -off),
                                   new Vector2(-off, off),
                                   new Vector2(off, off),
                                   new Vector2(off, -off)
                );
        }

        // Downsamples the texture to a quarter resolution.
        private void DownSample4x(RenderTexture source, RenderTexture dest)
        {
            float off = 1.0f;
            Graphics.BlitMultiTap(source, dest, materialBlur,
                                   new Vector2(-off, -off),
                                   new Vector2(-off, off),
                                   new Vector2(off, off),
                                   new Vector2(off, -off)
                );
        }

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            //Downsample the texture
            //Blur it
            //Add it as with add mode

            int rtW = source.width / (int) Mathf.Pow(2, downsampling);
            int rtH = source.height / (int) Mathf.Pow(2, downsampling);
            RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);

            // Copy source to the 4x4 smaller texture.
            DownSample4x(source, buffer);

            materialBloom.SetFloat("_BloomThreshold", threshold);
            Graphics.Blit(buffer, buffer, materialBloom,0);

            // Blur the small texture
            for (int i = 0; i < iterations; i++)
            {
                RenderTexture buffer2 = RenderTexture.GetTemporary(rtW, rtH, 0);
                FourTapCone(buffer, buffer2, i);
                RenderTexture.ReleaseTemporary(buffer);
                buffer = buffer2;
            }
            materialBloom.SetFloat("_BloomIntensity", intensity);
            materialBloom.SetTexture("_OriginalTex", source);
            Graphics.Blit(buffer, destination, materialBloom, 1);

            RenderTexture.ReleaseTemporary(buffer);
        }
    }
}
