float sdfmap(vec3 p)
{
    vec3 CSize = vec3(1., 1., 1.3);
    p = p.xzy;
    float scale = 0.4;
    for( int i=0; i < 12;i++ )
    {
        p = 2.0*clamp(p, -CSize, CSize) - p;
        float r2 = dot(p,p);
        //float r2 = dot(p,p+sin(p.z*.3)); //Alternate fractal
        float k = max((2.)/(r2), .027);
        p     *= k;
        scale *= k;
    }
    float l = length(p.xy);
    float rxy = l - 4.0;
    float n = 1.0 * p.z;
    rxy = max(rxy, -(n) / 4.);
    return (rxy) / abs(scale);

}

#define SCALE 2.577
#define MINRAD2 .005
float minRad2 = clamp(MINRAD2, 1.0e-15, 1.0);
vec4 scale = vec4(SCALE, SCALE, SCALE, abs(SCALE)) / minRad2;
float absScalem1 = abs(SCALE - 1.0);
float AbsScaleRaisedTo1mIters = pow(abs(SCALE), float(1-10));

vec4 sdfmap2(vec3 pos)
{
  //float s = p.x;
  vec4 p = vec4(pos * 0.02,1);
	vec4 p0 = p;  // p.w is the distance estimate

	for (int i = 0; i < 9; i++)
	{
		p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;

		// sphere folding: if (r2 < minRad2) p /= minRad2; else if (r2 < 1.0) p /= r2;
		float r2 = dot(p.xyz, p.xyz);
		p *= clamp(max(minRad2/r2, minRad2), 0.0, 1.0);

		// scale, translate
		p = p*scale + p0;
	}

  float dist = ((length(p.xyz) - absScalem1) / p.w - AbsScaleRaisedTo1mIters);
  //dist = max(dist,-s);
  return vec4(0.,0.,0.,dist * 50.);

}
