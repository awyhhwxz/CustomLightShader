#ifndef LIGHT_INNER
#define LIGHT_INNER

#include "UnityCG.cginc"
#include "Struct.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

void ComputeVertexLightColor(inout float3 vertexLightColor, float3 worldPos, float3 normal)
{
#if defined(VERTEXLIGHT_ON)
	vertexLightColor = 
		Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, worldPos, normal
	);
#endif
}

UnityLight CreateLight(v2f i)
{
	UnityLight light;
#if defined(DEFERRED_PASS)
	light.dir = float3(0, 1, 0);
	light.color = 0;
#else
	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif

	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
	light.color = _LightColor0.rgb * attenuation;
#endif
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

float3 BoxProjection(
	float3 direction, float3 position,
	float4 cubemapPosition, float3 boxMin, float3 boxMax
) {
	if (cubemapPosition.w > 0) {
		float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
		float scalar = min(min(factors.x, factors.y), factors.z);
		direction = direction * scalar + (position - cubemapPosition);
	}

	return direction;
}

UnityIndirect CreateIndirectLight(v2f i, float3 viewDir, float roughness)
{
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

#ifdef VERTEXLIGHT_ON
	indirectLight.diffuse = i.vertexLightColor;
#endif

#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)

#if defined(LIGHTMAP_ON)
	indirectLight.diffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
#else
	indirectLight.diffuse = max(0, ShadeSH9(float4(i.normal, 1)));
#endif
	float3 reflectViewDir = reflect(-viewDir, i.normal);
	Unity_GlossyEnvironmentData envData;
	envData.roughness = roughness;
	envData.reflUVW = BoxProjection(
		reflectViewDir, i.worldPos,
		unity_SpecCube0_ProbePosition,
		unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
	);
	indirectLight.specular = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0),
		unity_SpecCube0_HDR, envData);

	#if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
		indirectLight.specular = 0;
	#endif

#endif

	return indirectLight;
}

#endif