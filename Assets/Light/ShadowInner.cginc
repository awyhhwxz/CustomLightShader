#ifndef SHADOW_INNER
#define SHADOW_INNER

#include "UnityCG.cginc"

#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
	#if defined(_SEMITRANSPARENT_SHADOWS)
		#define SHADOWS_SEMITRANSPARENT 1
	#else
		#define _RENDERING_CUTOUT
	#endif
#endif

#if defined(SHADOWS_SEMITRANSPARENT) || defined(_RENDERING_CUTOUT)
	#if !defined(_SMOOTHNESS_ALBEDO)
		#define SHADOWS_NEED_UV 1
	#endif
#endif

struct shadow_appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
#if defined(SHADOWS_NEED_UV)
	float2 uv : TEXCOORD0;
#endif
};

struct vertex_shadow_v2f
{
	float4 position : SV_POSITION;
#if defined(SHADOWS_NEED_UV)
	float2 uv : TEXCOORD0;
#endif
#if defined(SHADOWS_CUBE)
	float3 lightVec : TEXTOOR1;
#endif
};

struct shadow_v2f
{
#if defined(SHADOWS_SEMITRANSPARENT)
	UNITY_VPOS_TYPE vpos : VPOS;
#else
	float4 position : SV_POSITION;
#endif

#if defined(SHADOWS_NEED_UV)
	float2 uv : TEXCOORD0;
#endif
#if defined(SHADOWS_CUBE)
	float3 lightVec : TEXTOOR1;
#endif
};

sampler2D _MainTex;
float4 _MainTex_ST;

float4 _Color;
float _Cutoff;

sampler3D _DitherMaskLOD;

float GetAlpha(shadow_v2f i)
{
	float alpha = _Color.a;
#if defined(SHADOWS_NEED_UV)
	alpha *= tex2D(_MainTex, i.uv).a;
#endif
	return alpha;
}

vertex_shadow_v2f ShadowVertShader(shadow_appdata i)
{
#if defined(SHADOWS_CUBE)
	vertex_shadow_v2f o;
	o.position = UnityObjectToClipPos(i.vertex);
	o.lightVec = mul(unity_ObjectToWorld, i.vertex).xyz - _LightPositionRange.xyz;
#else
	vertex_shadow_v2f o;
	float4 position = UnityClipSpaceShadowCasterPos(i.vertex, i.normal);
	o.position = UnityApplyLinearShadowBias(position);
#endif

#if defined(SHADOWS_NEED_UV)
	o.uv = i.uv;
#endif
	return o;
}


fixed4 ShadowFragShader(shadow_v2f i) : SV_TARGET
{
#if defined(_RENDERING_CUTOUT)
	float alpha = GetAlpha(i);
	clip(alpha - _Cutoff);
#endif

#if defined(SHADOWS_SEMITRANSPARENT)
	float alpha = GetAlpha(i);
	float dither = tex3D(_DitherMaskLOD, float3(i.vpos.xy * 0.25, alpha * 0.9375)).a;
	clip(dither - 0.01);
#endif

#if defined(SHADOWS_CUBE)
	float depth = length(i.lightVec) + unity_LightShadowBias.x;
	depth *= _LightPositionRange.w;
	return UnityEncodeCubeShadowDepth(depth);
#else
	return 0;
#endif
}

#endif