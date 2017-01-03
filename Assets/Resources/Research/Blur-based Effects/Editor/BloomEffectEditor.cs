using UnityEditor;
using AMSPostprocessingEffects;

[CustomEditor(typeof(BloomEffect))]
[CanEditMultipleObjects]
public class BloomEffectEditor : Editor
{
    SerializedProperty threshold;
    SerializedProperty intensity;

    // Get the values we'll control through this inspector: threshold and intensity.
    void OnEnable()
    {
        threshold = serializedObject.FindProperty("threshold");
        intensity = serializedObject.FindProperty("intensity");
    }

    public override void OnInspectorGUI()
    {
        // Update the changes on the serialized object.
        serializedObject.Update();

        // Draw the default inspector.
        DrawDefaultInspector();

        // Clamp the negative values of threshold to 0 and the positive values depending if the camera supports HDR or not.
        if (threshold.floatValue < 0.0f) threshold.floatValue = 0.0f;
        if (threshold.floatValue > 1.0f && !((BloomEffect)serializedObject.targetObject).HDR()) threshold.floatValue = 1.0f;

        // Clamp the negative values of inthensity to 0.
        if (intensity.floatValue < 0.0f) intensity.floatValue = 0.0f;

        // Apply the changes.
        serializedObject.ApplyModifiedProperties();
    }
}