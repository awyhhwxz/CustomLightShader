#ifndef SHADOW_INNER
#define SHADOW_INNER

#include "UnityCG.cginc"

struct shadow_appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};
#if defined(SHADOWS_CUBE)

struct shadow_v2f
{
	float4 position : SV_POSITION;
	float3 lightVec : TEXTOOR0;
};

shadow_v2f ShadowVertShader(shadow_appdata i)
{
	shadow_v2f o;
	o.position = UnityObjectToClipPos(i.vertex);
	o.lightVec = mul(unity_ObjectToWorld, i.vertex).xyz - _LightPositionRange.xyz;
	return o;
}

fixed4 ShadowFragShader(shadow_v2f i) : SV_TARGET
{
	float depth = length(i.lightVec) + unity_LightShadowBias.x;
	depth *= _LightPositionRange.w;
	return UnityEncodeCubeShadowDepth(depth);
}
#else
float4 ShadowVertShader(shadow_appdata i) : SV_POSITION
{
	float4 position = UnityClipSpaceShadowCasterPos(i.vertex, i.normal);
	return UnityApplyLinearShadowBias(position);
}

fixed4 ShadowFragShader() : SV_TARGET
{
	return 0;
}
#endif

#endif