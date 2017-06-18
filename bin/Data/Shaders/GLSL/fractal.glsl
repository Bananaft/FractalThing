#define pi 3.14159

uniform float cIterations;
/*mat3 rot = mat3(
  0.754,0.4893,0.4381,
  0.5279,-0.0548,-0.8475,
  -0.3908,0.8703,-0.2997
  );//*/
mat3 rot = mat3(
  0.9997,-0.0116,-0.1215,
  0.0287,0.992,-0.1256,
  0.0226,0.1253,0.9918
  );//*/



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

float apo(vec3 pos, float seed,vec3 CSize, vec3 C)
{
  float dist;
  //vec3 CSize = vec3(1., 1., 1.3);
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
      k = max((2.0)/(r2), seed); //.378888 //.13345 max((2.6)/(r2), .03211); //max((1.8)/(r2), .0018);
      p     *= k;
      scale *= k;
      uggg += r2;
      p+=C;
       p.xyz = vec3(-1.0*p.z,1.0*p.x,1.0*p.y);
      //p *= rot;
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
    //  p.xyz *= rot;
  	}

    dist = ((length(p.xyz) - 1.577) / p.w - 0.00013) * 200.;
    //dist = max(dist,-s);
  #elif defined FCTYP_2
      dist = apo(pos, 0.01, vec3(1.4,0.87, 1.1), vec3(0.02,-0.33332,-0.09092));
  #elif defined FCTYP_3

    //float t = cElapsedTimePS * 0.08;
    pos *= 1./400.;

    //vec4 c = 0.5*vec4(cos(t),cos(t*1.1),cos(t*2.3),cos(t*3.1));
    vec4 c = vec4(-0.32,0.59,-0.29,0.32);
    vec4 z = vec4( pos, 0.0 );
    vec4 nz;

    float md2 = 1.0;
    float mz2 = dot(z,z);

    for(int i=0;i<16;i++)
    {

      md2*=4.0*mz2;
        nz.x=z.x*z.x-dot(z.yzw,z.yzw);
      nz.yzw=2.0*z.x*z.yzw;
      z=nz+c;

      mz2 = dot(z,z);
      if(mz2>4.0) break;

      //z.yzw *= rot;
      //z.zwy *= rot;
      //c.yzw *= rot;
    }

    dist = 400. * 0.25*sqrt(mz2/md2)*log(mz2);
  #elif defined FCTYP_4
    float scl = 128;
    vec4 sdf1 = texture2D(sDiffMap, pos.xz * 0.0016);
    vec4 sdf2 = texture2D(sDiffMap, pos.yz * 0.0016);
    vec4 sdf3 = texture2D(sDiffMap, pos.xy * 0.0016);


    dist =  max((-0.5 + sdf1.r),(-0.5 + sdf2.g)) * scl;
    dist =  max(dist,(-0.5 + sdf3.b) * scl);
   //dist =  (- 0.5 + sdf2.g) * scl;
  #elif defined FCTYP_5

  const float boxScale = 0.9;
  const float sphereScale = 1.0;
  const float boxFold = 0.917;
  float mR2 = boxScale * boxScale;    // Min radius
  float fR2 = sphereScale * mR2;      // Fixed radius

  vec4 p = vec4(pos * 0.005,1);
  vec4 p0 = p;  // p.w is the distance estimate

  for (int i = 0; i < 10; i++)
  {
    p.xyz = clamp(p.xyz, -boxFold, boxFold) * 2.0 * boxFold - p.xyz;  // box fold

    float d = dot(p.xyz, p.xyz);
    p.xyzw *= clamp(max(fR2 / d, mR2), 0.0, 1.0);  // sphere fold

    p.xyzw = p * vec4(vec3(-2.81),2.81) + p0;

  }

  dist = ((length(p.xyz) - 0.1) / p.w - 0.00019) * 200.;
  //dist = max(dist,-s);
  #elif defined FCTYP_6
      vec4 p = vec4(pos * 0.005,1);
      vec4 p0 = p;  // p.w is the distance estimate

      for (int i = 0; i < 10; i++)
      {
      p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;

      // sphere folding: if (r2 < minRad2) p /= minRad2; else if (r2 < 1.0) p /= r2;
      float r2 = dot(p.xyz, p.xyz);
      p *= clamp(max(.012/r2, .004), 0.0, 1.0);
      //p.xyz = vec3(1.0*p.y,1.0*p.z,1.0*p.x);
      // scale, translate
      p = p*vec4(495.4 + pos.y * 0.05) + p0;
      //p.xyz += vec3(0.077 * p.z,0.33333,0.12);
      //  p.xyz *= rot;
      }

      dist = ((length(p.xyz) - max(-42.577-pos.y * 0.067,1.557)) / p.w - 0.00019) * 200.;
  #elif defined FCTYP_7
    vec3 p = pos * 0.0002;
    vec4 q = vec4(p - 1.0, 1);
    for(int i = 0; i < 11; i++) {
      q.xyz = abs(q.xyz + 1.0) - 1.0;
      q /= clamp(dot(q.xyz, q.xyz), 0.12, 1.0);
      q *= 1.837;// + p.y*0.8;
    }
    dist = (length(q.xz) - 1.2)/q.w * 5000.;

  #else
    dist = apo(pos, .0274, vec3(1., 1., 1.3), vec3(0.));
  #endif

  return vec4(0.,0.,0.,dist);
}
