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

float sphDensity( vec3  ro, vec3  rd,   // ray origin, ray direction
                  vec3  sc, float sr,   // sphere center, sphere radius
                  float dbuffer )       // depth buffer
{
    // normalize the problem to the canonical sphere
    float ndbuffer = dbuffer / sr;
    vec3  rc = (ro - sc)/sr;

    // find intersection with sphere
    float b = dot(rd,rc);
    float c = dot(rc,rc) - 1.0;
    float h = b*b - c;

    // not intersecting
    if( h<0.0 ) return 0.0;

    h = sqrt( h );

    //float s = 1. /(sr/h);

    //float l = s * (atan( (dbuffer + b) * s) - atan( b*s ));

    //return h*h*h;

    float t1 = -b - h;
    float t2 = -b + h;

    // not visible (behind camera or behind ndbuffer)
    if( t2<0.0 || t1>ndbuffer ) return 0.0;

    // clip integration segment from camera to ndbuffer
    t1 = max( t1, 0.0 );
    t2 = min( t2, ndbuffer );

    // analytical integration of an inverse squared density
    float i1 = -(c*t1 + b*t1*t1 + t1*t1*t1/3.0);
    float i2 = -(c*t2 + b*t2*t2 + t2*t2*t2/3.0);
    return (i2-i1)*(3.0/4.0);
}

float InScatter(vec3 start, vec3 dir, vec3 lightPos, float d)
{
	// calculate quadratic coefficients a,b,c
	vec3 q = start - lightPos;

	float b = dot(dir, q);
	float c = dot(q, q);

	// evaluate integral
	float s = 1. / sqrt(c - b*b);

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
            vec3 wP = vFarRay * depth / vScreenPos.w;
            vec3 worldPos = wP;
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

    vec3 dir = normalize(vFarRay);
    float Z = length(eyeVec);
    float vol;

    #if defined(SPOTLIGHT)
      float aperture = 0.4;
      float height = 30.0;
      float minT = 0.0;
      float maxT = 0.0;

      IntersectCone(cCameraPosPS, dir, cLightMatricesPS[0], aperture, height, minT, maxT);

      // clamp bounds to scene geometry / camera
      maxT = clamp(maxT, 0.0, Z);
      minT = max(0.0, minT);
      float t = max(0.0, maxT - minT);

      vol = min(InScatter(cCameraPosPS + dir*minT, dir, cLightPosPS.xyz, t) * 0.5,16.);
    #else
      vol = min(InScatter(cCameraPosPS, dir, cLightPosPS.xyz, Z) * 0.5,16.);
    #endif

    float dens = min(sphDensity(cCameraPosPS,normalize(vFarRay),cLightPosPS.xyz,1./cLightPosPS.w, Z),1.);
    vol *= dens;

    #ifdef SHADOW
        diff *= GetShadowDeferred(projWorldPos, normal, depth);
    #endif

    #if defined(SPOTLIGHT)
        vec4 spotPos = projWorldPos * cLightMatricesPS[0];
        lightColor =cLightColor.rgb;// spotPos.w > 0.0 ? texture2DProj(sLightSpotMap, spotPos).rgb * cLightColor.rgb : vec3(0.0);
        float spot = spotPos.w > 0.0 ? texture2DProj(sLightSpotMap, spotPos).r: 0.0;
        diff *= spot;
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
