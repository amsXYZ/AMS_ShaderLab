using UnityEditor;
using AMSPostprocessingEffects;

[CustomEditor(typeof(DOFEffect))]
[CanEditMultipleObjects]
public class DOFEffectEditor : Editor {

    SerializedProperty focusObject;
    SerializedProperty focalDistance;
    SerializedProperty focalSize;
    SerializedProperty aperture;
    SerializedProperty maxBlurDistance;
    SerializedProperty HighQualityNearBlur;
    SerializedProperty Debug;

    // Get the values we'll control through this inspector.
    void OnEnable()
    {
        focusObject = serializedObject.FindProperty("focusObject");
        focalDistance = serializedObject.FindProperty("focalDistance");
        focalSize = serializedObject.FindProperty("focalSize");
        aperture = serializedObject.FindProperty("aperture");
        maxBlurDistance = serializedObject.FindProperty("maxBlurDistance");
        HighQualityNearBlur = serializedObject.FindProperty("HighQualityNearBlur");
        Debug = serializedObject.FindProperty("Debug");
    }

    public override void OnInspectorGUI()
    {
        // Update the changes on the serialized object.
        serializedObject.Update();

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Focal Plane Settings", EditorStyles.boldLabel);

        // Draw the focal distance property if there's no focus object.
        EditorGUILayout.PropertyField(focusObject);

        if (!focusObject.objectReferenceValue)
            EditorGUILayout.PropertyField(focalDistance);

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Lens settings", EditorStyles.boldLabel);

        EditorGUILayout.PropertyField(focalSize);
        EditorGUILayout.PropertyField(aperture);
        EditorGUILayout.PropertyField(maxBlurDistance);

        EditorGUILayout.Space();
        EditorGUILayout.PropertyField(HighQualityNearBlur);
        EditorGUILayout.PropertyField(Debug);

        // Apply the changes.
        serializedObject.ApplyModifiedProperties();
    }
}
