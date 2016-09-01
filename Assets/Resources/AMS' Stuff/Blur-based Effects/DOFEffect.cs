using UnityEngine;

namespace AMSPostprocessingEffects
{
    [ExecuteInEditMode]
#if UNITY_5_4_OR_NEWER
    [ImageEffectAllowedInSceneView]
#endif
    [RequireComponent(typeof(Camera))]
    public class DOFEffect : MonoBehaviour
    {

        public Transform focusObject;
        public float focalDistance = 10;

        [Range(0,2)]
        public float focalSize = 0.05f;
        [Range(0, 1)]
        public float aperture = 0.5f;
        [Range(0, 3)]
        public float maxBlurDistance = 1f;

        public bool Debug;

        private float internalBlurWidth = 1.0f;

        private Material material;
        private Material materialBlur;
        private Camera camera;

        //Creates a private material used to the effect
        void Awake()
        {
            //material = new Material(Shader.Find("Hidden/Dof/DepthOfFieldHdr"));
            material = new Material(Shader.Find("Hidden/DOF"));
            materialBlur = new Material(Shader.Find("Hidden/Blur"));
            camera = GetComponent<Camera>();
        }

        // Performs one blur iteration.
        public void FourTapCone(RenderTexture source, RenderTexture dest, int iteration)
        {
            float off = 0.5f + iteration * 1f;
            Graphics.BlitMultiTap(source, dest, material,
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
            Graphics.BlitMultiTap(source, dest, material,
                                   new Vector2(-off, -off),
                                   new Vector2(-off, off),
                                   new Vector2(off, off),
                                   new Vector2(off, -off)
                );
        }

        float CalculateDepth(float worldDist)
        {
            return camera.WorldToViewportPoint((worldDist - camera.nearClipPlane) * camera.transform.forward + camera.transform.position).z / (camera.farClipPlane - camera.nearClipPlane);
        }

        // Called by the camera to apply the image effect
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            material.SetFloat("_FocusDepth", (focusObject) ? (camera.WorldToViewportPoint(focusObject.position)).z / (camera.farClipPlane) : camera.WorldToViewportPoint((focalDistance - camera.nearClipPlane) * camera.transform.forward + camera.transform.position).z / (camera.farClipPlane - camera.nearClipPlane));
            material.SetFloat("_FocalSize", focalSize);
            material.SetFloat("_Aperture", 1.0f / (1.0f - aperture) - 1.0f);
            material.SetInt("_Debug", Debug ? 1 : 0);

            material.SetFloat("_FocalSize", focalSize);

            material.SetFloat("_MaxBlurDistance", maxBlurDistance);

            float[] poissonDisks = {-0.6116678f,  0.04548655f, -0.26605980f, -0.6445347f,
                                                -0.4798763f,  0.78557830f, -0.19723210f, -0.1348270f,
                                                -0.7351842f, -0.58396650f, -0.35353550f,  0.3798947f,
                                                0.1423388f,  0.39469180f, -0.01819171f,  0.8008046f,
                                                0.3313283f, -0.04656135f,  0.58593510f,  0.4467109f,
                                                0.8577477f,  0.11188750f,  0.03690137f, -0.9906120f,
                                                0.4768903f, -0.84335800f,  0.13749180f, -0.4746810f,
                                                0.7814927f, -0.48938420f,  0.38269190f,  0.8695006f };

            material.SetFloatArray("_PoissonDisks", poissonDisks);

            // Capture COC
            // Create the downsampled textures (being careful with preserving the coc)
            // Lerp between the 3D Texture using the coc

            // Calculate the coc
            RenderTexture FcocBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(source, FcocBuffer, material, 2);
            RenderTexture FdownsampledBufffer = RenderTexture.GetTemporary(source.width/2, source.height/2, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(FcocBuffer, FdownsampledBufffer, material, 4);
            RenderTexture FblurredBuffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(FdownsampledBufffer, FblurredBuffer, material, 5);

            RenderTexture BcocBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(source, BcocBuffer, material, 1);
            RenderTexture BdownsampledBufffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(BcocBuffer, BdownsampledBufffer, material, 4);
            RenderTexture BblurredBuffer = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(BdownsampledBufffer, BblurredBuffer, material, 5);

            RenderTexture cocBuffer = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.sRGB);
            Graphics.Blit(source, cocBuffer, material, 0);

            material.SetTexture("_downsampledBlurredB", BblurredBuffer);
            material.SetTexture("_downsampledBlurredF", FblurredBuffer);
            Graphics.Blit(cocBuffer, destination, material, 3);

            RenderTexture.ReleaseTemporary(FcocBuffer);
            RenderTexture.ReleaseTemporary(FdownsampledBufffer);
            RenderTexture.ReleaseTemporary(FblurredBuffer);
            RenderTexture.ReleaseTemporary(BcocBuffer);
            RenderTexture.ReleaseTemporary(BdownsampledBufffer);
            RenderTexture.ReleaseTemporary(BblurredBuffer);
            RenderTexture.ReleaseTemporary(cocBuffer);
        }
    }
}
