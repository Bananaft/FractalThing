vec3 calcNormal( in vec3 pos , float size, out float ao )
{
	vec3 eps = vec3( size,  0.0, 0.0 );

	float x1 = sdfmap(pos+eps.xyy).w;
	float x2 = sdfmap(pos-eps.xyy).w;
	float y1 = sdfmap(pos+eps.yxy).w;
	float y2 = sdfmap(pos-eps.yxy).w;
	float z1 = sdfmap(pos+eps.yyx).w;
	float z2 = sdfmap(pos-eps.yyx).w;

	vec3 nor = vec3(x1 - x2, y1 - y2, z1 - z2);
	ao = x1+x2+y1+y2+z1+z2;
	return nor;
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
  float stp = 0.1;

  for( int i=1; i<4; i++ )
    {
        stp *= i * 2.;
        vec3 aopos =  nor * stp + pos;
        float dd = sdfmap( aopos ).w;
        occ += dd;
        //if (dd<stp) break;
    }

    return min(occ * 0.3,1.);
}
