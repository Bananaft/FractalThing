#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "fractal.glsl"
#include "SDF_funcs.glsl"

#define PI acos(-1.)
vec3 distanceMeter(float dist, float rayLength, vec3 wP) {
    float idealGridDistance = 20.0/rayLength;
    float nearestBase = floor(log(idealGridDistance)/log(10.));
    //float relativeDist = abs(dist/camHeight);

    float largerDistance = pow(10.0,nearestBase+1.);
    float smallerDistance = pow(10.0,nearestBase);


    vec3 col = vec3(1.0);
    //col = max(vec3(0.),col);
    //if (sign(dist) < 0.) {
    //    col = col.grb*3.;
    //}

    float l0 = (pow(0.5+0.5*cos(dist*PI*2.*smallerDistance),10.0));
    float l1 = (pow(0.5+0.5*cos(dist*PI*2.*largerDistance),10.0));

    float x = fract(log(idealGridDistance)/log(10.));
    l0 = mix(l0,0.,smoothstep(0.5,1.0,x));
    l1 = mix(0.,l1,smoothstep(0.0,0.5,x));

    float grid = (pow(0.5+0.5*cos(((0.5-fract(wP.x*0.1))*(0.5-fract(wP.z*0.1)))*PI*2.*smallerDistance),1000.0));

    col.rgb *= 0.1+0.9*(1.-l0)*(1.-l1);
    col.gb *= grid;
    return col;
}

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
    vec3 localpos = vFarRay * depth;
    vec3 worldPos = cCameraPosPS + localpos;
    float depth2 = length(localpos);


    vec4 normalInput = texture2D(sNormalBuffer, vScreenPos);
    vec3 normal = (normalInput.rgb * 2.0 - 1.0);
    float ao;
    vec3 bent_normal = (calcNormal(worldPos+normal*0.7, 10.0));

    float ao_free = pow(length(bent_normal)*0.3,4.);
    float ao_size = 0.8;
    bent_normal = normalize(bent_normal);
    float tap_result = max(sdfmap(worldPos + bent_normal*ao_size).w,0.);
    float ao2 = (tap_result+0.08)/ao_size;
    ao2 = max(ao2,0.03);
    ao2 = pow(ao2*2.,3.);
    //ao2 = clamp(ao2,0.,1.0);
    ao = ao2 * ao_free*0.2;
    float final_ao = 1. - (1.0 + ao / 3.) / (1.0 + ao) + tap_result*0.1;

    final_ao = clamp(final_ao,0.,1.0);
    //float ao2 = sdfmap(worldPos+bent_normal*5)
    vec3 col = vec3(0.);

    #ifdef FOG
      float depthclamp = depth2/cFarClipPS;
      vec3 skycol = textureCube(sEnvCubeMap, normalize(vFarRay),pow((1.-depthclamp)*20.,0.8)).rgb * min(pow(depthclamp,1.1),1.) * 2.;
      vec3 reflcol = textureLod(sEnvCubeMap,mix(normal,bent_normal,final_ao),5.+final_ao*6.).rgb;
      float ndot = max(dot(normal,bent_normal)*0.2+0.8,0.);
      float fog = clamp(pow(depth2/cFarClipPS*6.,1.1),0.,1.);
      //skycol = pow(skycol,min(depthclamp,1.0));
      col = 0.1 * reflcol * ndot*(final_ao)*(1.-fog)+skycol*fog*4.;
    #endif
    //if (sdfmap(worldPos + bent_normal).w<0.0) col = vec3(1.,0.1,0.02);
    //if (final_ao > 0.8) col = vec3(1.,0.,0.); else col = vec3(final_ao);

    float dist = sdfmap(worldPos).w;
    col = distanceMeter(dist,depth2,worldPos) * 0.1;
    //col = 1.-col;


    //gl_FragData[0] = vec4(step(0.1,ao),step(0.5,ao),step(0.9,ao),1.0);
    //gl_FragData[0] = vec4(vec3(final_ao),0.);
    //if (vScreenPos.y>0.9)  gl_FragData[0] = vec4(vec3(1.0),0.);
    gl_FragData[0] = vec4(col,1.);
    gl_FragData[1] = vec4(0.5 + bent_normal*0.5, final_ao );

}
