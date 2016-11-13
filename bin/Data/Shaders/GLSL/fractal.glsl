

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


vec4 sdfmap2(vec3 pos)
{

  //float s = p.x;
  vec4 p = vec4(pos * 0.005,1);
	vec4 p0 = p;  // p.w is the distance estimate

	for (int i = 0; i < 10; i++)
	{
		p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;

		// sphere folding: if (r2 < minRad2) p /= minRad2; else if (r2 < 1.0) p /= r2;
		float r2 = dot(p.xyz, p.xyz);
		p *= clamp(max(.005/r2, .005), 0.0, 1.0);

		// scale, translate
		p = p*vec4(515.4) + p0;
	}

  float dist = ((length(p.xyz) - 1.577) / p.w - 0.0001);
  //dist = max(dist,-s);
  return vec4(0.,0.,0.,dist * 200.);

}
