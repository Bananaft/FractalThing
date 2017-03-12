float hash(float h) {
	return fract(sin(h) * 43758.5453123);
}

vec3 pointRepetition(vec3 point, vec3 c)
{
	point.x = mod(point.x, c.x) - 0.5*c.x;
	point.z = mod(point.z, c.z) - 0.5*c.z;
	return point;
}

float noise3d(vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 157.0 + 113.0 * p.z;
	return mix(
			mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
					mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
			mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
					mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

float apo(vec3 pos, float seed, int steps)
{
  float dist;
  vec3 CSize = vec3(1., 1., 1.3);
  vec3 p = pos.xzy;
  float scale = 1.0;

  float r2 = 0.;
  float k = 0.;
  float uggg = 0.;
  for( int i=0; i < steps;i++ )
  {
      p = 2.0*clamp(p, -CSize, CSize) - p;
      r2 = dot(p,p);
      //float r2 = dot(p,p+sin(p.z*.3)); //Alternate fractal
      k = max((2.0)/(r2), seed); //.378888 //.13345 max((2.6)/(r2), .03211); //max((1.8)/(r2), .0018);
      p     *= k;
      scale *= k;
      uggg += r2;
  }
  float l = length(p.xy);
  float rxy = l - 4.0;
  float n = 1.0 * p.z;
  rxy = max(rxy, -(n) / 4.);
  dist = (rxy) / abs(scale);
  return dist;
}

vec4 sdfmap(vec3 pos)
{
  float dist = 10000.;

  #ifdef FCTYP_1
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
  #ifdef FCTYP_2

    vec3 npos = pos;

    npos.xz *= 0.6;

    float noise = noise3d(npos * 0.1) * 10.;

    vec3 apopos = pointRepetition(pos,vec3(500.,0,500.));

    float apodist = 0.1 * (7+pos.y) - apo(apopos * 0.5, .0274,9) * 2.;
    dist = 0.2  * (pos.y+20.) + noise;
    dist = min(mix(pos.y,noise,0.89) -(apodist),dist+apodist);

  #else
    dist = apo(pos, .0274,12);
  #endif
  #endif

  return vec4(0.,0.,0.,dist);
}
