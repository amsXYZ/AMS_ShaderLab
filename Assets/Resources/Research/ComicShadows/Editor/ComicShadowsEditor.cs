using UnityEditor;
using AMSPostprocessingEffects;

[CustomEditor(typeof(ComicShadows))]
[CanEditMultipleObjects]
public class ComicShadowsEditor : Editor
{
    SerializedProperty shadowType;
    SerializedProperty shadowColor;
    SerializedProperty levels;
    SerializedProperty angle;
    SerializedProperty frequency;
    SerializedProperty size;
    SerializedProperty separation;

    // Get the values we'll control through this inspector.
    void OnEnable()
    {
        shadowType = serializedObject.FindProperty("shadowType");
        shadowColor = serializedObject.FindProperty("shadowColor");
        levels = serializedObject.FindProperty("levels");
        angle = serializedObject.FindProperty("angle");
        frequency = serializedObject.FindProperty("frequency");
        size = serializedObject.FindProperty("size");
        separation = serializedObject.FindProperty("separation");
    }

    public override void OnInspectorGUI()
    {
        // Update the changes on the serialized object.
        serializedObject.Update();

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Shadow Settings", EditorStyles.boldLabel);

        // Draw the properties based on the shadowType and control their values.
        EditorGUILayout.PropertyField(shadowType);

        if (shadowType.enumValueIndex != (int)ComicShadows.ToonShadows.Debug)
            EditorGUILayout.PropertyField(shadowColor);

        EditorGUILayout.PropertyField(levels);
        if (levels.floatValue < 2.0f) levels.floatValue = 2.0f;

        if (shadowType.enumValueIndex != (int)ComicShadows.ToonShadows.Debug)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Shadow Pattern Settings", EditorStyles.boldLabel);

            EditorGUILayout.PropertyField(angle);
            EditorGUILayout.PropertyField(frequency);
            EditorGUILayout.PropertyField(size);
            EditorGUILayout.PropertyField(separation);

            if (angle.floatValue < 0.0f) angle.floatValue = 0.0f;
            else if (angle.floatValue > 180.0f) angle.floatValue = 180.0f;

            if (frequency.floatValue < 0.0f) frequency.floatValue = 0.0f;

            if (size.floatValue < 0.0f) size.floatValue = 0.0f;
            else if (size.floatValue > 10.0f) size.floatValue = 10.0f;

            if (separation.floatValue < 0.0f) separation.floatValue = 0.0f;
        }

        // Apply the changes.
        serializedObject.ApplyModifiedProperties();
    }
}
