#ifndef LIGHT_VERT_FRAG
#define LIGHT_VERT_FRAG

#include "UnityCG.cginc"
#include "Struct.cginc"
#include "LightInner.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;

sampler2D _NormalMap;
float _BumpScale;
sampler2D _DetailMap;
sampler2D _MetallicMap;

float4 _Tint;

float _Smoothness;
float _Metallic;

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

v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.normal = UnityObjectToWorldNormal(v.normal);
#if defined(BINORMAL_PER_FRAGMENT)
	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
#else
	o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
	o.binormal = CreateBinormal(v.normal, v.tangent, v.tangent.w);
#endif
	UNITY_TRANSFER_FOG(o,o.vertex);
#if defined(VERTEXLIGHT_ON)
	ComputeVertexLightColor(o.vertexLightColor, o.worldPos, o.normal);
#endif
	TRANSFER_SHADOW(o);
	return o;
}

void InitializeFragmentNormal(inout v2f i)
{
	float3 mainNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailMap, i.uv), _BumpScale);
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

fixed4 frag(v2f i) : SV_Target
{
	InitializeFragmentNormal(i);

	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

	fixed3 albedo = tex2D(_MainTex, i.uv).rgb *_Tint;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(albedo, GetMetallic(i), specularTint, oneMinusReflectivity);

	float smoothness = GetSmoothness(i);
	fixed3 col = UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, smoothness,
		i.normal, viewDir, CreateLight(i), CreateIndirectLight(i, viewDir, 1 - smoothness));
	// apply fog
	fixed4 finalCol = fixed4(col, 1);
	UNITY_APPLY_FOG(i.fogCoord, finalCol);
	return finalCol;
}

#endif