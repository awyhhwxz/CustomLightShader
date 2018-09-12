using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class LightShaderGUI : ShaderGUIBase
{
    class RenderingSettings
    {
        public RenderQueue Queue;
        public string RenderType;
        public BlendMode SrcBlend;
        public BlendMode DestBlend;
        public bool ZWrite;
    }

    enum SmoothnessSource
    {
        Uniform, Albedo, Metallic
    }

    enum RenderingMode
    {
        Opaque = 0,
        Cutout,
        Fade,
        Transparent
    }

    private static RenderingSettings[] _modes =
    {
        new RenderingSettings() { Queue = RenderQueue.Geometry, RenderType = "", SrcBlend = BlendMode.One, DestBlend = BlendMode.Zero, ZWrite = true },
        new RenderingSettings() { Queue = RenderQueue.AlphaTest, RenderType = "TransparentCutout", SrcBlend = BlendMode.One, DestBlend = BlendMode.Zero, ZWrite = true },
        new RenderingSettings() { Queue = RenderQueue.Transparent, RenderType = "Transparent", SrcBlend = BlendMode.SrcAlpha, DestBlend = BlendMode.OneMinusSrcAlpha, ZWrite = false },
        new RenderingSettings() { Queue = RenderQueue.Transparent, RenderType = "Transparent", SrcBlend = BlendMode.One, DestBlend = BlendMode.OneMinusSrcAlpha, ZWrite = false },
    };

    class KeywordType
    {
        public const string kSmoothnessAlbedo = "_SMOOTHNESS_ALBEDO";
        public const string kSmoothnessMetallic = "_SMOOTHNESS_METALLIC";

        public const string kRenderingCutout = "_RENDERING_CUTOUT";
        public const string kRenderingFade = "_RENDERING_FADE";
        public const string kRenderingTransparent = "_RENDERING_TRANSPARENT";

        public const string kSemitransparentShadows = "_SEMITRANSPARENT_SHADOWS";
    }

    private bool _shouldShowAlphaCutoff = false;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //base.OnGUI(materialEditor, properties);
        _editor = materialEditor;
        _properties = properties;

        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        _shouldShowAlphaCutoff = false;
        DisplayRenderingMode();
        DisplayMainMaps();
        DisplaySecondaryMaps();
    }

    private void DisplayRenderingMode()
    {
        RenderingMode mode = RenderingMode.Opaque;
        if(IsKeywordEnable(KeywordType.kRenderingCutout))
        {
            mode = RenderingMode.Cutout;
            _shouldShowAlphaCutoff = true;
        }
        else if(IsKeywordEnable(KeywordType.kRenderingFade))
        {
            mode = RenderingMode.Fade;
        }
        else if (IsKeywordEnable(KeywordType.kRenderingTransparent))
        {
            mode = RenderingMode.Transparent;
        }

        EditorGUI.BeginChangeCheck();

        mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);
        if(EditorGUI.EndChangeCheck())
        {
            RecordAction("Rendering Mode");
            SetKeyword(KeywordType.kRenderingCutout, mode == RenderingMode.Cutout);
            SetKeyword(KeywordType.kRenderingFade, mode == RenderingMode.Fade);
            SetKeyword(KeywordType.kRenderingTransparent, mode == RenderingMode.Transparent);

            var renderingSetting = _modes[(int)mode];
            foreach(Material target in _editor.targets)
            {
                target.renderQueue = (int)renderingSetting.Queue;
                target.SetOverrideTag("RenderType", renderingSetting.RenderType);
                target.SetFloat("_SrcBlend", (int)renderingSetting.SrcBlend);
                target.SetFloat("_DestBlend", (int)renderingSetting.DestBlend);
                target.SetFloat("_ZWrite", renderingSetting.ZWrite ? 1 : 0);
            }
        }

        if(mode == RenderingMode.Fade || mode == RenderingMode.Transparent)
        {
            DisplaySemitransparentShadows();
        }
    }

    private void DisplaySemitransparentShadows()
    {
        EditorGUI.BeginChangeCheck();

        bool isSemiparentShadows = EditorGUILayout.Toggle(
                MakeLabel("Semitransp. Shadows", "Semitransparent Shadows"),
                IsKeywordEnable(KeywordType.kSemitransparentShadows)
            );

        if(EditorGUI.EndChangeCheck())
        {
            SetKeyword(KeywordType.kSemitransparentShadows, isSemiparentShadows);

        }

        if (!isSemiparentShadows)
        {
            _shouldShowAlphaCutoff = true;
        }
    }

    private void DisplayMainMaps()
    {
        DisplayAlbedo();
        DisplayMetallic();
        DisplaySmoothness();
        DisplayNormalMap();
        DisplayEmission();
    }

    private void DisplayAlbedo()
    {
        var albedoProperty = FindProperty("_MainTex", _properties);
        var tintProperty = FindProperty("_Color", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(albedoProperty, "Albedo (RGB) and Transparency (A)"), albedoProperty, tintProperty);
        
        if(_shouldShowAlphaCutoff)
        {
            EditorGUI.indentLevel += 2;
            var cutoffProperty = FindProperty("_Cutoff", _properties);
            _editor.ShaderProperty(cutoffProperty, MakeLabel(cutoffProperty));
            EditorGUI.indentLevel -= 2;
        }

        _editor.TextureScaleOffsetProperty(albedoProperty);
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
        source = (SmoothnessSource)EditorGUILayout.EnumPopup(MakeLabel("Source"), source);
        EditorGUI.indentLevel -= 3;

        if(EditorGUI.EndChangeCheck())
        {
            RecordAction("Smoothness source");
            SetKeyword(KeywordType.kSmoothnessAlbedo, source == SmoothnessSource.Albedo);
            SetKeyword(KeywordType.kSmoothnessMetallic, source == SmoothnessSource.Metallic);
        }
    }

    private void DisplayNormalMap()
    {
        var normalMapProperty = FindProperty("_NormalMap", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(normalMapProperty, "Normal Map")
            , normalMapProperty
            , normalMapProperty.textureValue == null ? null : FindProperty("_BumpScale", _properties));
    }

    private void DisplayEmission()
    {
        var emissionMapProperty = FindProperty("_EmissionMap", _properties);
        var emissionProperty = FindProperty("_Emission", _properties);
        EditorGUI.BeginChangeCheck();
        
        _editor.TexturePropertyWithHDRColor(
            MakeLabel(emissionMapProperty, "Emission (RGB)")
            , emissionMapProperty
            , emissionProperty
            , false);

        _editor.LightmapEmissionProperty(2);
        if(EditorGUI.EndChangeCheck())
        {
            SetKeyword("_EMISSION_MAP", emissionMapProperty.textureValue);

            foreach (Material m in _editor.targets)
            {
                m.globalIlluminationFlags &=
                    ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }
    }

    private void DisplaySecondaryMaps()
    {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        var detailMapProperty = FindProperty("_DetailTex", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(detailMapProperty, "Albedo (RGB) multiplied by 2"), detailMapProperty);

        var normalMapProperty = FindProperty("_DetailNormalMap", _properties);
        _editor.TexturePropertySingleLine(MakeLabel(normalMapProperty, "Normal Map")
            , normalMapProperty
            , normalMapProperty.textureValue == null ? null : FindProperty("_DetailBumpScale", _properties));

        _editor.TextureScaleOffsetProperty(detailMapProperty);
    }
}
