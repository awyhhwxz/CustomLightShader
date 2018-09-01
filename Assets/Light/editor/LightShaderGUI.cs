using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class LightShaderGUI : ShaderGUIBase
{
    enum SmoothnessSource
    {
        Uniform, Albedo, Metallic
    }

    class KeywordType
    {
        public const string kSmoothnessAlbedo = "_SMOOTHNESS_ALBEDO";
        public const string kSmoothnessMetallic = "_SMOOTHNESS_METALLIC";
    }


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //base.OnGUI(materialEditor, properties);
        _editor = materialEditor;
        _properties = properties;

        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        DisplayAlbedo();
        DisplayMetallic();
        DisplaySmoothness();
        DisplaySecondaryMaps();
    }

    private void DisplayAlbedo()
    {
        var albedoProperty = FindProperty("_MainTex", _properties);
        var tintProperty = FindProperty("_Tint", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(albedoProperty, "Albedo (RGB) and Transparency (A)"), albedoProperty, tintProperty);
        _editor.TextureScaleOffsetProperty(albedoProperty);
    }

    private void DisplaySecondaryMaps()
    {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        var detailMapProperty = FindProperty("_DetailMap", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(detailMapProperty, "Albedo (RGB) multiplied by 2"), detailMapProperty);


        var normalMapProperty = FindProperty("_NormalMap", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(normalMapProperty, "Normal Map")
            , normalMapProperty
            , normalMapProperty.textureValue == null ? null : FindProperty("_BumpScale", _properties));
        _editor.TextureScaleOffsetProperty(normalMapProperty);
    }

    private void DisplayMetallic()
    {
        var metallicMap = FindProperty("_MetallicMap", _properties);
        var slider = FindProperty("_Metallic", _properties);

        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(
            MakeLabel(metallicMap, "Metallic (R)"),
            metallicMap,
            slider);

        if(EditorGUI.EndChangeCheck())
        {
            SetKeyword("_METALLIC_MAP", metallicMap.textureValue);
        }
    }

    private void DisplaySmoothness()
    {
        SmoothnessSource source = SmoothnessSource.Uniform;
        if(IsKeywordEnable(KeywordType.kSmoothnessAlbedo))
        {
            source = SmoothnessSource.Albedo;
        }
        else if(IsKeywordEnable(KeywordType.kSmoothnessMetallic))
        {
            source = SmoothnessSource.Metallic;
        }

        EditorGUI.BeginChangeCheck();
        
        var slider = FindProperty("_Smoothness", _properties);
        EditorGUI.indentLevel += 2;
        _editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel += 1;
        EditorGUILayout.EnumPopup(MakeLabel("Source"), source);
        EditorGUI.indentLevel -= 3;

        if(EditorGUI.EndChangeCheck())
        {
            SetKeyword(KeywordType.kSmoothnessAlbedo, source == SmoothnessSource.Albedo);
            SetKeyword(KeywordType.kSmoothnessMetallic, source == SmoothnessSource.Metallic);
        }
    }
}
