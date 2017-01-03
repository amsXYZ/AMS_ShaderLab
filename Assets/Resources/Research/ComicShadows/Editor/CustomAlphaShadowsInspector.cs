using System;
using UnityEngine;

namespace UnityEditor
{
    internal class CustomAlphaShadowsInspector : ShaderGUI
    {
        public enum BlendMode
        {
            Opaque,
            Cutout
        }

        // Class used to store all the stings and tooltips used by the inspector.
        private static class Styles
        {
            public static GUIContent albedoText = new GUIContent("Albedo", "Albedo without transparency (RGB)");
            public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");
            public static GUIContent normalText = new GUIContent("Normal Map", "Map used to add surface bumpiness");
            public static GUIContent emissionText = new GUIContent("Emission Map", "Map used to self-illuminate the material");
            public static GUIContent emissionColorText = new GUIContent("Emission Color", "Color of the emissive regions");
            public static GUIContent hueText = new GUIContent("Hue", "Offsets the albedo hue in the HSV color space");
            public static GUIContent saturationText = new GUIContent("Saturation", "Offsets the albedo saturation in the HSV color space");
            public static GUIContent valueText = new GUIContent("Value", "Offsets the albedo brightness in the HSV color space");

            public static string whiteSpaceString = " ";
            public static string primaryMapsText = "Main Maps";
            public static string hsvText = "HSV Color Adjustments";
            public static string renderingMode = "Rendering Mode";
            public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));
        }

        MaterialProperty _blendMode = null;
        MaterialProperty _albedoMap = null;
        MaterialProperty _alphaCutoff = null;
        MaterialProperty _normalMap = null;
        MaterialProperty _emissionMap = null;
        MaterialProperty _emissionColor = null;
        MaterialProperty _hue = null;
        MaterialProperty _saturation = null;
        MaterialProperty _value = null;

        MaterialEditor _materialEditor;
        ColorPickerHDRConfig _ColorPickerHDRConfig = new ColorPickerHDRConfig(0f, 99f, 1 / 99f, 3f);

        bool _firstTimeApply = true;

        public void FindProperties(MaterialProperty[] props)
        {
            _blendMode = FindProperty("_Mode", props);
            _albedoMap = FindProperty("_MainTex", props);
            _alphaCutoff = FindProperty("_Cutoff", props);
            _normalMap = FindProperty("_NormalMap", props);
            _emissionMap = FindProperty("_EmissionMap", props);
            _emissionColor = FindProperty("_EmissionColor", props);
            _hue = FindProperty("_Hue", props);
            _saturation = FindProperty("_Saturation", props);
            _value = FindProperty("_Value", props);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
            _materialEditor = materialEditor;
            Material material = materialEditor.target as Material;

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a standard shader.
            // Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
            if (_firstTimeApply)
            {
                switch ((BlendMode)material.GetFloat("_Mode"))
                {
                    case BlendMode.Opaque:
                        material.SetOverrideTag("RenderType", "Opaque");
                        material.DisableKeyword("_ALPHATEST_ON");
                        material.renderQueue = -1;
                        break;
                    case BlendMode.Cutout:
                        material.SetOverrideTag("RenderType", "TransparentCutout");
                        material.EnableKeyword("_ALPHATEST_ON");
                        material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                        break;
                }

                _firstTimeApply = false;
            }

            ShaderPropertiesGUI(material);
        }

        public void ShaderPropertiesGUI(Material material)
        {
            // Use default labelWidth
            EditorGUIUtility.labelWidth = 0f;

            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            {
                // Blend mode
                BlendModePopup();

                // Primary properties
                GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
                
                // Albedo
                _materialEditor.TexturePropertySingleLine(Styles.albedoText, _albedoMap);
                if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout))
                {
                    _materialEditor.ShaderProperty(_alphaCutoff, Styles.alphaCutoffText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
                }

                // Normal
                _materialEditor.TexturePropertySingleLine(Styles.normalText, _normalMap);

                // Emission
                bool hadEmissionTexture = _emissionMap.textureValue != null;

                // Texture and HDR color controls
                _materialEditor.TexturePropertyWithHDRColor(Styles.emissionText, _emissionMap, _emissionColor, _ColorPickerHDRConfig, false);

                // If texture was assigned and color was black set color to white
                float brightness = _emissionColor.colorValue.maxColorComponent;
                if (_emissionMap.textureValue != null && !hadEmissionTexture && brightness <= 0f)
                    _emissionColor.colorValue = Color.white;

                // Draw the tiliding and offset panels of the albedo map (which we'll use for the other textures too)
                EditorGUI.BeginChangeCheck();
                _materialEditor.TextureScaleOffsetProperty(_albedoMap);
                if (EditorGUI.EndChangeCheck())
                    _emissionMap.textureScaleAndOffset = _normalMap.textureScaleAndOffset = _albedoMap.textureScaleAndOffset;

                // HSV
                GUILayout.Label(Styles.hsvText, EditorStyles.boldLabel);
                _materialEditor.ShaderProperty(_hue, Styles.hueText.text);
                _materialEditor.ShaderProperty(_saturation, Styles.saturationText.text);
                _materialEditor.ShaderProperty(_value, Styles.valueText.text);

            }
            if (EditorGUI.EndChangeCheck())
            {
                // Set again the rendering tags and keywords
                foreach (var obj in _blendMode.targets)
                {
                    Material mat = (Material)obj;
                    switch ((BlendMode)mat.GetFloat("_Mode"))
                    {
                        case BlendMode.Opaque:
                            mat.SetOverrideTag("RenderType", "Opaque");
                            mat.DisableKeyword("_ALPHATEST_ON");
                            mat.renderQueue = -1;
                            break;
                        case BlendMode.Cutout:
                            mat.SetOverrideTag("RenderType", "TransparentCutout");
                            mat.EnableKeyword("_ALPHATEST_ON");
                            mat.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                            break;
                    }
                }
            }
        }

        // Draw the blending mode popup
        void BlendModePopup()
        {
            EditorGUI.showMixedValue = _blendMode.hasMixedValue;
            var mode = (BlendMode)_blendMode.floatValue;

            EditorGUI.BeginChangeCheck();
            mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                _blendMode.floatValue = (float)mode;
            }

            EditorGUI.showMixedValue = false;
        }
    }
}