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

float FadeShadow(v2f i, float attenuation)
{
#if defined(HANDLE_SHADOWS_BLENDING_IN_GI) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
	#if ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
		attenuation = SHADOW_ATTENUATION(i);
	#endif
	float viewZ = dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
	float shadowFadeDistance = UnityComputeShadowFadeDistance(i.worldPos, viewZ);
	float shadowFade = UnityComputeShadowFade(shadowFadeDistance);

	float bakedAttenuation = UnitySampleBakedOcclusion(i.lightmapUV, i.worldPos);
	attenuation = UnityMixRealtimeAndBakedShadows(attenuation, bakedAttenuation, shadowFade);
#endif
	return attenuation;
}

UnityLight CreateLight(v2f i)
{
	UnityLight light;
#if defined(DEFERRED_PASS) || SUBTRACTIVE_LIGHTING
	light.dir = float3(0, 1, 0);
	light.color = 0;
#else
	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif

	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
	attenuation = FadeShadow(i, attenuation);
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

void ApplySubtractiveLighting(v2f i, inout UnityIndirect indirectlight)
{
#if SUBTRACTIVE_LIGHTING
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	attenuation = FadeShadows(i, attenuation);
	float ndotl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));
	float3 shadowedLightEstimate =
		ndotl * (1 - attenuation) * _LightColor0.rgb;
	float3 subtractedLight = indirectLight.diffuse - shadowedLightEstimate;
	subtractedLight = max(subtractedLight, unity_ShadowColor.rgb);
	subtractedLight =
		lerp(subtractedLight, indirectLight.diffuse, _LightShadowData.x);
	indirectLight.diffuse = min(subtractedLight, indirectLight.diffuse);
#endif
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

		#if defined(DIRLIGHTMAP_COMBINED)
			float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(
				unity_LightmapInd, unity_Lightmap, i.lightmapUV
			);
			indirectLight.diffuse = DecodeDirectionalLightmap(
				indirectLight.diffuse, lightmapDirection, i.normal
			);
		#endif

		ApplySubtractiveLighting(i, indirectLight);
	#endif

	#if defined(DYNAMICLIGHTMAP_ON)
		float3 dynamicLightDiffuse = DecodeRealtimeLightmap(
			UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, i.dynamicLightmapUV)
		);

		#if defined(DIRLIGHTMAP_COMBINED)
			float4 dynamicLightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(
				unity_DynamicDirectionality, unity_DynamicLightmap,
				i.dynamicLightmapUV
			);
            indirectLight.diffuse += DecodeDirectionalLightmap(
            	dynamicLightDiffuse, dynamicLightmapDirection, i.normal
            );
		#else
			indirectLight.diffuse += dynamicLightDiffuse;
		#endif
	#endif

	#if !defined(LIGHTMAP_ON) && !defined(DYNAMICLIGHTMAP_ON)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
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