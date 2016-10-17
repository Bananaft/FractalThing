
float sphDensity( vec3  ro, vec3  rd,   // ray origin, ray direction
                  vec3  sc, float sr,   // sphere center, sphere radius
                  float dbuffer )       // depth buffer
{
    // normalize the problem to the canonical sphere
    float ndbuffer = dbuffer / sr;
    vec3  rc = (ro - sc)/sr;

    // find intersection with sphere
    float b = dot(rd,rc);
    float c = dot(rc,rc) - 1.0;
    float h = b*b - c;

    // not intersecting
    if( h<0.0 ) return 0.0;

    h = sqrt( h );

    //float s = 1. /(sr/h);

    //float l = s * (atan( (dbuffer + b) * s) - atan( b*s ));

    //return h*h*h;

    float t1 = -b - h;
    float t2 = -b + h;

    // not visible (behind camera or behind ndbuffer)
    if( t2<0.0 || t1>ndbuffer ) return 0.0;

    // clip integration segment from camera to ndbuffer
    t1 = max( t1, 0.0 );
    t2 = min( t2, ndbuffer );

    // analytical integration of an inverse squared density
    float i1 = -(c*t1 + b*t1*t1 + t1*t1*t1/3.0);
    float i2 = -(c*t2 + b*t2*t2 + t2*t2*t2/3.0);
    return (i2-i1)*(3.0/4.0);
}

float InScatter(vec3 start, vec3 dir, vec3 lightPos, float d)
{
	// calculate quadratic coefficients a,b,c
	vec3 q = start - lightPos;

	float b = dot(dir, q);
	float c = dot(q, q);

	// evaluate integral
	float s = 1. / sqrt(c - b*b);

	float l = s * (atan( (d + b) * s) - atan( b*s ));

	return l;
}

void SolveQuadratic(float a, float b, float c, out float minT, out float maxT)
{
	float discriminant = b*b - 4.0*a*c;

	if (discriminant < 0.0)
	{
		// no real solutions so return a degenerate result
		maxT = 0.0;
		minT = 0.0;
		return;
	}

	// numerical receipes 5.6 (this method ensures numerical accuracy is preserved)
	float t = -0.5 * (b + sign(b)*sqrt(discriminant));
	float closestT = t / a;
	float furthestT = c / t;

	if (closestT > furthestT)
	{
		minT = furthestT;
		maxT = closestT;
	}
	else
	{
		minT = closestT;
		maxT = furthestT;
	}
}

void IntersectCone(vec3 rayOrigin, vec3 rayDir, mat4 invConeTransform, float aperture, float height, out float minT, out float maxT)
{
	vec4 localOrigin = invConeTransform * vec4(rayOrigin, 1.0);
	vec4 localDir = invConeTransform * vec4(rayDir, 0.0);
	// could perform this on the cpu
	float tanTheta = tan(aperture);
	tanTheta *= tanTheta;

	float a = localDir.x*localDir.x + localDir.y*localDir.y - localDir.z*localDir.z*tanTheta;
	float b = 2.0*(localOrigin.x*localDir.x + localOrigin.y*localDir.y - localOrigin.z*localDir.z*tanTheta);
	float c = localOrigin.x*localOrigin.x + localOrigin.y*localOrigin.y - localOrigin.z*localOrigin.z*tanTheta;

	SolveQuadratic(a, b, c, minT, maxT);

	float y1 = localOrigin.z + localDir.z*minT;
	float y2 = localOrigin.z + localDir.z*maxT;

	// should be possible to simplify these branches if the compiler isn't already doing it

	if (y1 > 0.0 && y2 > 0.0)
	{
		// both intersections are in the reflected cone so return degenerate value
		minT = 0.0;
		maxT = -1.0;
	}
	else if (y1 > 0.0 && y2 < 0.0)
	{
		// closest t on the wrong side, furthest on the right side => ray enters volume but doesn't leave it (so set maxT arbitrarily large)
		minT = maxT;
		maxT = 10000.0;
	}
	else if (y1 < 0.0 && y2 > 0.0)
	{
		// closest t on the right side, largest on the wrong side => ray starts in volume and exits once
		maxT = minT;
		minT = 0.0;
	}
}
