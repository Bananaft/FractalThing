#include "Uniforms.glsl"
#include "Samplers.glsl"
//#define DEFERRED;
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "fractal.glsl"
//out vec4 fragData[4];
//#define gl_FragData fragData

uniform float cRAY_STEPS;
uniform float cSizeDiv;

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

  vec3 origin = cCameraPosPS;
  vec3 normal;
  vec3 intersection;
  //vec3 direction = camMat * normalize( vec3(uv.xy,2.0) );
  float distance = 0.;
  float totalDistance = cNearClipPS;
  float lfog = 0.;
  float pxsz = fov * cGBufferInvSize.y;
  #ifdef PREMARCH
    pxsz *= cSizeDiv * 64 * 4;
  #endif
  float distTrsh = 0.02;

  for(int i =0 ;  i < cRAY_STEPS; ++i) ////// Rendering main scene
   {
       intersection = origin + direction * totalDistance;

       distance = sdfmap2(intersection);

       #ifdef PREMARCH
          distTrsh = pxsz * totalDistance/cFarClipPS;
       #endif
       if(distance <= distTrsh || totalDistance >= cFarClipPS)
       {
           break;
       }
       totalDistance += distance;
   }
   vec4 clpp = vec4(intersection,1.0) * cViewProjPS;
   float fdepth = clpp.z /(cFarClipPS);

   #ifndef PREMARCH
      vec3 diffColor = vec3(0.5 + sin(intersection.y * 0.6) * 0.3,0.6 + sin(intersection.z * 0.2) * 0.3,1.0);

      vec3 ambient = diffColor.rgb;

      float depth = DecodeDepth(texture2D(sDepthBuffer, vScreenPos).rgb);
      float depth16 = DecodeDepth(texture2D(sSpecMap, vScreenPos).rgb);

      if (fdepth>depth) discard;

      float mimus = max( -1000000. * (fdepth - depth16), 0.0 );
      float plus = max( 100. * (fdepth - depth16), 0.0 );
      //Normal softening powered by magic.
      normal = calcNormal(intersection, max(pow(clpp.z,1.3) * pxsz,0.001));

      float fog = pow(1.-fdepth,6.6);
  #endif

  //gl_FragColor = vec4(ambient , 1.0);
  #ifndef PREMARCH
    gl_FragData[0] = vec4(mimus , plus,0.,0.);
    gl_FragData[1] = vec4(diffColor.rgb * fog, 1.7 );
    gl_FragData[2] = vec4(normal, 1.0);// * 0.5 + 0.5
    gl_FragData[3] = vec4(EncodeDepth(fdepth), 0.0);//
  #else
    gl_FragColor =  vec4(EncodeDepth(fdepth), 0.0);
  #endif
}
