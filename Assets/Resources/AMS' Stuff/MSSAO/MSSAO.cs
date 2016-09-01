using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class MSSAO : MonoBehaviour
    {
        [Range(1, 5)]
        public int levels = 5;
        [Range(1, 10)]
        public float radius = 1;
        [Range(0, 4)]
        public float intensity = 1;
        public float maxRadiusDistance = 2;
        [Range(3,7)]
        public int maxKernelSize = 5;

        public bool debug = false;

        private Material material;
        private Material materialBlur;

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
                RenderTexture bufferNorm = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                RenderTexture bufferPos = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

                if (!material) material = new Material(Shader.Find("Hidden/MSSAO"));
                
                Graphics.Blit(source, bufferNorm, material, 0);
                normalTextures[i] = bufferNorm;
                Graphics.Blit(source, bufferPos, material, 1);
                posTextures[i] = bufferPos;

                RenderTexture.ReleaseTemporary(bufferNorm);
                RenderTexture.ReleaseTemporary(bufferPos);
            }

            RenderTexture[] aoTextures = new RenderTexture[levels];

            for (int i = levels - 1; i >= 0; i--)
            {
                int rtW = source.width / (int)Mathf.Pow(2, i);
                int rtH = source.height / (int)Mathf.Pow(2, i);
                RenderTexture bufferAO = RenderTexture.GetTemporary(rtW, rtH, 1, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

                if (!material) material = new Material(Shader.Find("Hidden/MSSAO"));

                material.SetFloat("_maxDist", maxRadiusDistance);
                material.SetFloat("_maxKernelSize", maxKernelSize);
                float r = GetComponent<Camera>().pixelHeight * maxRadiusDistance / (2.0f * Mathf.Abs(Mathf.Tan(Mathf.Deg2Rad * GetComponent<Camera>().fieldOfView / 2.0f)));
                r = r / Mathf.Pow(2, i);
                material.SetFloat("_r", r);
                material.SetFloat("_Radius", radius);

                material.SetTexture("_normTex", normalTextures[i]);
                material.SetTexture("_posTex", posTextures[i]);

                if (i == levels - 1) Graphics.Blit(source, bufferAO, material, 2);
                else
                {
                    material.SetTexture("_lowResNormTex", normalTextures[i+1]);
                    material.SetTexture("_lowResPosTex", posTextures[i+1]);

                    //Blur the AO Texture
                    if (!materialBlur) materialBlur = new Material(Shader.Find("Hidden/LowPassFilterAO"));
                    materialBlur.SetTexture("_AOTexture", aoTextures[i + 1]);
                    materialBlur.SetTexture("_NormalTexture", normalTextures[i + 1]);
                    materialBlur.SetTexture("_PosTexture", posTextures[i + 1]);

                    RenderTexture bufferAOBlur = RenderTexture.GetTemporary(rtW/2, rtH/2, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                    Graphics.Blit(source, bufferAOBlur, materialBlur, 0);
                    aoTextures[i+1] = bufferAOBlur;
                    RenderTexture.ReleaseTemporary(bufferAOBlur);

                    material.SetTexture("_AOFar", aoTextures[i+1]);

                    if (i == 0)
                    {
                        float[] poissonDisks = {-0.6116678f,  0.04548655f, -0.26605980f, -0.6445347f,
                                                -0.4798763f,  0.78557830f, -0.19723210f, -0.1348270f,
                                                -0.7351842f, -0.58396650f, -0.35353550f,  0.3798947f,
                                                0.1423388f,  0.39469180f, -0.01819171f,  0.8008046f,
                                                0.3313283f, -0.04656135f,  0.58593510f,  0.4467109f,
                                                0.8577477f,  0.11188750f,  0.03690137f, -0.9906120f,
                                                0.4768903f, -0.84335800f,  0.13749180f, -0.4746810f,
                                                0.7814927f, -0.48938420f,  0.38269190f,  0.8695006f };

                        material.SetFloatArray("_PoissonDisks", poissonDisks);

                        Graphics.Blit(source, bufferAO, material, 4);
                    }
                    else Graphics.Blit(source, bufferAO, material, 3);
                }

                aoTextures[i] = bufferAO;
                RenderTexture.ReleaseTemporary(bufferAO);
            }

            material.SetTexture("_AOFinal", aoTextures[0]);

            if (levels == 1) material.SetInt("_singleAO", 1);
            else material.SetInt("_singleAO", 0);

            material.SetInt("_Debug", debug ? 1 : 0);
            material.SetFloat("_Intensity", intensity);

            Graphics.Blit(source, destination, material, 5);
            return;
        }
    }
}
