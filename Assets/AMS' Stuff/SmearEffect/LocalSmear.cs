using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class LocalSmear : MonoBehaviour
{

    private Mesh previousFrameMesh;
    private Mesh currentMesh;
    private Vector3[] accelerationColors;

    [Range(0.1f,3)]
    public float smearDecceleration;

    private Vector3 prevPosition;

    public ComputeShader shader;

	void LateUpdate()
	{
        if(!currentMesh) currentMesh = new Mesh();

        if (previousFrameMesh) 
        {
            GetComponent<SkinnedMeshRenderer>().BakeMesh(currentMesh);
            currentMesh.UploadMeshData(false);
            Vector3[] currentVertex = currentMesh.vertices;
            Vector3[] previousVertex = previousFrameMesh.vertices;
            if (accelerationColors == null) accelerationColors = new Vector3[currentMesh.vertices.Length];

            Vector3[] vertexDisplacement = new Vector3[currentVertex.Length];
            List<Color> colors = new List<Color>();
            for (int i = 0; i < currentVertex.Length; i++)
            {
                vertexDisplacement[i] = (transform.position + currentVertex[i]) - previousVertex[i];
                accelerationColors[i] = Vector3.ClampMagnitude(accelerationColors[i] + vertexDisplacement[i] * 1/10,1);

                colors.Add(new Color(accelerationColors[i].x, accelerationColors[i].y, accelerationColors[i].z, 1));
            }

            GetComponent<SkinnedMeshRenderer>().sharedMesh.SetColors(colors);
            GetComponent<SkinnedMeshRenderer>().sharedMesh.UploadMeshData(false);
        }

        if (!previousFrameMesh) previousFrameMesh = new Mesh();

        GetComponent<SkinnedMeshRenderer>().BakeMesh(previousFrameMesh);

        ComputeBuffer buffer = new ComputeBuffer(previousFrameMesh.vertices.Length, 3 * sizeof(float));

        buffer.SetData(previousFrameMesh.vertices);

        int kernel = shader.FindKernel("CSMain");

        shader.SetBuffer(kernel, "vertexPositions", buffer);

        float[] positions = new float[3];
        positions[0] = transform.position.x;
        positions[1] = transform.position.y;
        positions[2] = transform.position.z;

        shader.SetFloats("position", positions);

        shader.Dispatch(kernel, previousFrameMesh.vertices.Length, 1, 1);

        Vector3[] data = new Vector3[previousFrameMesh.vertices.Length];

        buffer.GetData(data);

        buffer.Release();

        previousFrameMesh.vertices = data;

        previousFrameMesh.UploadMeshData(false);

        prevPosition = transform.position;
        if (accelerationColors != null)
        {
            for (int i = 0; i < accelerationColors.Length; i++)
            {
                accelerationColors[i] = Vector3.Lerp(accelerationColors[i], Vector3.zero, Time.deltaTime * smearDecceleration / accelerationColors[i].magnitude);
            }
        }
    }
}
