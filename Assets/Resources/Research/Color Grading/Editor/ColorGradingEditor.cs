using UnityEditor;
using UnityEngine;
using AMSPostprocessingEffects;

[CustomEditor(typeof(ColorGrading))]
[CanEditMultipleObjects]
public class ColorGradingEditor : Editor
{

    public override void OnInspectorGUI()
    {
        // Update the changes on the serialized object.
        serializedObject.Update();

        // Draw the default inspector.
        DrawDefaultInspector();

        // Check if the Generate LUT button has been pressed, and if so, create a texture2D asset.
        if (GUILayout.Button("Generate LUT"))
        {
            string path = EditorUtility.SaveFilePanelInProject("Export LUT", "LUT.png", "png", "Please name the LUT file.");

            if (!string.IsNullOrEmpty(path))
            {
                Texture2D lut = ((ColorGrading)serializedObject.targetObject).GenerateLUT(path);

                byte[] bytes = lut.EncodeToPNG();
                System.IO.File.WriteAllBytes(path, bytes);
                DestroyImmediate(lut);

                AssetDatabase.Refresh();
                TextureImporter importer = (TextureImporter)AssetImporter.GetAtPath(path);

                importer.textureType = TextureImporterType.Advanced;
                importer.isReadable = true;
                importer.anisoLevel = 0;
                importer.mipmapEnabled = false;
                importer.linearTexture = true;
                importer.textureFormat = TextureImporterFormat.RGB24;
                importer.SaveAndReimport();

                Debug.Log(string.Format("File saved at path: {0}", path));
            } else Debug.LogError("Failed when saving LUT file.");
        }

        // Apply the changes.
        serializedObject.ApplyModifiedProperties();
    }
}
