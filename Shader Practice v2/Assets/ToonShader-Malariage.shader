Shader "Custom/ToonShader-Malariage"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        _TransparentColor("Transparency Color", Color) = (1,1,1,1)
        _Transparency("Transparency", Range(0,1)) = 0.5

        _ShadowThreshold("Shadow Threshold", Range(0,1)) = 0.5
        _Steps("Toon Steps", Range(1,8)) = 4

        _OutlineWidth("Outline Width", Range(0,0.03)) = 0.005
        _OutlineColor("Outline Color", Color) = (0,0,0,1) // Maybe based on texture and shadow????

    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" 
               "RenderPipeline" = "UniversalPipeline" 
               "Queue" = "Geometry"}

        Pass
        {
            Name "Outline"
            Tags {"LightMode"="SRPDefaultUnlit"}
            cull Front
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _OutlineWidth;
                float4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            
            ENDHLSL
        }

        Pass
        {
            Name "Toonlit"
            Tags {"LightMode"="UniversalForward"}
            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _ShadowThreshold;
                float _Steps;
                float4 _BaseMap_ST;
            CBUFFER_END

            struct Attributes{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings{
                float4 positionHCS: SV_POSITION;
                float3 normalWS: TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            Varyings vert(Attributes IN){
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 n = normalize(IN.normalWS);

                //main light
                Light mainLight = GetMainLight();
                half3 l = normalize(mainLight.direction);

                // N . L in [0..1]
                half ndl = saturate(dot(n, l));

                //Toon Steps
                half steps = max(1.0h, _Steps);
                half toon = floor(ndl * steps) / steps + 0.1;
                
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                half3 lit = albedo.rgb * (toon * mainLight.color);
                return half4(lit, albedo.a);
            }
            
            ENDHLSL
        }

        // Pass
        // {
        //     Name "Transparency"

        //     HLSLPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
            
        //     TEXTURE2D(_BaseMap);
        //     SAMPLER(sampler_BaseMap);

        //     CBUFFER_START(UnityPerMaterial)
        //         float4 _BaseColor;
        //         float4 _TransparentColor;
        //         float _Transparency;
        //         float4 _BaseMap;
        //     CBUFFER_END


        //     ENDHLSL
        // }
    }
}