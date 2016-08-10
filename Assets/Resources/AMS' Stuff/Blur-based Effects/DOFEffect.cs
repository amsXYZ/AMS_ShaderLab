using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class DOFEffect : MonoBehaviour
    {

        public Transform focusObject;
        public float focalDistance = 10;

        [Range(0,2)]
        public float focalSize = 0.05f;
        [Range(0, 1)]
        public float aperture = 0.5f;
        //[Range(0.1f, 2)]
        //public float maxBlurSize = 0.5f;

        private float internalBlurWidth = 1.0f;

        private Material material;
        private Camera camera;

        //Creates a private material used to the effect
        void Awake()
        {
            //material = new Material(Shader.Find("Hidden/Dof/DepthOfFieldHdr"));
            material = new Material(Shader.Find("Hidden/DOF"));
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
            material.SetFloat("_FocusDepth", (focusObject != null) ? CalculateDepth(Vector3.Distance(focusObject.transform.position, camera.transform.position)) : CalculateDepth(focalDistance));
            material.SetFloat("_FocalSize", focalSize);
            material.SetFloat("_Aperture", 1.0f / (1.0f - aperture) - 1.0f);

            material.SetFloat("_FocalSize", focalSize);

            int rtW = source.width;
            int rtH = source.height;
            RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

            // Copy source to the 4x4 smaller texture.
            DownSample4x(source, buffer);

            // Blur the small texture
            for (int i = 0; i < 5; i++)
            {
                RenderTexture buffer2 = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                FourTapCone(buffer, buffer2, i);
                RenderTexture.ReleaseTemporary(buffer);
                buffer = buffer2;
            }
            Graphics.Blit(buffer, destination);

            RenderTexture.ReleaseTemporary(buffer);
        }
    }
}
