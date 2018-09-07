Shader "Custom Shader/LightShader"
{
	Properties
	{
		_MainTex ("Albedo", 2D) = "white" {}
		_Color ("Tint", Color) = (1, 1, 1, 1)
		_Smoothness("Smoothness", Range(0,1)) = 1.0
		[Gamma]_Metallic("Metallic", Range(0,1)) = 1.0
		[NoScaleOffset]_MetallicMap("Metallic", 2D) = "black" {}
		[NoScaleOffset]_NormalMap("Normal Normals", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0

		_DetailTex("Detail Albedo", 2D) = "gray" {}
		[NoScaleOffset]_DetailNormalMap("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale("Detail Bump Scale", Float) = 1.0

		[NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}
		_Emission("Emission", Color) = (0, 0, 0)

		_Cutoff("Alpha cutoff", Range(0, 1)) = 0.5

		[HideInInspector]_SrcBlend("Src Blend", Float) = 1
		[HideInInspector]_DestBlend("Dest Blend", Float) = 0
		[HideInInspector]_ZWrite("ZWrite", Float) = 1
	}
	SubShader
	{
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			Blend [_SrcBlend] [_DestBlend]
			ZWrite [_ZWrite]

			CGPROGRAM
			#pragma target 3.0	
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma shader_feature _ _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			
			#define FORWARD_BASE_PASS
			//#define BINORMAL_PER_FRAGMENT
			#include "LightVertFrag.cginc"

			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ForwardAdd" }
			Blend[_SrcBlend] One
			ZWrite false

			CGPROGRAM
			#pragma target 3.0	
			#pragma vertex vert
			#pragma fragment frag
							
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows

			#pragma shader_feature _ LIGHTMAP_ON VERTEXLIGHT_ON
			#pragma shader_feature _ _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT

			//#define BINORMAL_PER_FRAGMENT			
			#include "LightVertFrag.cginc"

			ENDCG
		}

		Pass 
		{
			Tags { "LightMode" = "Deferred" }

			CGPROGRAM
			#pragma target 3.0	
			#pragma exclude_renderers nomrt
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma shader_feature _ _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _ _RENDERING_CUTOUT
			#pragma shader_feature _ UNITY_HDR_ON
			#pragma shader_feature _ LIGHTMAP_ON
			
			#define DEFERRED_PASS
			#include "LightVertFrag.cginc"

			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_shadowcaster

			#pragma shader_feature _ _SMOOTHNESS_ALBEDO
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS

			#pragma vertex ShadowVertShader
			#pragma fragment ShadowFragShader

			#include "ShadowInner.cginc"
			ENDCG
		}
	}

	CustomEditor "LightShaderGUI"
}
