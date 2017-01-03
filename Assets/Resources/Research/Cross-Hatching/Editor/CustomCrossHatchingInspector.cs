using System;
using UnityEngine;

namespace UnityEditor
{
	internal class CustomCrossHatchingInspector : ShaderGUI
	{
		// Class used to store all the stings and tooltips used by the inspector.
		private static class Styles
		{
			public static GUIContent albedoText = new GUIContent("Albedo", "Albedo without transparency (RGB)");
			public static GUIContent normalText = new GUIContent("Normal Map", "Map used to add surface bumpiness");
			public static GUIContent tam0Text = new GUIContent("TAM 0", "Texture used for cross-hatched darkest zones");
			public static GUIContent tam1Text = new GUIContent("TAM 1", "Texture used for cross-hatched second most dark zones");
			public static GUIContent tam2Text = new GUIContent("TAM 2", "Texture used for cross-hatched dark zones");
			public static GUIContent tam3Text = new GUIContent("TAM 3", "Texture used for cross-hatched bright zones");
			public static GUIContent tam4Text = new GUIContent("TAM 4", "Texture used for cross-hatched second most bright zones");
			public static GUIContent tam5Text = new GUIContent("TAM 5", "Texture used for cross-hatched brightest zones");

			public static string whiteSpaceString = " ";
			public static string primaryMapsText = "Main Maps";
			public static string crossHatchingText = "Cross-hatching Tonal Art Maps";
		}

		MaterialProperty _albedoMap = null;
		MaterialProperty _normalMap = null;
		MaterialProperty _tam0 = null;
		MaterialProperty _tam1 = null;
		MaterialProperty _tam2 = null;
		MaterialProperty _tam3 = null;
		MaterialProperty _tam4 = null;
		MaterialProperty _tam5 = null;
		MaterialProperty _inkColor = null;

		MaterialEditor _materialEditor;
		bool _firstTime = true;

		public void FindProperties(MaterialProperty[] props)
		{
			_albedoMap = FindProperty("_MainTex", props);
			_normalMap = FindProperty("_NormalMap", props);
			_tam0 = FindProperty("_TAM0", props);
			_tam1 = FindProperty("_TAM1", props);
			_tam2 = FindProperty("_TAM2", props);
			_tam3 = FindProperty("_TAM3", props);
			_tam4 = FindProperty("_TAM4", props);
			_tam5 = FindProperty("_TAM5", props);
			_inkColor = FindProperty("_InkColor", props);
		}

		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
		{
			FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
			_materialEditor = materialEditor;
			Material material = materialEditor.target as Material;

			// Make sure that the first time the material is created, ink color's alpha is 1 (in order to see the proper shadows)
			if (_firstTime)
			{
				SetupTexArray(material);
				_firstTime = false;
			}

			ShaderPropertiesGUI(material);
		}

		private void ShaderPropertiesGUI(Material material)
		{
			// Use default labelWidth
			EditorGUIUtility.labelWidth = 0f;

            
			// Detect any changes to the material
			EditorGUI.BeginChangeCheck();
			{
				// Primary properties
				GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
                
				// Albedo, normal and uv scale/offset
				_materialEditor.TexturePropertySingleLine(Styles.albedoText, _albedoMap);
				_materialEditor.TexturePropertySingleLine(Styles.normalText, _normalMap);
				_materialEditor.TextureScaleOffsetProperty(_albedoMap);

				// Primary properties
				GUILayout.Label(Styles.crossHatchingText, EditorStyles.boldLabel);

				// Tonal Art Maps and uv scale/offset
				_materialEditor.TexturePropertySingleLine(Styles.tam0Text, _tam0);
				_materialEditor.TexturePropertySingleLine(Styles.tam1Text, _tam1);
				_materialEditor.TexturePropertySingleLine(Styles.tam2Text, _tam2);
				_materialEditor.TexturePropertySingleLine(Styles.tam3Text, _tam3);
				_materialEditor.TexturePropertySingleLine(Styles.tam4Text, _tam4);
				_materialEditor.TexturePropertySingleLine(Styles.tam5Text, _tam5);
				_materialEditor.TextureScaleOffsetProperty(_tam0);

				// Ink color
				_materialEditor.ColorProperty(_inkColor, "Ink Color");

                
			}
			// Setup the TAM texture array
			if (EditorGUI.EndChangeCheck())
				SetupTexArray(material);
		}

		private void SetupTexArray(Material material)
		{
			if (_tam0.textureValue && _tam1.textureValue && _tam2.textureValue && _tam3.textureValue && _tam4.textureValue && _tam5.textureValue)
			{
				Texture2DArray texArray = new Texture2DArray(_tam0.textureValue.width, _tam0.textureValue.height, 8, TextureFormat.RGB24, true);
				texArray.filterMode = FilterMode.Trilinear;
				texArray.anisoLevel = 16;
				texArray.wrapMode = TextureWrapMode.Repeat;

				texArray.SetPixels(((Texture2D)_tam0.textureValue).GetPixels(), 0);
				texArray.SetPixels(((Texture2D)_tam1.textureValue).GetPixels(), 1);
				texArray.SetPixels(((Texture2D)_tam2.textureValue).GetPixels(), 2);
				texArray.SetPixels(((Texture2D)_tam3.textureValue).GetPixels(), 3);
				texArray.SetPixels(((Texture2D)_tam4.textureValue).GetPixels(), 4);
				texArray.SetPixels(((Texture2D)_tam5.textureValue).GetPixels(), 5);
				texArray.Apply();

				material.SetTexture("_TAMTexArray", texArray);
			}
		}
	}
}