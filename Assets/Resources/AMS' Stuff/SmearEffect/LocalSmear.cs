using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class LocalSmear : MonoBehaviour
{
    [Range(0.1f,20)]
    public float smearDecceleration;
    public ComputeShader shader;

    private Mesh previousFrameMesh;
    private Mesh currentMesh;
    private Vector3[] accelerationColors;
    private Vector3 prevPosition;
    private SkinnedMeshRenderer meshRenderer;

    void LateUpdate()
    {
        if (!currentMesh) currentMesh = new Mesh();

        if (!meshRenderer) meshRenderer = GetComponent<SkinnedMeshRenderer>();

        if (previousFrameMesh)
        {
            meshRenderer.BakeMesh(currentMesh);
            currentMesh.UploadMeshData(false);
            Vector3[] currentVertex = currentMesh.vertices;
            Vector3[] currentNormals = currentMesh.normals;
            Vector3[] previousVertex = previousFrameMesh.vertices;
            if (accelerationColors == null) accelerationColors = new Vector3[currentMesh.vertices.Length];

            Vector3[] vertexDisplacement = new Vector3[currentVertex.Length];
            List<Color> colors = new List<Color>();

            for (int i = 0; i < currentVertex.Length; i++)
            {
                //Debug.DrawLine(previousVertex[i], meshRenderer.localToWorldMatrix.MultiplyPoint(currentVertex[i]), new Color(1,1,1,0.05f), 0.05f, true);

                vertexDisplacement[i] = previousVertex[i] - meshRenderer.localToWorldMatrix.MultiplyPoint(currentVertex[i]);
                accelerationColors[i] = Vector3.ClampMagnitude(accelerationColors[i] + vertexDisplacement[i] / 10, 1);

                colors.Add(new Color(accelerationColors[i].x, accelerationColors[i].y, accelerationColors[i].z, 1));
            }

            meshRenderer.sharedMesh.SetColors(colors);
            meshRenderer.sharedMesh.UploadMeshData(false);
        }

        if (!previousFrameMesh) previousFrameMesh = new Mesh();
        meshRenderer.BakeMesh(previousFrameMesh);

        ComputeBuffer buffer = new ComputeBuffer(previousFrameMesh.vertices.Length, 3 * sizeof(float));
        buffer.SetData(previousFrameMesh.vertices);
        int kernel = shader.FindKernel("CSMain");
        shader.SetBuffer(kernel, "vertexPositions", buffer);

        shader.SetVector("Position", transform.position);
        shader.SetVector("MV0", meshRenderer.localToWorldMatrix.GetRow(0));
        shader.SetVector("MV1", meshRenderer.localToWorldMatrix.GetRow(1));
        shader.SetVector("MV2", meshRenderer.localToWorldMatrix.GetRow(2));
        shader.SetVector("MV3", meshRenderer.localToWorldMatrix.GetRow(3));

        shader.SetVector("Q0", new Vector3( 1 - Mathf.Pow(2*transform.rotation.y, 2) - Mathf.Pow(2 * transform.rotation.z, 2),
                                            2*transform.rotation.x*transform.rotation.y - 2*transform.rotation.z*transform.rotation.w,
                                            2 * transform.rotation.x * transform.rotation.z + 2 * transform.rotation.y * transform.rotation.w));

        shader.SetVector("Q1", new Vector3( 2 * transform.rotation.x * transform.rotation.y + 2 * transform.rotation.z * transform.rotation.w,
                                            1 - Mathf.Pow(2 * transform.rotation.x, 2) - Mathf.Pow(2 * transform.rotation.z, 2),
                                            2 * transform.rotation.y * transform.rotation.z - 2 * transform.rotation.x * transform.rotation.w));

        shader.SetVector("Q1", new Vector3(2 * transform.rotation.x * transform.rotation.z - 2 * transform.rotation.y * transform.rotation.z,
                                            2 * transform.rotation.y * transform.rotation.z + 2 * transform.rotation.x * transform.rotation.w,
                                            1 - Mathf.Pow(2 * transform.rotation.x, 2) - Mathf.Pow(2 * transform.rotation.y, 2)));

        shader.Dispatch(kernel, previousFrameMesh.vertices.Length, 1, 1);

        Vector3[] data = new Vector3[previousFrameMesh.vertices.Length];
        buffer.GetData(data);
        buffer.Release();
        previousFrameMesh.vertices = data;
        previousFrameMesh.UploadMeshData(false);

        if (accelerationColors != null)
        {
            for (int i = 0; i < accelerationColors.Length; i++)
            {
                accelerationColors[i] = Vector3.Lerp(accelerationColors[i], Vector3.zero, Time.deltaTime * smearDecceleration * accelerationColors[i].magnitude);
            }
        }

        prevPosition = transform.position;
    }
}
