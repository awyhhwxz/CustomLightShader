#ifndef DATA_STRUCT
#define DATA_STRUCT

#include "AutoLight.cginc"

#if !defined(LIGHTMAP_ON) && defined(SHADOWS_SCREEN)
	#if defined(SHADOWS_SHADOWMASK) && !defined(UNITY_NO_SCREENSPACE_SHADOWS)
		#define ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS 1
	#endif
#endif

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float2 uv2 : TEXCOORD2;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct v2f
{
	float4 uv : TEXCOORD0;
	UNITY_FOG_COORDS(1)
	float3 normal : TEXCOORD2;
#if defined(BINORMAL_PER_FRAGMENT)
	float4 tangent : TEXCOORD3;
#else
	float3 tangent : TEXCOORD3;
	float3 binormal : TEXCOORD4;
#endif
	float3 worldPos : TEXCOORD5;
#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor : TEXCOORD6;
#endif
#if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
	float2 lightmapUV : TEXCOORD6;
#endif
#if defined(DYNAMICLIGHTMAP_ON)
	float2 dynamicLightmapUV : TEXCOORD7;
#endif
	UNITY_SHADOW_COORDS(8)
	float4 pos : SV_POSITION;
};

struct fragment_output
{
#if defined(DEFERRED_PASS)
	float4 gBuffer0 : SV_Target0;
	float4 gBuffer1 : SV_Target1;
	float4 gBuffer2 : SV_Target2;
	float4 gBuffer3 : SV_Target3;

	#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
		float4 gBuffer4 : SV_Target4;
	#endif
#else
	float4 color : SV_Target;
#endif
};

#endif