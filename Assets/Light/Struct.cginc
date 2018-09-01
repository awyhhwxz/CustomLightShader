#ifndef DATA_STRUCT
#define DATA_STRUCT

#include "AutoLight.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct v2f
{
	float2 uv : TEXCOORD0;
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
	SHADOW_COORDS(7)
	float4 pos : SV_POSITION;
};

#endif