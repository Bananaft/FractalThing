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
    float ao;
    vec3 bent_normal = calcNormal(worldPos+normalInput.rgb*0.7, 10.0, ao);

    //float ao = calcAO(intersection,normal);
    //float ao = length(bent_normal) * 0.1 - 0.3;
    ao = pow(ao*0.04,1.3);

    normalize(bent_normal);


    //gl_FragData[0] = vec4(step(0.1,ao),step(0.5,ao),step(0.9,ao),1.0);
    gl_FragData[0] = vec4(0.0);
    gl_FragData[1] = vec4(0.5 + bent_normal*0.5, ao );

}
