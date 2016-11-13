vec4 sdfmap(vec3 pos)
{
  float dist = 10000.;

  #ifdef FCTYP
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

    dist = ((length(p.xyz) - 1.577) / p.w - 0.00013) * 200.;
    //dist = max(dist,-s);

  #else
    vec3 CSize = vec3(1., 1., 1.3);
    vec3 p = pos.xzy;
    float scale = 1.0;

    float r2 = 0.;
    float k = 0.;
    float uggg = 0.;
    for( int i=0; i < 12;i++ )
    {
        p = 2.0*clamp(p, -CSize, CSize) - p;
        r2 = dot(p,p);
        //float r2 = dot(p,p+sin(p.z*.3)); //Alternate fractal
        k = max((2.0)/(r2), .0274); //.378888 //.13345 max((2.6)/(r2), .03211); //max((1.8)/(r2), .0018);
        p     *= k;
        scale *= k;
        uggg += r2;
    }
    float l = length(p.xy);
    float rxy = l - 4.0;
    float n = 1.0 * p.z;
    rxy = max(rxy, -(n) / 4.);
    dist = (rxy) / abs(scale);
  #endif

  return vec4(0.,0.,0.,dist);
}
