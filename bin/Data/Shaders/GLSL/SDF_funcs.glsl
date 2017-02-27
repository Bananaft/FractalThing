vec3 calcNormal( in vec3 pos , float size )
{
	vec3 eps = vec3( size,  0.0, 0.0 );
	vec3 nor = vec3(
	    sdfmap(pos+eps.xyy).w - sdfmap(pos-eps.xyy).w,
	    sdfmap(pos+eps.yxy).w - sdfmap(pos-eps.yxy).w,
	    sdfmap(pos+eps.yyx).w - sdfmap(pos-eps.yyx).w );
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
