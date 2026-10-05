Shader "GhostRally/WorldAtlas" {
 Properties {_BaseMap("Photo material atlas",2D)="white"{} _BaseColor("Tint",Color)=(1,1,1,1) _Kind("Atlas tile",Float)=0 _Cull("Cull",Float)=0 _BrickMap("Brick albedo",2D)="white"{} _PlasterMap("Plaster albedo",2D)="white"{} _BrickNormal("Brick normal",2D)="bump"{} _PlasterNormal("Plaster normal",2D)="bump"{} _BrickRough("Brick roughness",2D)="white"{} _PlasterRough("Plaster roughness",2D)="white"{} _Cutoff("Cutoff",Float)=0.5}
 SubShader {
 Tags {"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
 Pass {
 Tags {"LightMode"="UniversalForward"} Cull [_Cull]
 HLSLPROGRAM
 #pragma vertex Vert
 #pragma fragment Frag
 #pragma multi_compile_instancing
 #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
 #pragma multi_compile_fragment _ _SHADOWS_SOFT
 #pragma multi_compile_fog
 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);TEXTURE2D(_BrickMap);SAMPLER(sampler_BrickMap);TEXTURE2D(_PlasterMap);SAMPLER(sampler_PlasterMap);TEXTURE2D(_BrickNormal);TEXTURE2D(_PlasterNormal);
 CBUFFER_START(UnityPerMaterial)
 float4 _BaseColor;float _Kind;
 CBUFFER_END
 struct Attributes{float4 positionOS:POSITION;float3 normalOS:NORMAL;float4 color:COLOR;UNITY_VERTEX_INPUT_INSTANCE_ID};
 struct Varyings{float4 positionCS:SV_POSITION;float3 world:TEXCOORD0;float3 normal:TEXCOORD1;float4 color:TEXCOORD2;float fog:TEXCOORD3;UNITY_VERTEX_INPUT_INSTANCE_ID};
 Varyings Vert(Attributes a){Varyings o;UNITY_SETUP_INSTANCE_ID(a);UNITY_TRANSFER_INSTANCE_ID(a,o);o.positionCS=TransformObjectToHClip(a.positionOS.xyz);o.world=TransformObjectToWorld(a.positionOS.xyz);o.normal=TransformObjectToWorldNormal(a.normalOS);o.color=a.color*_BaseColor;o.fog=ComputeFogFactor(o.positionCS.z);return o;}
 half4 Frag(Varyings i):SV_Target{UNITY_SETUP_INSTANCE_ID(i);float tile=_Kind;if(tile>5.5)tile=i.color.r>i.color.g*1.22&&i.color.r>i.color.b*1.25?1:2;float2 uv=i.world.xz/(tile<.5?.65:tile>3.5&&tile<4.5?1:3);if(tile>.5&&tile<2.5)uv=float2(abs(i.normal.x)>abs(i.normal.z)?i.world.z:i.world.x,i.world.y)/(tile<1.5?1.7:.75);float2 cell=float2(fmod(tile,3),floor(tile/3));float2 atlas=(cell+lerp(.012,.988,frac(uv)))/float2(3,2);float3 base=SAMPLE_TEXTURE2D_GRAD(_BaseMap,sampler_BaseMap,atlas,ddx(uv)/float2(3,2),ddy(uv)/float2(3,2)).rgb*i.color.rgb;float3 n=normalize(i.normal);if(tile>.5&&tile<2.5){bool brick=tile<1.5;float2 facadeUv=float2(abs(n.x)>abs(n.z)?i.world.z:i.world.x,i.world.y)/(brick?2:1);base=(brick?SAMPLE_TEXTURE2D(_BrickMap,sampler_BrickMap,facadeUv).rgb:SAMPLE_TEXTURE2D(_PlasterMap,sampler_PlasterMap,facadeUv).rgb)*i.color.rgb/(brick?float3(.36,.16,.09):float3(.82,.82,.82));float3 bump=brick?UnpackNormal(SAMPLE_TEXTURE2D(_BrickNormal,sampler_BrickMap,facadeUv)):UnpackNormal(SAMPLE_TEXTURE2D(_PlasterNormal,sampler_PlasterMap,facadeUv));float3 u=abs(n.x)>abs(n.z)?float3(0,0,1):float3(1,0,0);n=normalize(n*bump.z+u*bump.x*.38+float3(0,1,0)*bump.y*.38);}Light light=GetMainLight(TransformWorldToShadowCoord(i.world));float3 lit=base*(SampleSH(n)+light.color*max(.05,dot(n,light.direction))*light.shadowAttenuation);return half4(MixFog(lit,i.fog),1);}
 ENDHLSL
 }
 UsePass "Universal Render Pipeline/Lit/ShadowCaster"
 UsePass "Universal Render Pipeline/Lit/DepthOnly"
 }
}
