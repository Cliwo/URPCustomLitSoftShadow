Shader "Unlit/URP_Unlit_SoftShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque" 
            "Queue"="Geometry+0"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // GPU Instancing
            #pragma multi_compile_instancing
            // make fog work
            #pragma multi_compile_fog

            // Receive Shadow
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float3 normal : NORMAL;
                float4 shadowCoord : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;

            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //VR 설정

                o.vertex = TransformObjectToHClip(v.vertex.xyz); //MVP랑 같음 이름만 달라짐.
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal); // Normal Transform은 따로 행렬이 필요.
                o.fogCoord = ComputeFogFactor(o.vertex.z);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.shadowCoord = GetShadowCoord(vertexInput);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                Light mainLight = GetMainLight(i.shadowCoord);

                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                float NdotL = saturate(dot(_MainLightPosition.xyz, i.normal)); // NdotL로 간단히 라이팅한다.
                half3 ambient = SampleSH(i.normal);

                col.rgb *= NdotL * _MainLightColor.rgb * mainLight.shadowAttenuation * mainLight.distanceAttenuation + ambient;
                col.rgb = MixFog(col.rgb, i.fogCoord);
                
                return col;
            }
            ENDHLSL
        }

    //     Pass
    // {
    //     Name "ShadowCaster"

    //     Tags{"LightMode" = "ShadowCaster"}

    //         Cull Back

    //         HLSLPROGRAM

    //         #pragma prefer_hlslcc gles
    //         #pragma exclude_renderers d3d11_9x
    //         #pragma target 2.0

    //         #pragma vertex ShadowPassVertex
    //         #pragma fragment ShadowPassFragment
            
    //         #pragma shader_feature _ALPHATEST_ON

    //        // GPU Instancing
    //         #pragma multi_compile_instancing
          
    //         #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    //         #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
    //         #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"


    //          CBUFFER_START(UnityPerMaterial)
    //          half4 _TintColor;
    //          sampler2D _MainTex;
    //          float4 _MainTex_ST;
    //          float   _Alpha;
    //          CBUFFER_END

    //         struct VertexInput
    //         {          
    //         float4 vertex : POSITION;
    //         float4 normal : NORMAL;
            
    //         #if _ALPHATEST_ON
    //         float2 uv     : TEXCOORD0;
    //         #endif

    //         UNITY_VERTEX_INPUT_INSTANCE_ID  
    //         };
          
    //         struct VertexOutput
    //         {          
    //         float4 vertex : SV_POSITION;
    //         #if _ALPHATEST_ON
    //         float2 uv     : TEXCOORD0;
    //         #endif
    //         UNITY_VERTEX_INPUT_INSTANCE_ID          
    //         UNITY_VERTEX_OUTPUT_STEREO
  
    //         };

    //         VertexOutput ShadowPassVertex(VertexInput v)
    //         {
    //            VertexOutput o;
    //            UNITY_SETUP_INSTANCE_ID(v);
    //            UNITY_TRANSFER_INSTANCE_ID(v, o);
    //           UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);                             
           
    //           float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
    //           float3 normalWS   = TransformObjectToWorldNormal(v.normal.xyz);
         
    //           float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightPosition.xyz));
              
    //           o.vertex = positionCS;
    //          #if _ALPHATEST_ON
    //           o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw; ;
    //          #endif

    //           return o;
    //         }

    //         half4 ShadowPassFragment(VertexOutput i) : SV_TARGET
    //         {  
    //             UNITY_SETUP_INSTANCE_ID(i);
    //             UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
              
    //             #if _ALPHATEST_ON
    //             float4 col = tex2D(_MainTex, i.uv);
    //             clip(col.a - _Alpha);
    //             #endif

    //             return 0;
    //         }

    //         ENDHLSL
    //     }
    }
}
