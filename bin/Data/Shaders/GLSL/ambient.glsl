#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "fractal.glsl"
#include "SDF_funcs.glsl"


varying vec2 vScreenPos;
varying vec3 vFarRay;

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);

    vScreenPos = GetScreenPosPreDiv(gl_Position);
    vFarRay = GetFarRay(gl_Position);
}

void PS()
{
    float depth = DecodeDepth(texture2D(sDepthBuffer, vScreenPos).rgb);
    vec3 worldPos = cCameraPosPS + (vFarRay * depth);

    vec4 normalInput = texture2D(sNormalBuffer, vScreenPos);
    vec3 normal = (normalInput.rgb * 2.0 - 1.0);
    float ao;
    vec3 bent_normal = normalize(calcNormal(worldPos+normal*0.7, 10.0, ao));

    ao = pow(ao*0.04,1.4);
    //ao = clamp(ao,0.,1.0);
    float ao2 = sdfmap(worldPos + bent_normal*25.).w/25.;
    //ao2 = clamp(ao2,0.,1.0);
    //ao = ao * ao2 * 2.;

    ao = clamp(ao,0.,1.0);
    //float ao2 = sdfmap(worldPos+bent_normal*5)


    vec3 skycol = textureCube(sEnvCubeMap, normalize(vFarRay),16.*(1.-depth)).rgb;
    vec3 reflcol = textureLod(sEnvCubeMap,normal,3.+ao*9.).rgb;
    float ndot = max(dot(normal,bent_normal)*0.2+0.8,0.);
    float fog = clamp(pow(depth-0.001,0.9),0.,1.);
    vec3 col = reflcol * ndot*(ao)*(1.-fog)+skycol*fog*4.;



    //gl_FragData[0] = vec4(step(0.1,ao),step(0.5,ao),step(0.9,ao),1.0);
    gl_FragData[0] = vec4(vec3(ao2),0.);
    //if (vScreenPos.x>0.5)  gl_FragData[0] = vec4(vec3(1.0),0.);
    //gl_FragData[0] = vec4(col,1.);
    gl_FragData[1] = vec4(0.5 + bent_normal*0.5, ao );

}
