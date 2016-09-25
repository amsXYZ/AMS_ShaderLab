using UnityEngine;
using System.Collections.Generic;

public class Smear : MonoBehaviour
{
	[Range(0.1f, 20)]
	public float smearDecceleration;
	public ComputeShader shader;

	private Mesh _previousFrameMesh;
	private Mesh _currentMesh;
	private Vector3[] _accelerationColors;
	private SkinnedMeshRenderer _meshRenderer;

	void LateUpdate()
	{
		if (!_currentMesh)
			_currentMesh = new Mesh();

		if (!_meshRenderer)
			_meshRenderer = GetComponent<SkinnedMeshRenderer>();

		if (_previousFrameMesh)
		{
			// Bake the current vertex data into an array and load the previous vertex data into another one.
			_meshRenderer.BakeMesh(_currentMesh);
			_currentMesh.UploadMeshData(false);
			Vector3[] currentVertices = _currentMesh.vertices;
			Vector3[] previousVertices = _previousFrameMesh.vertices;

			// If there's acceleration information, create a new array to store it.
			if (_accelerationColors == null)
				_accelerationColors = new Vector3[_currentMesh.vertices.Length];

			Vector3[] vertexDisplacement = new Vector3[currentVertices.Length];
			List<Color> colors = new List<Color>();

			for (int i = 0; i < currentVertices.Length; i++)
			{
				// Calculate how much has that vertex has being displaced in the last frame.
				vertexDisplacement[i] = previousVertices[i] - _meshRenderer.localToWorldMatrix.MultiplyPoint(currentVertices[i]);

				// Add that movement to the acceleration colors (and clamp it).
				_accelerationColors[i] = Vector3.ClampMagnitude(_accelerationColors[i] + vertexDisplacement[i] / 10, 1);
				colors.Add(new Color(_accelerationColors[i].x, _accelerationColors[i].y, _accelerationColors[i].z, 1));
			}

			// Pass the acceleration information as input for the vertex colors.
			_meshRenderer.sharedMesh.SetColors(colors);
			_meshRenderer.sharedMesh.UploadMeshData(false);
		}

		// Bake the current mesh to be used in next frames.
		if (!_previousFrameMesh)
			_previousFrameMesh = new Mesh();
		_meshRenderer.BakeMesh(_previousFrameMesh);

		// Setup the RWBuffer we're gonna use to effiicently apply the current transformation matrix to all the vertices.
		ComputeBuffer buffer = new ComputeBuffer(_previousFrameMesh.vertices.Length, 3 * sizeof(float));
		buffer.SetData(_previousFrameMesh.vertices);

		// Setup the variables that the command buffer will use.
		int kernel = shader.FindKernel("CSMain");
		shader.SetBuffer(kernel, "vertexPositions", buffer);
		shader.SetVector("Position", transform.position);
		shader.SetVector("MV0", _meshRenderer.localToWorldMatrix.GetRow(0));
		shader.SetVector("MV1", _meshRenderer.localToWorldMatrix.GetRow(1));
		shader.SetVector("MV2", _meshRenderer.localToWorldMatrix.GetRow(2));
		shader.SetVector("MV3", _meshRenderer.localToWorldMatrix.GetRow(3));

		// Dispatch it.
		shader.Dispatch(kernel, _previousFrameMesh.vertices.Length, 1, 1);

		// Retrieve the data and upload the previous mesh.
		Vector3[] data = new Vector3[_previousFrameMesh.vertices.Length];
		buffer.GetData(data);
		buffer.Release();
		_previousFrameMesh.vertices = data;
		_previousFrameMesh.UploadMeshData(false);

		// Decrease the strength of the acceleration colors overtime.
		if (_accelerationColors != null)
		{
			for (int i = 0; i < _accelerationColors.Length; i++)
			{
				_accelerationColors[i] = Vector3.Lerp(_accelerationColors[i], Vector3.zero, Time.deltaTime * smearDecceleration * _accelerationColors[i].magnitude);
			}
		}
	}
}
