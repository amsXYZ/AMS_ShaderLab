using UnityEditor;
using UnityEngine;
using AMSPostprocessingEffects;

[CustomEditor(typeof(HalftoneEffect))]
[CanEditMultipleObjects]
public class HalftoneEffectEditor : Editor
{
    SerializedProperty frequency;

    // Get the values we'll control through this inspector.
    void OnEnable()
    {
        frequency = serializedObject.FindProperty("frequency");
    }

    public override void OnInspectorGUI()
    {
        // Update the changes on the serialized object.
        serializedObject.Update();

        // Draw the default inspector.
        DrawDefaultInspector();

        // Get the camera minimum side's size in pixels and clamp the frequency to a fifth of it (also avoiding negative values).
        Camera camera = ((HalftoneEffect)target).GetCamera();
        if(camera)
        {
            float minScreenSide = Mathf.Min(camera.pixelWidth, camera.pixelHeight);
            if (frequency.floatValue > minScreenSide / 4) frequency.floatValue = minScreenSide / 4;
            else if (frequency.floatValue < 1) frequency.floatValue = 1;
        }

        // Apply the changes.
        serializedObject.ApplyModifiedProperties();
    }
}
