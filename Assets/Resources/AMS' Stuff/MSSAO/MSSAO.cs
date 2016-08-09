using UnityEngine;
using UnityEngine.Rendering;

namespace UnityStandardAssets.ImageEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class MSSAO : MonoBehaviour
    {
        [Range(1, 5)]
        public int levels;
        public float maxRadiusDistance = 2;
        public int maxKernelSize = 5;

        private Material material;

        //Creates a private material used to the effect
        void Awake()
        {
            material = new Material(Shader.Find("Hidden/MSSAO"));
            GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;
        }

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            RenderTexture[] normalTextures = new RenderTexture[levels];
            RenderTexture[] posTextures = new RenderTexture[levels];

            for (int i = levels - 1; i >= 0; i--)
            {
                int rtW = source.width / (int)Mathf.Pow(2, i);
                int rtH = source.height / (int)Mathf.Pow(2, i);
                RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

                if (!material) material = new Material(Shader.Find("Hidden/MSSAO"));

                Graphics.Blit(source, buffer, material, 0);
                normalTextures[i] = buffer;
                Graphics.Blit(source, buffer, material, 1);
                posTextures[i] = buffer;
                RenderTexture.ReleaseTemporary(buffer);
            }

            RenderTexture[] aoTextures = new RenderTexture[levels];

            for (int i = levels - 1; i >= 0; i--)
            {
                if (i == levels - 1)
                {
                    Texture2D white = Texture2D.whiteTexture;
                    material.SetTexture("_AOFar", white);
                }
                int rtW = source.width / (int)Mathf.Pow(2, i);
                int rtH = source.height / (int)Mathf.Pow(2, i);
                RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);

                if (!material) material = new Material(Shader.Find("Hidden/MSSAO"));

                //material.SetTexture("_NormalPosTex", normalPosTextures[i]);
                material.SetFloat("_FOV", GetComponent<Camera>().fieldOfView);
                material.SetFloat("_maxDist", maxRadiusDistance);
                material.SetInt("_maxKernelSize", maxKernelSize);
                float r = GetComponent<Camera>().pixelHeight * maxRadiusDistance / (2.0f * Mathf.Abs(Mathf.Tan(Mathf.Deg2Rad * GetComponent<Camera>().fieldOfView / 2.0f)));
                r = r / Mathf.Pow(2, i);
                material.SetFloat("_r", r);

                if (i == levels - 1) Graphics.Blit(source, buffer, material, 2);
                else if (i == 0)
                {
                    float[] poissonDisks = { -0.6116678f,  0.04548655f, -0.26605980f, -0.6445347f,
                    -0.4798763f,  0.78557830f, -0.19723210f, -0.1348270f,
                    -0.7351842f, -0.58396650f, -0.35353550f,  0.3798947f,
                    0.1423388f,  0.39469180f, -0.01819171f,  0.8008046f,
                    0.3313283f, -0.04656135f,  0.58593510f,  0.4467109f,
                    0.8577477f,  0.11188750f,  0.03690137f, -0.9906120f,
                    0.4768903f, -0.84335800f,  0.13749180f, -0.4746810f,
                    0.7814927f, -0.48938420f,  0.38269190f,  0.8695006f };

                    material.SetFloatArray("_PoissonDisks", poissonDisks);

                    Graphics.Blit(source, buffer, material, 4);
                }
                else Graphics.Blit(source, buffer, material, 3);

                aoTextures[i] = buffer;
                RenderTexture.ReleaseTemporary(buffer);

                material.SetTexture("_AOFar", aoTextures[i]);
            }

            Graphics.Blit(source, destination, material, 5);

            return;
        }
    }
}
