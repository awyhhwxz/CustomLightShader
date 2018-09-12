#ifndef LIGHTMAPPING_INNER
#define LIGHTMAPPING_INNER

#include "UnityCG.cginc"
#include "UnityMetaPass.cginc"
#include "UnityPBSLighting.cginc"

struct lightmapping_appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float2 uv2 : TEXCOORD2;
};

struct lightmapping_v2f
{
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _DetailTex;
float4 _DetailTex_ST;

sampler2D _MetallicMap;
float _Metallic;
float _Smoothness;
sampler2D _EmissionMap;
float _Emission;

float4 _Color;

float3 GetAlbedo(lightmapping_v2f i)
{
	float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color;
	albedo *= tex2D(_DetailTex, i.uv.zw).rgb * unity_ColorSpaceDouble;
	return albedo;
}

float GetMetallic(lightmapping_v2f i)
{
#if defined(_METALLIC_MAP)
	return tex2D(_MetallicMap, i.uv).r * _Metallic;
#else
	return _Metallic;
#endif
}

float GetSmoothness(lightmapping_v2f i)
{
	float smoothness = 1;
#if defined(_SMOOTHNESS_ALBEDO)
	smoothness = tex2D(_MainTex, i.uv).r;
#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
	smoothness = tex2D(_MetallicMap, i.uv).r;
#endif
	return smoothness * _Smoothness;
}

float3 GetEmission(lightmapping_v2f i)
{
#if defined(_EMISSION_MAP)
	return tex2D(_EmissionMap, i.uv).rgb * _Emission;
#else
	return _Emission;
#endif
}

lightmapping_v2f LightmappingVert(lightmapping_appdata i)
{
	lightmapping_v2f o;
	o.pos = UnityMetaVertexPosition(
		i.vertex, i.uv1, i.uv2, unity_LightmapST, unity_DynamicLightmapST
	);
	
	o.uv.xy = TRANSFORM_TEX(i.uv, _MainTex);
	o.uv.zw = TRANSFORM_TEX(i.uv, _DetailTex);
	return o;
}

fixed4 LightmappingFrag(lightmapping_v2f i) : SV_TARGET
{ 
	UnityMetaInput surfaceData;
	surfaceData.Emission = GetEmission(i);
	float oneMinusReflectivity;
	surfaceData.Albedo = DiffuseAndSpecularFromMetallic(GetAlbedo(i), GetMetallic(i), surfaceData.SpecularColor, oneMinusReflectivity);
	float roughness = SmoothnessToRoughness(GetSmoothness(i)) * 0.5;
	surfaceData.Albedo += surfaceData.SpecularColor * roughness;
	return UnityMetaFragment(surfaceData);
}

#endif