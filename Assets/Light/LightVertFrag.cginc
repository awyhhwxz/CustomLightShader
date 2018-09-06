#ifndef LIGHT_VERT_FRAG
#define LIGHT_VERT_FRAG

#include "UnityCG.cginc"
#include "Struct.cginc"
#include "LightInner.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;

float4 _Tint;

sampler2D _NormalMap;
float _BumpScale;
sampler2D _MetallicMap;
sampler2D _DetailTex;
float4 _DetailTex_ST;
sampler2D _DetailNormalMap;
float _DetailBumpScale;

sampler2D _EmissionMap;
float3 _Emission;

float _Smoothness;
float _Metallic;

float _AlphaCutoff;

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

float GetMetallic(v2f i)
{
#if defined(_METALLIC_MAP)
	return tex2D(_MetallicMap, i.uv).r * _Metallic;
#else
	return _Metallic;
#endif
}

float GetSmoothness(v2f i)
{
	float smoothness = 1;
#if defined(_SMOOTHNESS_ALBEDO)
	smoothness = tex2D(_MainTex, i.uv).r;
#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
	smoothness = tex2D(_MetallicMap, i.uv).r;
#endif
	return smoothness * _Smoothness;
}

float3 GetEmission(v2f i)
{
#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
#if defined(_EMISSION_MAP)
	return tex2D(_EmissionMap, i.uv).rgb * _Emission;
#else
	return _Emission;
#endif
#else
	return 0;
#endif
}

float GetAlpha(v2f i)
{
	float alpha = _Tint.a;
#if !defined(_SMOOTHNESS_ALBEDO)
	alpha *= tex2D(_MainTex, i.uv.xy).a;
#endif
	return alpha;
}

v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	o.normal = UnityObjectToWorldNormal(v.normal);
#if defined(BINORMAL_PER_FRAGMENT)
	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
#else
	o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
	o.binormal = CreateBinormal(v.normal, v.tangent, v.tangent.w);
#endif
	UNITY_TRANSFER_FOG(o,o.pos);
#if defined(VERTEXLIGHT_ON)
	ComputeVertexLightColor(o.vertexLightColor, o.worldPos, o.normal);
#endif
	TRANSFER_SHADOW(o);
	return o;
}

void InitializeFragmentNormal(inout v2f i)
{	
	float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv), _BumpScale);
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv), _DetailBumpScale);
	float3 normal = BlendNormals(mainNormal, detailNormal);
#if defined(BINORMAL_PER_FRAGMENT)
	float3 binormal = CreateBinormal(i.normal, i.tangent, i.tangent.w);
#else
	float3 binormal = i.binormal;
#endif
	i.normal = normalize(normal.x * i.tangent
		+ normal.y * binormal
		+ normal.z * i.normal);
}

fragment_output frag(v2f i) : SV_Target
{
	float alpha = GetAlpha(i);
#if defined(_RENDERING_CUTOUT)
	clip(alpha - _AlphaCutoff);
#endif

	InitializeFragmentNormal(i);

	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

	fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb *_Tint;
	albedo *= tex2D(_DetailTex, i.uv.zw).rgb * unity_ColorSpaceDouble;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(albedo, GetMetallic(i), specularTint, oneMinusReflectivity);
#if defined(_RENDERING_TRANSPARENT)
	albedo *= alpha;
	alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
#endif

	float smoothness = GetSmoothness(i);
	fixed3 col = UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, smoothness,
		i.normal, viewDir, CreateLight(i), CreateIndirectLight(i, viewDir, 1 - smoothness));
	
	col += GetEmission(i);

#if !defined(_RENDERING_FADE) && !defined(_RENDERING_TRANSPARENT)
	alpha = 1;
#endif
	fixed4 finalCol = fixed4(col, alpha);

	fragment_output o;
#if defined(DEFERRED_PASS)
	//o.color = float4(0, 0, 0, 1);
	o.gBuffer0.rgb = albedo;
	o.gBuffer0.a = 1;
	o.gBuffer1.rgb = specularTint;
	o.gBuffer1.a = smoothness;
	o.gBuffer2 = float4(i.normal * 0.5 + 0.5, 1);

#if !defined(UNITY_HDR_ON)
	finalCol.rgb = exp2(-finalCol.rgb);
#endif

	o.gBuffer3 = finalCol;
#else
	// apply fog
	UNITY_APPLY_FOG(i.fogCoord, finalCol);
	o.color = finalCol;
#endif

	return o;
}

#endif