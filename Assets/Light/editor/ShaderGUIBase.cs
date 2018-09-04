using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ShaderGUIBase : ShaderGUI
{
    protected MaterialEditor _editor;
    protected MaterialProperty[] _properties;

    private static GUIContent _staticLabel = new GUIContent();
    protected GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        return MakeLabel(property.displayName, tooltip);
    }

    protected GUIContent MakeLabel(string text, string tooltip = null)
    {
        _staticLabel.text = text;
        _staticLabel.tooltip = tooltip;
        return _staticLabel;
    }

    protected void SetKeyword(string keyword, bool state)
    {
        foreach (Material target in _editor.targets)
        {
            if (target)
            {
                if (state)
                {
                    target.EnableKeyword(keyword);
                }
                else
                {
                    target.DisableKeyword(keyword);
                }
            }
        }
    }

    protected bool IsKeywordEnable(string keyword)
    {
        var target = _editor.target as Material;
        return target.IsKeywordEnabled(keyword);
    }

    protected void RecordAction(string labal)
    {
        _editor.RegisterPropertyChangeUndo(labal);
    }
}
