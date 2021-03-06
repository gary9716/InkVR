﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


Shader "Hidden/FogVolume"
{
    CGINCLUDE  
    #include "UnityCG.cginc" 
    sampler2D _CameraDepthTexture;
	sampler2D _Gradient;
  
   	#if defined(_FOG_VOLUME_NOISE)
	sampler3D _NoiseVolume;
    #endif
	
	#define PI 3.1416
	//tweak quality here
	#define STEP_COUNT  50

    float4 _Color, _InscatteringColor, _BoxMin, _BoxMax, Speed=1, Stretch, _LightColor, _ShadowColor, VolumeSize;
    float3 L = float3(0, 0, 1);
    float _InscatteringIntensity=1, InscatteringShape, _Visibility, InscatteringStartDistance = 100, IntersectionThreshold, 
	InscatteringTransitionWideness = 500, _3DNoiseScale, _RayStep, gain=1, threshold=0,
	Shade, _SceneIntersectionThreshold, ShadowBrightness, SlyCollision, Exposure, FadeDistance;
    //http://www.cs.cornell.edu/courses/CS4620/2013fa/lectures/03raytracing1.pdf
	//http://www.clockworkcoders.com/oglsl/rt/gpurt1.htm
    //http://webcache.googleusercontent.com/search?q=cache:9r5sCd1f2hsJ:www.clockworkcoders.com/oglsl/rt/gpurt1.htm+&cd=1&hl=es&ct=clnk&gl=es
 //float hitbox(Ray r, float3 m1, float3 m2, out float tmin, out float tmax) 
 float hitbox (float3 startpoint, float3 direction, float3 m1, float3 m2, inout float tmin, inout float tmax)
 {
        float tymin, tymax, tzmin, tzmax;
        float flag = 1.0;
        if (direction.x > 0) 
    {
            tmin = (m1.x - startpoint.x) / direction.x;
            tmax = (m2.x - startpoint.x) / direction.x;
        }



    else 
    {
            tmin = (m2.x - startpoint.x) / direction.x;
            tmax = (m1.x - startpoint.x) / direction.x;
        }



    if (direction.y > 0) 
    {
            tymin = (m1.y - startpoint.y) / direction.y;
            tymax = (m2.y - startpoint.y) / direction.y;
        }



    else 
    {
            tymin = (m2.y - startpoint.y) / direction.y;
            tymax = (m1.y - startpoint.y) / direction.y;
        }



     
    if ((tmin > tymax) || (tymin > tmax)) flag = -1.0;
        if (tymin > tmin) tmin = tymin;
        if (tymax < tmax) tmax = tymax;
        if (direction.z > 0) 
    {
            tzmin = (m1.z - startpoint.z) / direction.z;
            tzmax = (m2.z - startpoint.z) / direction.z;
        }



    else 
    {
            tzmin = (m2.z - startpoint.z) / direction.z;
            tzmax = (m1.z - startpoint.z) / direction.z;
        }



    if ((tmin > tzmax) || (tzmin > tmax)) flag = -1.0;
        if (tzmin > tmin) tmin = tzmin;
        if (tzmax < tmax) tmax = tzmax;
        return (flag > 0.0);
    }


	//http://zurich.disneyresearch.com/~wjarosz/publications/dissertation/chapter4.pdf
	float Henyey(float3 E, float3 L, float mieDirectionalG)
	{
        float theta=saturate(dot(E, L));
        return (1.0 / (4.0 * PI)) * ((1.0 - mieDirectionalG * mieDirectionalG) / pow(1.0 - 2.0 * mieDirectionalG * theta + mieDirectionalG * mieDirectionalG, 1.5)) ;
    }


    struct v2f
    {
        float4 SampleCoordinates         : SV_POSITION;
        float3 Wpos        : TEXCOORD0;
        float4 ScreenUVs   : TEXCOORD1;
        float3 LocalPos    : TEXCOORD2;
        float3 ViewPos     : TEXCOORD3;
        float3 LocalEyePos : TEXCOORD4;
        float3 LightLocalDir : TEXCOORD5;
    };

    half Threshold(float a, float Gain, float Contrast)
	{
        float Guy = a * Gain;
        float thresh =  Guy - Contrast;
        return saturate(lerp(0.0f ,Guy , thresh ));
    }


    v2f vert (appdata_full i)
    {
        v2f o;
        o.SampleCoordinates = mul(UNITY_MATRIX_MVP, i.vertex);
        o.Wpos = mul((float4x4)unity_ObjectToWorld, float4(i.vertex.xyz, 1)).xyz;
        o.ScreenUVs = ComputeScreenPos(o.SampleCoordinates);
        o.ViewPos = mul((float4x4)UNITY_MATRIX_MV, float4(i.vertex.xyz, 1)).xyz;
        o.LocalPos = i.vertex.xyz;
        o.LocalEyePos = mul((float4x4)unity_WorldToObject, (float4(_WorldSpaceCameraPos, 1))).xyz;
        o.LightLocalDir =  mul((float4x4)unity_WorldToObject, (float4(L.xyz, 1))).xyz;
        return o;
    }

	#if _FOG_VOLUME_NOISE && _SHADE
	
	#define ShadowSamples 3
	half ShadowShift = .05;

	float Shadow( float3 ShadowCoords, v2f i )
	{
        float VolumeShadow = 1.0;
        float s = 0.0;
        for ( int j=0; j < ShadowSamples; j++ )
		{       
            ShadowCoords.xz += s * i.LightLocalDir.xz;
            ShadowCoords.y += s * i.LightLocalDir.y * .001;
            VolumeShadow = VolumeShadow - tex3Dlod(_NoiseVolume, float4(ShadowCoords, 0)).r * VolumeShadow;
            s += ShadowShift * (1.0/ShadowSamples);
        }
	

		return pow(VolumeShadow * ShadowBrightness, 3);
    }
	#endif
	
    float4 frag (v2f i) : COLOR
      {
        float3 direction = normalize(i.LocalPos - i.LocalEyePos);
        float tmin = 0.0, tmax = 0.0;
        float Volume = hitbox(i.LocalEyePos, direction, _BoxMin.xyz, _BoxMax.xyz, tmin, tmax);       
        
        int bOutside  = min(1,(float)(step(0.0, abs(i.LocalEyePos.x) - _BoxMax.x) + step(0.0, abs(i.LocalEyePos.y) - _BoxMax.y) + step(0.0, abs(i.LocalEyePos.z) - _BoxMax.z)));
        tmin *= bOutside;
        float2 ScreenUVs = i.ScreenUVs.xy/i.ScreenUVs.w;
        float Depth =  length(DECODE_EYEDEPTH(tex2D(_CameraDepthTexture, ScreenUVs).r )/normalize(i.ViewPos).z);
        float lDepth = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D (_CameraDepthTexture, ScreenUVs)));        
        float thickness = min(max(tmin, tmax), Depth) - min(min(tmin, tmax), Depth);
		
        float Fog = thickness / _Visibility;
		
        Fog = 1.0 - exp2( -Fog );
        //Fog *= Volume;
		
        float4 Final=0;
        float3 Normalized_CameraWorldDir = normalize(i.Wpos - _WorldSpaceCameraPos);
        float3 Normalized_CameraLocalDir = normalize(i.LocalPos - i.LocalEyePos);
        float3 CameraLocalDir = (i.LocalPos - i.LocalEyePos);
        half DistanceClamp = saturate( Depth / InscatteringTransitionWideness - InscatteringStartDistance);
        #if _FOG_VOLUME_NOISE || _FOG_GRADIENT	
								
		
					
        float4 Noise = 0, ShadowColor = 0;
        float3 rayStart = i.LocalEyePos + Normalized_CameraLocalDir * tmin;
        float3 rayStop = i.LocalEyePos + Normalized_CameraLocalDir * tmax;
   		
		float3 SampleDirection = rayStop - rayStart;
        float3 step = normalize(SampleDirection) * _RayStep;
        float3 stepLocal = normalize(direction) * _RayStep;
        float Ray = distance(rayStop, rayStart);
        half jitter = 1;

        #if _COLLISION				
			jitter = frac(sin(ScreenUVs.x * 12.9898 + ScreenUVs.y * 78.233) * 43758.5453);
			jitter = lerp(1, -jitter , SlyCollision);
		
			Ray = min(Ray, Ray * jitter);
			float distance2Exterior = 1.0;
			float Intersection = 1.0;
			distance2Exterior = distance(i.LocalEyePos, rayStart);
			Intersection = Depth - distance2Exterior;
			Intersection /= _SceneIntersectionThreshold;
			Ray = min(Ray, Ray * Intersection);    
						
		#endif

		float3 SampleCoordinates = rayStart;
        Speed *=_Time.x;
        float4 FinalNoise = 0;
        float4 Gradient = 1;
		//cloud fade
		float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
		
		//return CloudFade;
        //CloudFade *= Volume;
        
        for(int s = 0; s < STEP_COUNT && Ray > 0.0; s++, SampleCoordinates += step, Ray -= _RayStep)
         {

		 float CloudFade = distance(mul(SampleCoordinates, unity_ObjectToWorld), float3(.0, 0,0)) / FadeDistance;
		
        CloudFade = min(1,  exp( -CloudFade ));
		
            #if defined(_FOG_GRADIENT)
					half2 GradientCoords = 1.0h - SampleCoordinates.xy / (_BoxMin.y - _BoxMax.y) + 0.5;
					half4 Gradient = tex2Dlod(_Gradient, half4(GradientCoords, 0, 0));
						
						#ifndef _FOG_VOLUME_NOISE
							Noise =  Gradient * Fog;
						#endif	
            #endif	
					
					#if defined(_FOG_VOLUME_NOISE)
					half NoiseAtten = gain * Gradient.a * CloudFade;
					float4 Layer1_Coords = float4(SampleCoordinates * (_3DNoiseScale * Stretch.rgb) + Speed.rgb, 0);
						#if _DOUBLE_LAYER
								float4 Layer2_Coords = float4(SampleCoordinates * (_3DNoiseScale * Stretch.rgb * .5) - Speed.rgb * 2, 0);
								Noise = Threshold(lerp(tex3Dlod(_NoiseVolume,  Layer1_Coords).r ,	tex3Dlod(_NoiseVolume,  Layer2_Coords ).r, .5), NoiseAtten, threshold) * float4(Gradient.xyz, 1.0);
						#else
								Noise = Threshold(tex3Dlod(_NoiseVolume,  Layer1_Coords).r, NoiseAtten, threshold) * float4(Gradient.xyz, 1.0);
							
						#endif

					#if _SHADE
						#if _DOUBLE_LAYER
							ShadowColor = lerp(lerp(_ShadowColor, 1.0, Shadow(Layer1_Coords, i)), lerp(_ShadowColor, 1.0, Shadow(Layer2_Coords, i)), .5);
						#else			
							ShadowColor = lerp(_ShadowColor, 1.0, Shadow(Layer1_Coords, i));
						#endif
							Noise.xyz *= lerp(1.0 - Shade, 1, ShadowColor);
					#endif														
			#endif	
										FinalNoise = FinalNoise + Noise * (1.0 - FinalNoise.a);
		
		}
				FinalNoise.rgb *= _Color.rgb;
				_Color = FinalNoise;
				_InscatteringColor *= FinalNoise;
				//#endif				
				
				#endif				
				
				#ifdef _FOG_VOLUME_INSCATTERING		
					
				float Inscattering = Henyey(Normalized_CameraWorldDir, L, InscatteringShape);
				Inscattering *= DistanceClamp * Fog;
				Final = float4( _Color.rgb +  _Color.rgb * _InscatteringColor.rgb * _InscatteringIntensity * Inscattering, _Color.a);

				#else
						Final = _Color;
				#endif																
						Final.rgb *= Exposure;
				#if !_FOG_VOLUME_NOISE && !_FOG_GRADIENT
						Final.a *= (Fog * _Color.a);						
				#endif
	
				return Final;

    }


			            
            ENDCG
            SubShader
			{
        Tags {
            "Queue"="Transparent" 
			"IgnoreProjector"="True" "RenderType"="FogVolume" }

        Blend SrcAlpha OneMinusSrcAlpha   

        Cull Front  
		Lighting Off 
		ZWrite Off  
		ZTest Always

        Pass
        {
            Fog {
                Mode Off }
            CGPROGRAM
            #pragma multi_compile _ _FOG_VOLUME_INSCATTERING  
			#pragma multi_compile _ _FOG_VOLUME_NOISE 
			#pragma multi_compile _ _FOG_GRADIENT     
			#pragma multi_compile _ _COLLISION            
			#pragma multi_compile _ _SHADE
			#pragma multi_compile _ _DOUBLE_LAYER        			
			#pragma glsl
			#pragma vertex vert
            #pragma fragment frag			
            #pragma target 3.0
            ENDCG
        }
      
	} 
}
