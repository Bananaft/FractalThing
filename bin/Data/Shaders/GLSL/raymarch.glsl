#include "Uniforms.glsl"
#include "Samplers.glsl"
//#define DEFERRED;
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "fractal.glsl"
#include "SDF_funcs.glsl"
//out vec4 fragData[4];
//#define gl_FragData fragData

uniform float cRAY_STEPS;

varying vec2 vScreenPos;
//varying vec3 direction;
varying mat4 cViewProjPS;
varying float fov;
varying vec3 FrustumSizePS;
varying mat4 ViewPS;


void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vec2 pos = GetScreenPosPreDiv(gl_Position);
    pos = pos;

    vScreenPos = pos;
    //cViewProjPS = cViewProj;
    vec3 pos3 = vec3(pos,1.0) * cFrustumSize;
    fov = atan(cFrustumSize.y/cFrustumSize.z);
    FrustumSizePS = cFrustumSize;
    ViewPS = cView;
    //direction = normalize(mat3(cView) * pos3);

}


void PS()
{
  vec3 locDir = normalize(vec3(vScreenPos * 2.0 -1.0,1.0) * FrustumSizePS);
  vec3 direction = (mat3(ViewPS) * locDir  );
  vec3 origin = cCameraPosPS;
  vec3 intersection;
  //vec3 direction = camMat * normalize( vec3(uv.xy,2.0) );
  float PREdepth =  texture2D(sSpecMap, vScreenPos).r;

  vec4 distance = vec4(0.);
  float totalDistance = PREdepth;// * cFarClipPS;
  float lfog = 0.;
  float pxsz = fov * cGBufferInvSize.y;

  float distTrsh = 0.002;
  int stps = 0;


  for(int i =0 ;  i < cRAY_STEPS; ++i) ////// Rendering main scene
   {
       intersection = origin + direction * totalDistance;

       distance = sdfmap(intersection);
      totalDistance += distance.w;
       //#ifdef PREMARCH
          distTrsh = pxsz * totalDistance * 1.4142;
          #ifdef PREMARCH
          totalDistance -= distTrsh * 0.5;
          #else
            distTrsh *= 0.4;
          #endif

          if(distance.w <= distTrsh || totalDistance >= cFarClipPS) break;
      //  #else
      //    if(distance.w <= 0.002 || totalDistance >= cFarClipPS) break;
      // #endif



      // stps = i;
   }

   #ifndef PREMARCH

     //vec4 clpp = vec4(intersection,1.0) * cViewProjPS;
     float fdepth = (totalDistance*locDir.z)/cFarClipPS; //clpp.z /(cFarClipPS);

      //vec3 diffColor = normalize(vec3(pow(distance.r,-0.6),abs(1.7- distance.g),abs(1.7- distance.b)));
      vec3 diffColor = vec3(0.5);

      //vec3 ambient = diffColor.rgb;

      float depth = DecodeDepth(texture2D(sDepthBuffer, vScreenPos).rgb);

      if (fdepth>depth) discard;

      //float mimus = max( -1000000. * (fdepth - PREdepth), 0.0 );
      //float plus = max( 10. * (fdepth - PREdepth), 0.0 );
      //Normal softening powered by magic.

      vec3 normal = normalize(calcNormal(intersection, max(pow(totalDistance,1.25) * pxsz,0.001)));

      //float fog = min(pow(fdepth * 6.,1.5),1.);//
  #endif



  //gl_FragColor = vec4(ambient , 1.0);
  #ifndef PREMARCH
    //gl_FragData[0] = vec4(mix(0.002 , 0.0001*ao * (1.-fog),1.-fog));//vec4(vec3(0.3) * (1.-fog),1.0); //distance.r * 0.2
    gl_FragData[0] = vec4(diffColor.rgb, 1.0 );
    //gl_FragData[0] = vec4(float(stps)/256,0.,0.,0.);//vec4(float(stps)/cRAY_STEPS,0.,0.,0.);//vec4(mimus , plus,0.,0.); //vec4(vec3(0.3) * (1.-fog),1.0);
    //gl_FragData[1] = vec4(0.);//vec4(diffColor.rgb * fog, 1.7 );



    gl_FragData[1] = vec4(0.5 + normal*0.5, 1.0);// * 0.5 + 0.5
    gl_FragData[2] = vec4(EncodeDepth(fdepth), 0.0);//
    //gl_FragData[3] = vec4(0.5 + bent_normal*0.5, ao);
  #else
    gl_FragColor =  vec4(totalDistance ,0. , 0. , 0.);
  #endif
}
