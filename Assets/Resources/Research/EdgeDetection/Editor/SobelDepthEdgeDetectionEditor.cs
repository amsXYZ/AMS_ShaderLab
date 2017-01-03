using UnityEditor;
using AMSPostprocessingEffects;

[CustomEditor(typeof(SobelDepthEdgeDetection))]
[CanEditMultipleObjects]
public class SobelDepthEdgeDetectionEditor : Editor
{
    SerializedProperty sensitivityDepth;
    SerializedProperty sensitivityNormals;

    // Get the values we'll control through this inspector.
    void OnEnable()
    {
        sensitivityDepth = serializedObject.FindProperty("sensitivityDepth");
        sensitivityNormals = serializedObject.FindProperty("sensitivityNormals");
    }

    public override void OnInspectorGUI()
    {
        // Update the changes on the serialized object.
        serializedObject.Update();

        // Draw the default inspector.
        DrawDefaultInspector();

        // Clamp the negative values of threshold to 0.
        if (sensitivityDepth.floatValue < 0.0f) sensitivityDepth.floatValue = 0.0f;
        if (sensitivityNormals.floatValue < 0.0f) sensitivityNormals.floatValue = 0.0f;

        // Apply the changes.
        serializedObject.ApplyModifiedProperties();
    }
}
