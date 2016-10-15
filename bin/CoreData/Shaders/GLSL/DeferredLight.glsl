#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "Lighting.glsl"

#ifdef DIRLIGHT
    varying vec2 vScreenPos;
#else
    varying vec4 vScreenPos;
    varying vec4 vScreenLpos;
#endif
varying vec3 vFarRay;
#ifdef ORTHO
    varying vec3 vNearRay;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    #ifdef DIRLIGHT
        vScreenPos = GetScreenPosPreDiv(gl_Position);
        vFarRay = GetFarRay(gl_Position);
        #ifdef ORTHO
            vNearRay = GetNearRay(gl_Position);
        #endif
    #else
        vScreenPos = GetScreenPos(gl_Position);
        //float aspect = cFrustumSize.x/cFrustumSize.y;
        vScreenLpos.xyz = GetFarRay(GetClipPos(cLightPos.xyz));
        vScreenLpos.w = length(cLightPos.xyz - cCameraPos.xyz);
        vScreenLpos.xyz = normalize(vScreenLpos.xyz);
        //vScreenLpos.xz *=aspect;
        vFarRay = GetFarRay(gl_Position) * gl_Position.w;
        #ifdef ORTHO
            vNearRay = GetNearRay(gl_Position) * gl_Position.w;
        #endif
    #endif
}


float InScatter(vec3 start, vec3 dir, vec3 lightPos, float d)
{
	// calculate quadratic coefficients a,b,c
	vec3 q = start - lightPos;

	float b = dot(dir, q);
	float c = dot(q, q);

	// evaluate integral
	float s = 1.0f / sqrt(c - b*b);

	float l = s * (atan( (d + b) * s) - atan( b*s ));

	return l;
}

void SolveQuadratic(float a, float b, float c, out float minT, out float maxT)
{
	float discriminant = b*b - 4.0*a*c;

	if (discriminant < 0.0)
	{
		// no real solutions so return a degenerate result
		maxT = 0.0;
		minT = 0.0;
		return;
	}

	// numerical receipes 5.6 (this method ensures numerical accuracy is preserved)
	float t = -0.5 * (b + sign(b)*sqrt(discriminant));
	float closestT = t / a;
	float furthestT = c / t;

	if (closestT > furthestT)
	{
		minT = furthestT;
		maxT = closestT;
	}
	else
	{
		minT = closestT;
		maxT = furthestT;
	}
}

void IntersectCone(vec3 rayOrigin, vec3 rayDir, mat4 invConeTransform, float aperture, float height, out float minT, out float maxT)
{
	vec4 localOrigin = invConeTransform * vec4(rayOrigin, 1.0);
	vec4 localDir = invConeTransform * vec4(rayDir, 0.0);

	// could perform this on the cpu
	float tanTheta = tan(aperture);
	tanTheta *= tanTheta;

	float a = localDir.x*localDir.x + localDir.z*localDir.z - localDir.y*localDir.y*tanTheta;
	float b = 2.0*(localOrigin.x*localDir.x + localOrigin.z*localDir.z - localOrigin.y*localDir.y*tanTheta);
	float c = localOrigin.x*localOrigin.x + localOrigin.z*localOrigin.z - localOrigin.y*localOrigin.y*tanTheta;

	SolveQuadratic(a, b, c, minT, maxT);

	float y1 = localOrigin.y + localDir.y*minT;
	float y2 = localOrigin.y + localDir.y*maxT;

	// should be possible to simplify these branches if the compiler isn't already doing it

	if (y1 > 0.0 && y2 > 0.0)
	{
		// both intersections are in the reflected cone so return degenerate value
		minT = 0.0;
		maxT = -1.0;
	}
	else if (y1 > 0.0 && y2 < 0.0)
	{
		// closest t on the wrong side, furthest on the right side => ray enters volume but doesn't leave it (so set maxT arbitrarily large)
		minT = maxT;
		maxT = 10000.0;
	}
	else if (y1 < 0.0 && y2 > 0.0)
	{
		// closest t on the right side, largest on the wrong side => ray starts in volume and exits once
		maxT = minT;
		minT = 0.0;
	}
}

