#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "fractal.glsl"

void VS()
{
    gl_Position = vec4(-1.0 + iPos.x,-1.0 + iPos.y,0.0,1.0);

}
void PS()
{
  gl_FragData[0] = vec4(vec3(0.3), 1.0);
  gl_FragData[1] = vec4(vec3(0.5), 1.7 );
  gl_FragData[2] = vec4(0.0,1.0,0.0, 1.0);
}
