#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "Lighting.glsl"
#include "volumetrics.glsl"

#ifdef DIRLIGHT
    varying vec2 vScreenPos;
#else
    varying vec4 vScreenPos;
    varying vec4 vScreenLpos;
#endif
varying mat4 vModel;
varying vec3 vFarRay;
#ifdef ORTHO
    varying vec3 vNearRay;
#endif

//#if defined(SPOTLIGHT)

  varying mat4 vSpotMatrix;
//#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vModel = modelMatrix;
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




            mat4 rmat = mat4(vec4(1.,0.,0.,0.),
                            vec4(0.,1.,0.,0.),
                            vec4(0.,0.,1.,0.),
                            vec4(-cLightPos.x,-cLightPos.y,-cLightPos.z,1.));

            mat4 mymat = cSpotMatrix;
            mymat[0][2] *= -1;
            mymat[1][2] *= -1;
            mymat[2][2] *= -1;

            vSpotMatrix = mymat*rmat;


    #endif


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
        vec4 bentNormalInput = texture2DProj(sLightBuffer, vScreenPos);
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
        vec4 bentNormalInput = texture2DProj(sLightBuffer, vScreenPos);
    #endif

    // Position acquired via near/far ray is relative to camera. Bring position to world space
    vec3 eyeVec = -worldPos;
    worldPos += cCameraPosPS;

    vec3 normal = (normalInput.rgb * 2.0 - 1.0);
    vec3 bent_normal = (bentNormalInput.rgb * 2.0 - 1.0);
    //normal = bent_normal;
    vec4 projWorldPos = vec4(worldPos, 1.0);
    vec3 lightColor;
    vec3 lightDir;
    float lightDist;
    float diff = GetDiffuse(normal, worldPos, lightDir, bentNormalInput.a, lightDist,bent_normal);
    //float bentDot = clamp(dot(bent_normal,lightDir),0.,1.);
    //diff *= bentDot;
    vec3 dir = normalize(vFarRay);
    float Z = length(eyeVec);
    float vol;


    float minT = 0.0;
    float maxT = 0.0;

    float sminT;
    float smaxT = raySphere(cCameraPosPS-cLightPosPS.xyz, dir, 1./cLightPosPS.w , sminT);

    #if defined(SPOTLIGHT)
        float aperture = cSpotFovPS * 0.5;

        float height = 30.0;


        IntersectCone(cCameraPosPS, dir, vSpotMatrix, aperture, height, minT, maxT);

        // clamp bounds to scene geometry / camera
        maxT = clamp(maxT, 0.0, Z);
        maxT = min(maxT, smaxT);
        minT = clamp(minT, 0.0, maxT);
        minT = max(minT, sminT);
    #else

      maxT =  clamp(smaxT,0.,Z);
      minT = max(0.0, sminT);;
    #endif


    float t = max(maxT - minT,0.);

    vol = min(InScatter(cCameraPosPS + dir*minT, dir, cLightPosPS.xyz, t, cLightPosPS.w) * 0.4,64.);

    //  vol = min(InScatter(cCameraPosPS, dir, cLightPosPS.xyz, Z) * 0.5,16.);


    //float dens = min(sphDensity(cCameraPosPS,normalize(vFarRay),cLightPosPS.xyz,1./cLightPosPS.w, Z),1.);
    //vol *= dens;

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
        gl_FragColor = vec4( vol * lightColor,0.) + diff * vec4(lightColor * (albedoInput.rgb + spec * cLightColor.a * albedoInput.aaa), 0.0);
    #else
        gl_FragColor = diff * vec4(lightColor * albedoInput.rgb, 0.0);
    #endif
}
