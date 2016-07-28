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
                vertexDisplacement[i] = previousVertex[i] - (transform.position + (Vector3)(meshRenderer.localToWorldMatrix.MultiplyPoint(currentVertex[i])));
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

    public void SewNormals()
    {
        if (!currentMesh)
        {
            currentMesh = new Mesh();
            meshRenderer.BakeMesh(currentMesh);
            currentMesh.UploadMeshData(false);
        }

        Vector3[] currentVertices = currentMesh.vertices;

        Dictionary<Vector3, List<int>> verticesIndices = new Dictionary<Vector3, List<int>>();
        for (int i = 0; i < currentVertices.Length; i++)
        {
            if (!verticesIndices.ContainsKey(currentVertices[i])) verticesIndices.Add(currentVertices[i], new List<int>());

            verticesIndices[currentVertices[i]].Add(i);
        }

        Vector3[] newNormals = new Vector3[currentVertices.Length];
        for (int i = 0; i < verticesIndices.Count; i++)
        {
            foreach (int index in verticesIndices[currentVertices[i]])
            {
                newNormals[index] += currentVertices[i];
                newNormals[index] = Vector3.Normalize(newNormals[index]);
            }
        }

        currentMesh.normals = newNormals;
        currentMesh.UploadMeshData(false);
    }

    /*void OnDrawGizmos()
    {
        if (currentMesh)
        {
            Vector3[] normals = currentMesh.normals;
            for (int i = 0; i < currentMesh.vertices.Length; i+=10)
            {
                Gizmos.color = new Color(Mathf.Max(Vector3.Dot(normals[i], -accelerationColors[i]), 0), Mathf.Max(Vector3.Dot(normals[i], -accelerationColors[i]), 0), Mathf.Max(Vector3.Dot(normals[i], -accelerationColors[i]), 0));
                Gizmos.DrawLine(transform.position + Quaternion.LookRotation(transform.forward, transform.up) * currentMesh.vertices[i], transform.position + Quaternion.LookRotation(transform.forward, transform.up) * currentMesh.vertices[i] + accelerationColors[i]);
                Gizmos.DrawLine(transform.position + Quaternion.LookRotation(transform.forward, transform.up) * currentMesh.vertices[i], transform.position + Quaternion.LookRotation(transform.forward, transform.up) * currentMesh.vertices[i] + Vector3.Normalize(normals[i]) / 10);
            }
        }
    }*/
}
