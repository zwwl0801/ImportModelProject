
/*
	悟空项目 角色Shader，
	
	Surf - Lambert
		+ Mask MatCap
		+ UVAnim 发光
		+ Rim


*/
Shader "WK/PlayerCharacter1" 
{  
    Properties 
    {  
        _MainTex  ("Diffuse (RGB)", 2D) = "white" {}  
        _Mask	  ("Mask (R-Matcap)", 2D) = "black" {}   // 目前只用了r通道  g / b 通道还可以干点别的
        _MatCap   ("MatCap", 2D) = "white" {}  

		// Illum 是受光照的影响值，1表示使用Lambert光照，0表示全部是Emission自发光
		_Illum ("illumination",Range(0,1)) = 1.0

		_DiffuseMultiply	("Diffuse-Mulitplier",Range(0,3)) = 1.0
		_MaskMultipily		("Mask-Mulitplier",Range(0,3)) = 1.0
		_MatCapMultipily	("MatCap-Mulitplier",Range(0,3)) = 1.0
	
		// 数值越大，越像是乘上去的，数值越小，越像是加上去的
		_MatCapAddFactor	("MatCap-Factor",Range(0,1)) = 0.5
			
		// 边缘光
    	_Rim			("Rim",Range(0,3)) = 0
        _RimGloss		("RimGloss",Range(1,20)) = 6.0
        _RimColor		("RimColor", Color) = (1,1,1,1) 
        
        //
        _Ramp			("Ramp", 2D) = "black" {}  
        _PannerSpeed	("UVSpeed", Range(-20,20)) = 0
        _RampMultipily	("Ramp-Mulitplier",Range(0,3)) = 1.0
    }  

	SubShader 
    {  
        Tags { "RenderType"="Opaque" }  
        LOD 200  
          
        CGPROGRAM  
      	#pragma surface surf Lambert vertex:vert  
        #pragma target 2.0

        sampler2D _MainTex;
        sampler2D _Mask;
        sampler2D _MatCap; 
        
        sampler2D _Ramp;

		
		fixed _Illum;

		fixed _DiffuseMultiply;
		fixed _MaskMultipily;
		fixed _MatCapMultipily;

		fixed _MatCapAddFactor;

        fixed _PannerSpeed;
        fixed _RampMultipily;
        
        fixed	_Rim;
        fixed	_RimGloss;
        fixed4	_RimColor;
        
        
		struct Input 
		{
			fixed2 uv_MainTex : TEXCOORD0;
			fixed2 matcapUV;
            fixed3 viewDir;
            
		};
          
		void vert (inout appdata_full v, out Input o)
		{
            UNITY_INITIALIZE_OUTPUT(Input,o);       
            
            // MatCap UV变换
            fixed3 worldNorm = normalize(_World2Object[0].xyz * v.normal.x + _World2Object[1].xyz * v.normal.y + _World2Object[2].xyz * v.normal.z);
            worldNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
            o.matcapUV = worldNorm.xy * 0.5 + 0.5;
            
            
		}

        void surf (Input IN, inout SurfaceOutput o)   
        {  
        	// diffuse 颜色
        	fixed3 diff  	= tex2D(_MainTex,	IN.uv_MainTex).rgb * _DiffuseMultiply;  
        	
        	// MatCap 颜色
			fixed3 matcap	= tex2D(_MatCap,	IN.matcapUV).rgb * _MatCapMultipily; 
			
			// Mask贴图信息
			fixed3 mask 	= tex2D(_Mask,		IN.uv_MainTex).rgb;
       
    		// 用于MatCap的Mask
    		fixed maskMc	= saturate(mask.r * _MaskMultipily);
       

            // 颜色计算
			fixed3 final = (diff * (1.0 - maskMc * _MatCapAddFactor)) + (maskMc * matcap);
			
			// UV动画的Ramp 作为流光效果
			fixed2 uvAnim;
        	uvAnim.x = IN.uv_MainTex.x;
            uvAnim.y = IN.uv_MainTex.y + (_Time * _PannerSpeed);
            fixed3 ramp = tex2D(_Ramp,	uvAnim).rgb; 
            
            // 边缘光
            if(_Rim > 0.1)
            {
                fixed rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
				final += pow(rim,_RimGloss) * _RimColor * _Rim;
            }
            
			// Illum 是受光照的影响值，1表示使用Lambert光照，0表示全部是Emission自发光
            o.Albedo = final * _Illum; 
            o.Alpha = 1.0;
            o.Emission = final * (1.0 - _Illum) + ramp * _RampMultipily * maskMc;
 

        }  
        ENDCG  
    }   
    




    FallBack "Diffuse"  
}  