void PS()
{
    // If rendering a directional light quad, optimize out the w divide
    #ifdef DIRLIGHT
        #ifdef HWDEPTH
            float depth = ReconstructDepth(texture2D(sDepthBuffer, vScreenPos).r);
        #else
            float depth = DecodeDepth(texture2D(sDepthBuffer, vScreenPos).rgb);
        #endif
        #ifdef ORTHO
            vec3 worldPos = mix(vNearRay, vFarRay, depth);
        #else
            vec3 worldPos = vFarRay * depth;
        #endif
        vec4 albedoInput = texture2D(sAlbedoBuffer, vScreenPos);
        vec4 normalInput = texture2D(sNormalBuffer, vScreenPos);
    #else
        #ifdef HWDEPTH
            float depth = ReconstructDepth(texture2DProj(sDepthBuffer, vScreenPos).r);
        #else
            float depth = DecodeDepth(texture2DProj(sDepthBuffer, vScreenPos).rgb);
        #endif
        #ifdef ORTHO
            vec3 worldPos = mix(vNearRay, vFarRay, depth) / vScreenPos.w;
        #else
            vec3 worldPos = vFarRay * depth / vScreenPos.w;
        #endif
        vec4 albedoInput = texture2DProj(sAlbedoBuffer, vScreenPos);
        vec4 normalInput = texture2DProj(sNormalBuffer, vScreenPos);
    #endif

    // Position acquired via near/far ray is relative to camera. Bring position to world space
    vec3 eyeVec = -worldPos;
    worldPos += cCameraPosPS;

    vec3 normal = normalize(normalInput.rgb * 2.0 - 1.0);
    vec4 projWorldPos = vec4(worldPos, 1.0);
    vec3 lightColor;
    vec3 lightDir;
    float lightDist;
    float diff = GetDiffuse(normal, worldPos, lightDir, normalInput.a, lightDist);
    //float vol = max(1. - length(vScreenLpos.xyz-normalize(vFarRay)) * vScreenLpos.w * cLightPosPS.w,0. );// max(10. - length(vScreenLpos.xy),0. );// max(2. - length(vScreenLpos.ba-vScreenLpos.xy),0. );
    //THIS THING SHOULD BE MOVED TO VS
    //float volzclip = clamp( (length(eyeVec) - vScreenLpos.w)*cLightPosPS.w, 0. , 1.) *  clamp(pow((vScreenLpos.w - 1.1/cLightPosPS.w)*0.003,2.2),0.,1.);
    //vol = volzclip * pow(vol,5.);


    float vol = max(InScatter(cCameraPosPS, normalize(vFarRay), cLightPosPS.xyz, depth * cFarClipPS) * 0.9,0.);

    #ifdef SHADOW
        diff *= GetShadowDeferred(projWorldPos, normal, depth);
    #endif

    #if defined(SPOTLIGHT)
        vec4 spotPos = projWorldPos * cLightMatricesPS[0];
        lightColor = spotPos.w > 0.0 ? texture2DProj(sLightSpotMap, spotPos).rgb * cLightColor.rgb : vec3(0.0);
    #elif defined(CUBEMASK)
        mat3 lightVecRot = mat3(cLightMatricesPS[0][0].xyz, cLightMatricesPS[0][1].xyz, cLightMatricesPS[0][2].xyz);
        lightColor = textureCube(sLightCubeMap, (worldPos - cLightPosPS.xyz) * lightVecRot).rgb * cLightColor.rgb;
    #else
        lightColor = cLightColor.rgb;
    #endif

    #ifdef SPECULAR
        float spec = GetSpecular(normal, eyeVec, lightDir, 0.7 * 255.0);
        gl_FragColor =vec4( vol * lightColor  * 0.1,0.) + diff * vec4(lightColor * (albedoInput.rgb + spec * cLightColor.a * albedoInput.aaa), 0.0);
    #else
        gl_FragColor = diff * vec4(lightColor * albedoInput.rgb, 0.0);
    #endif
}
