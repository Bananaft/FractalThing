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

vec4 sdfmap2(vec3 p)
{
  //float s = p.x;
  vec3 CSize = vec3(1., 1., 1.3);
  p = p.xzy;
  float scale = 1.0;

  float r2 = 0.;
  float k = 0.;
  for( int i=0; i < 12;i++ )
  {
      p = 2.0*clamp(p, -CSize, CSize) - p;
      r2 = dot(p,p);
      //float r2 = dot(p,p+sin(p.z*.3)); //Alternate fractal
      k = max((2.0)/(r2), .0274); //.378888 //.13345 max((2.6)/(r2), .03211);
      p     *= k;
      scale *= k;
  }
  float l = length(p.xy);
  float rxy = l - 4.0;
  float n = 1.0 * p.z;
  rxy = max(rxy, -(n) / 4.);
  float dist = (rxy) / abs(scale);
  //dist = max(dist,-s);
  return vec4(r2,k,l,dist);

}
