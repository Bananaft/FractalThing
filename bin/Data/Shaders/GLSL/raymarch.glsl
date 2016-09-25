#include "Uniforms.glsl"
#include "Samplers.glsl"
//#define DEFERRED;
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "fractal.glsl"
//out vec4 fragData[4];
//#define gl_FragData fragData

varying vec2 vScreenPos;
varying vec3 vFarRay;
varying vec3 direction;
varying mat4 cViewProjPS;
varying float fov;


void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vec2 pos = GetScreenPosPreDiv(gl_Position);
    vScreenPos = pos;
    pos = pos * 2.0 -1.0;
    cViewProjPS = cViewProj;
    vec3 pos3 = vec3(pos,1.0) * cFrustumSize;
    fov = atan(cFrustumSize.y/cFrustumSize.z);
    direction = normalize(mat3(cView) * pos3);

}

vec3 calcNormal( in vec3 pos , float size )
{
	vec3 eps = vec3( size,  0.0, 0.0 );
	vec3 nor = vec3(
	    sdfmap2(pos+eps.xyy) - sdfmap2(pos-eps.xyy),
	    sdfmap2(pos+eps.yxy) - sdfmap2(pos-eps.yxy),
	    sdfmap2(pos+eps.yyx) - sdfmap2(pos-eps.yyx) );
	return vec3(0.5)+normalize(nor);
}


void PS()
{
  vec2 uv = vScreenPos * 2.0 -1.0;

  const int RAY_STEPS = 96;
  //const float NEAR_CLIP = cNearClipPS;
  //const float FAR_CLIP = cFarClipPS;

  vec3 origin = cCameraPosPS;
  vec3 normal;
  vec3 intersection;
  //vec3 direction = camMat * normalize( vec3(uv.xy,2.0) );
  float distance = 0.;
  float totalDistance = cNearClipPS;
  float lfog = 0.;
  for(int i =0 ;  i < RAY_STEPS; ++i) ////// Rendering main scene
   {
       intersection = origin + direction * totalDistance;
       //float s = sdfmap(intersection);
       distance = sdfmap2(intersection);
       //texs = s.gba;
       totalDistance += distance;
       lfog += max(10.-distance,.0);
       if(distance <= 0.02 || totalDistance >= cFarClipPS)
       {
           //Col = vec3(0.,1.,0.);
           break;
       }
   }
   vec4 clpp = vec4(intersection,1.0) * cViewProjPS;
   vec3 diffColor = vec3(0.5 + sin(intersection.y * 0.6) * 0.3,0.6 + sin(intersection.z * 0.2) * 0.3,1.0);

   vec3 ambient = diffColor.rgb;


  float depth = DecodeDepth(texture2D(sDepthBuffer, vScreenPos).rgb);
  float fdepth = clpp.z /(cFarClipPS);

  if (fdepth>depth) discard;

  normal = calcNormal(intersection, max((1.0 * clpp.z) / (fov / cGBufferInvSize.y),0.001));

  float fog = pow(1.-fdepth,6.6);


  //gl_FragColor = vec4(ambient , 1.0);
  gl_FragData[0] = vec4(vec3(0.3) * (1.-fog), 1.0);
  gl_FragData[1] = vec4(diffColor.rgb * fog, 1.7 );
  gl_FragData[2] = vec4(normal, 1.0);// * 0.5 + 0.5
  gl_FragData[3] = vec4(EncodeDepth(fdepth), 0.0);//
}
