#version 330 core
		
layout( lines_adjacency ) in;
layout( line_strip, max_vertices=256 ) out;
			
in VertexData{
    vec4 color;
    vec4 pos;
} VertexIn[4];


out VertexData {
 vec4 color;
} VertexOut;

uniform mat4 matP;
uniform mat4 matV;
uniform mat4 matGeo;
uniform bool moebius;
									
//uniform int uNum;
int uNum = 15;			
float D = 0.1;    // half of the width of a band
float H = 0.025;  // half of the height of a band

/* translation over vector v */	
mat4 T(in vec3 v) {
        return mat4(0);
}

/* rotation over theta degrees */
mat4 Ry(in float theta) {
	return mat4(0);    // TODO
}

/* Bezier generation matrix */
mat4 B = mat4(0);

/* returns point at position t of Bezier curve
   with control points G[0], G[1], G[2], and G[3]. */
vec4 evalBezier(in float t, in mat4 G) {
		// Coefficient matrix for a cubic Bezier spline with four control points.
		mat4 M = mat4(-1, 3, -3, 1, 3, -6, 3, 0, -3, 3, 0, 0, 1, 0, 0, 0);
		// Variable vector for a cubic Bezier spline.
		vec4 U = vec4(pow(t, 3), pow(t, 2), t, 1);
		// The Bezier generation matrix, corresponding to matrix C of Variant 1
		// in the lecture slides.
		B = M * G;
        return U * B; // TODO
}
/* returns tangent at Bezier point evalBezier(t,G). */
vec4 evalBezierTan(in float t, in mat4 G) {
		// Coefficient matrix for the first derivative of
		// a cubic Bezier spline with four control points.
		mat4 M_derivative = mat4(0, 0, 0, 0, 3, 9, 9, 3, 6, -12, 6, 0, -3, 3, 0, 0);
		// Variable vector.
		vec4 U = vec4(pow(t, 3), pow(t, 2), t, 1);
		// The Bezier derivative generation matrix.
		mat4 B_derivative = M_derivative * G;
        return U * B_derivative;  // TODO
}

void genVertex(in vec4 v, in mat4 matMVP, in vec4 col) {
	gl_Position =  matMVP * v;
	VertexOut.color = col;
	EmitVertex();
}

void main( )
{
    // // TODO: set Geometry "vector" with control points
    
    // The four control points are available as gl_in[i].gl_Position.
    // Transpose because we need them to become row vectors.
    mat4 G = transpose(mat4(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position, gl_in[3].gl_Position));
	
	mat4 matMVP = matP * matV * matGeo;  	 
	
	// TODO: replace the following by generating a Bezier curve
	// using a line strip and later on extend it to 4 triangle strips:
	// two for the sides, one for the top, and fot the bottom of the track.
	
	// We're iterating over all points in the inner Bezier curve, with an extra point to close the loop.
	for (int i = 0; i <= uNum; ++i){
		// z-vector.
		vec4 z = vec4(0, 0, 1, 0);
		// y-vector is a normal vector tangential to the curve.
		// The iterative veriable is converted to a float to prevent truncation.
		vec4 y = normalize(evalBezierTan(float(i) / uNum, G));
		// x-vector is a normal vector orthogonal to both the y and z vector.
		// Since we're using a right-handed system, we're using this cross product order.
		// The cross product of two orthonormal vectors is normal.
		// We're converting between 3D and 4D vector because the cross product isn't defined for 4D vectors.
		vec4 x = vec4(cross(vec3(y), vec3(z)), 0);
		
		// Local-to-world transformation as demonstrated in the "viewing" lecture.
		// The origin of the local coordinate system is a point on the Bezier curve.
		mat4 inverseOrient = mat4(x, y, z, evalBezier(float(i) / uNum, G));
		// World-to-local transformation as demonstrated in the "viewing" lecture.
		mat4 Orient = inverse(inverseOrient);
		
		// Calculating global coordinates for the inner Bezier curve.
		vec4 global_Bezier = evalBezier(float(i) / uNum, G);
		// Local coordinates for the curve.
		vec4 local_Bezier = Orient * global_Bezier;
		
		// Vertices in the inner Bezier curve can immediately use the global Bezier coordinates.
    	genVertex(global_Bezier, matMVP, vec4(1, 1, 1, 0));
    	
    	// Vertices in the outer curve are transposed by 2D in the direction
    	// perpendicular to the inner curve, which is x in local coordinates.
    	genVertex(inverseOrient * (local_Bezier + vec4(2 * D, 0, 0, 0)), matMVP, vec4(1, 1, 1, 0));
    }
	
	EndPrimitive();
}
	