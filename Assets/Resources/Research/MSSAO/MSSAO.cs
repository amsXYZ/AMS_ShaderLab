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
        [Range(1, 5), Tooltip("Amount of AO levels to be calculated.")]
        public int levels = 5;
        [Range(1, 10), Tooltip("Maximum sampling radius.")]
        public float radius = 1;
        [Tooltip("Maximum radius (world space) for the occluding samples.")]
        public float maxRadiusDistance = 0.85f;
        [Range(3, 7), Tooltip("Maximum kernel sampling size.")]
        public int maxKernelSize = 5;
        [Range(0, 4), Tooltip("Intensity multiplier.")]
        public float intensity = 1;
        [Space]
        public bool debug = false;

        private Material _material;
        private Material _materialBlur;
        private Camera _camera;

        private float[] _poissonDisks = {-0.6116678f,  0.04548655f, -0.26605980f, -0.6445347f,
                                                -0.4798763f,  0.78557830f, -0.19723210f, -0.1348270f,
                                                -0.7351842f, -0.58396650f, -0.35353550f,  0.3798947f,
                                                0.1423388f,  0.39469180f, -0.01819171f,  0.8008046f,
                                                0.3313283f, -0.04656135f,  0.58593510f,  0.4467109f,
                                                0.8577477f,  0.11188750f,  0.03690137f, -0.9906120f,
                                                0.4768903f, -0.84335800f,  0.13749180f, -0.4746810f,
                                                0.7814927f, -0.48938420f,  0.38269190f,  0.8695006f };

        ////////////////////////////////////
        // Unity Editor related functions //
        ////////////////////////////////////

        // Creates the private materials used to the effect and get the camera component.
        void Awake()
        {
            _material = new Material(Shader.Find("Hidden/MSSAO"));
            _materialBlur = new Material(Shader.Find("Hidden/LowPassFilterAO"));
            _camera = GetComponent<Camera>();
            _camera.depthTextureMode = DepthTextureMode.DepthNormals;
        }

        // Methods used to take care of the materials when enabling/disabling the effects in the inspector.
        void OnDisable()
        {
            if (_material) DestroyImmediate(_material);
            _material = null;

            if (_materialBlur) DestroyImmediate(_materialBlur);
            _materialBlur = null;
        }
        void OnEnable()
        {
            if (!_material) _material = new Material(Shader.Find("Hidden/MSSAO"));
            if (!_materialBlur) _materialBlur = new Material(Shader.Find("Hidden/LowPassFilterAO"));
            if (!_camera) _camera = GetComponent<Camera>();
        }

        ///<summary>
        /// Get the effect's camera HDR flag.
        ///</summary>
        public bool HDR()
        {
            return _camera.hdr;
        }

        ////////////////////////////////////////
        // Post-processing effect application //
        ////////////////////////////////////////

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            // Declare the arrays we'll use to store both vertex normals and world positions at different resolutions.
            RenderTexture[] normalTextures = new RenderTexture[levels];
            RenderTexture[] posTextures = new RenderTexture[levels];

            // Store the normals and world position for each downsampled version of the camera buffer.
            for (int i = levels - 1; i >= 0; i--)
            {
                int rtW = source.width / (int)Mathf.Pow(2, i);
                int rtH = source.height / (int)Mathf.Pow(2, i);

                // Always use floating point precission buffer to avoid artifacts.
                RenderTexture bufferNorm = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                RenderTexture bufferPos = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                
                Graphics.Blit(source, bufferNorm, _material, 0);
                normalTextures[i] = bufferNorm;
                Graphics.Blit(source, bufferPos, _material, 1);
                posTextures[i] = bufferPos;

                RenderTexture.ReleaseTemporary(bufferNorm);
                RenderTexture.ReleaseTemporary(bufferPos);
            }

            //Determine the format of the render texture we'll use.
            RenderTextureFormat rtFormat;
            if (_camera.hdr)
            {
                if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBFloat)) rtFormat = RenderTextureFormat.ARGBFloat;
                else rtFormat = RenderTextureFormat.DefaultHDR;
            }
            else rtFormat = RenderTextureFormat.Default;

            // Declare the array for all the different AO levels.
            RenderTexture[] aoTextures = new RenderTexture[levels];
            for (int i = levels - 1; i >= 0; i--)
            {
                // Setup the render texture and all the uniforms required by the shader.

                int rtW = source.width / (int)Mathf.Pow(2, i);
                int rtH = source.height / (int)Mathf.Pow(2, i);
                RenderTexture bufferAO = RenderTexture.GetTemporary(rtW, rtH, 1, rtFormat, RenderTextureReadWrite.Linear);

                _material.SetFloat("_maxDist", maxRadiusDistance);
                _material.SetFloat("_maxKernelSize", maxKernelSize);
                float r = GetComponent<Camera>().pixelHeight * maxRadiusDistance / (2.0f * Mathf.Abs(Mathf.Tan(Mathf.Deg2Rad * GetComponent<Camera>().fieldOfView / 2.0f)));
                r = r / Mathf.Pow(2, i);
                _material.SetFloat("_r", r);
                _material.SetFloat("_Radius", radius);

                _material.SetTexture("_normTex", normalTextures[i]);
                _material.SetTexture("_posTex", posTextures[i]);

                // If we're not rendering the first pass, we'll use the previous normals, position and AO texture to calculate the new far AO value.
                if (i == levels - 1) Graphics.Blit(source, bufferAO, _material, 2);
                else
                {
                    _material.SetTexture("_lowResNormTex", normalTextures[i+1]);
                    _material.SetTexture("_lowResPosTex", posTextures[i+1]);

                    // Blur the AO Texture
                    if (!_materialBlur) _materialBlur = new Material(Shader.Find("Hidden/LowPassFilterAO"));
                    _materialBlur.SetTexture("_AOTexture", aoTextures[i + 1]);
                    _materialBlur.SetTexture("_NormalTexture", normalTextures[i + 1]);
                    _materialBlur.SetTexture("_PosTexture", posTextures[i + 1]);

                    // Calculate the new far AO texture.
                    RenderTexture bufferAOBlur = RenderTexture.GetTemporary(rtW/2, rtH/2, 0, rtFormat, RenderTextureReadWrite.Linear);
                    Graphics.Blit(source, bufferAOBlur, _materialBlur, 0);
                    aoTextures[i+1] = bufferAOBlur;
                    RenderTexture.ReleaseTemporary(bufferAOBlur);
                    _material.SetTexture("_AOFar", aoTextures[i+1]);

                    // Calculate the final AO value for this level.
                    // If we're rendering the last AO value, we'll use a poisson disk filter to improve the quality of the sampling.
                    if (i == 0)
                    {
                        _material.SetFloatArray("_PoissonDisks", _poissonDisks);

                        Graphics.Blit(source, bufferAO, _material, 4);
                    }
                    else Graphics.Blit(source, bufferAO, _material, 3);
                }

                aoTextures[i] = bufferAO;
                RenderTexture.ReleaseTemporary(bufferAO);
            }

            _material.SetTexture("_AOFinal", aoTextures[0]);

            if (levels == 1) _material.SetInt("_singleAO", 1);
            else _material.SetInt("_singleAO", 0);

            _material.SetInt("_Debug", debug ? 1 : 0);
            _material.SetFloat("_Intensity", intensity);

            Graphics.Blit(source, destination, _material, 5);
            return;
        }
    }
}
