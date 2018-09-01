Shader "Custom Shader/LightShader"
{
	Properties
	{
		_MainTex ("Albedo", 2D) = "white" {}
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_Smoothness("Smoothness", Range(0,1)) = 1.0
		[Gamma]_Metallic("Metallic", Range(0,1)) = 1.0
		[NoScaleOffset]_MetallicMap("Metallic", 2D) = "black" {}

		[NoScaleOffset]_NormalMap("Normal Normals", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		[NoScaleOffset]_DetailMap("Detail Normals", 2D) = "bump" {}
	}
	SubShader
	{
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma target 3.0	
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ _METALLIC_MAP
			#pragma multi_compile _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			
			//#define BINORMAL_PER_FRAGMENT
			#include "LightVertFrag.cginc"

			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite false

			CGPROGRAM
			#pragma target 3.0	
			#pragma vertex vert
			#pragma fragment frag
							
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows
			
			//#define BINORMAL_PER_FRAGMENT			
			#include "LightVertFrag.cginc"

			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_shadowcaster

			#pragma vertex ShadowVertShader
			#pragma fragment ShadowFragShader

			#include "ShadowInner.cginc"
			ENDCG
		}
	}

	CustomEditor "LightShaderGUI"
}
