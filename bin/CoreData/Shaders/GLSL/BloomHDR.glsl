#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "PostProcess.glsl"

varying vec2 vTexCoord;
varying vec2 vScreenPos;

#ifdef COMPILEPS
uniform float cBloomHDRThreshold;
uniform float cBloomHDRBlurSigma;
uniform float cBloomHDRBlurRadius;
uniform vec2 cBloomHDRBlurDir;
uniform vec2 cBloomHDRMix;
uniform vec2 cBright2InvSize;
uniform vec2 cBright4InvSize;
uniform vec2 cBright8InvSize;
uniform vec2 cBright16InvSize;

const int BlurKernelSize = 5;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetQuadTexCoord(gl_Position);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

vec3 ScreenBlend( vec3 a, vec3 b )
{
 return 1 - ( 1 - a ) * ( 1 - b );
}

void PS()
{
    #ifdef BRIGHT
    vec3 color = texture2D(sDiffMap, vScreenPos).rgb;
    gl_FragColor = vec4(max(color - cBloomHDRThreshold, 0.0), 1.0);
    #endif

    #ifdef BLUR16
    gl_FragColor = GaussianBlur(BlurKernelSize, cBloomHDRBlurDir, cBright16InvSize * cBloomHDRBlurRadius, cBloomHDRBlurSigma, sDiffMap, vScreenPos);
    #endif

    #ifdef BLUR8
    gl_FragColor = GaussianBlur(BlurKernelSize, cBloomHDRBlurDir, cBright8InvSize * cBloomHDRBlurRadius, cBloomHDRBlurSigma, sDiffMap, vScreenPos);
    #endif

    #ifdef BLUR4
    gl_FragColor = GaussianBlur(BlurKernelSize, cBloomHDRBlurDir, cBright4InvSize * cBloomHDRBlurRadius, cBloomHDRBlurSigma, sDiffMap, vScreenPos);
    #endif

    #ifdef BLUR2
    gl_FragColor = GaussianBlur(BlurKernelSize, cBloomHDRBlurDir, cBright2InvSize * cBloomHDRBlurRadius, cBloomHDRBlurSigma, sDiffMap, vScreenPos);
    #endif

    #ifdef COMBINE16
    gl_FragColor = texture2D(sDiffMap, vScreenPos) + texture2D(sNormalMap, vTexCoord);
    #endif

    #ifdef COMBINE8
    gl_FragColor = texture2D(sDiffMap, vScreenPos) + texture2D(sNormalMap, vTexCoord);
    #endif

    #ifdef COMBINE4
    gl_FragColor = texture2D(sDiffMap, vScreenPos) + texture2D(sNormalMap, vTexCoord);
    #endif

    #ifdef COMBINE2
    vec3 color = texture2D(sDiffMap, vScreenPos).rgb * cBloomHDRMix.x;

    float white = 8.;
    //  color *= (1.0 + color / white) / (1.0 + color);
    float L = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.g;
    float nL = (1.0 + L / white) / (1.0 + L);;
    float scale = nL / L;
    color *= nL;
    color = pow(color,vec3( 1/2.2 ));




    // vec3 x = max(vec3(0.0),color-vec3(0.004)); // Filmic Curve
    // color = (x*(6.2*color+.5))/(x*(6.2*x+1.7)+0.06);

    vec3 bloom = texture2D(sNormalMap, vTexCoord).rgb * cBloomHDRMix.y;
    //bloom = bloom/(1+bloom);
    color = ScreenBlend(clamp(color,0,1), bloom);

    gl_FragColor = vec4(color, 1.0);//pow(color,vec3( 1/2.2 ))
    #endif
}
