#version 330 core
		
layout( lines_adjacency ) in;
layout( triangle_strip, max_vertices=256 ) out;
			
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
    return mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(v.x, v.y, v.z, 1.0)
    );
}

/* rotation over theta degrees */
mat4 Ry(in float theta) {
    float c = cos(theta);
    float s = sin(theta);
	return mat4(
        vec4(c, 0.0, s, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(-s, 0.0, c, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

/* Bezier generation matrix */
// Coefficient matrix for a cubic Bezier spline with four control points.
const mat4 B = mat4(
    vec4(-1, 3, -3, 1),
    vec4(3, -6, 3, 0),
    vec4(-3, 3, 0, 0),
    vec4(1, 0, 0, 0)
);

/* returns point at position t of Bezier curve
   with control points G[0], G[1], G[2], and G[3]. */
vec4 evalBezier(in float t, in mat4 G) {
    vec4 T = vec4(pow(t, 3), pow(t, 2), t, 1.0);
    return G * B * T;
}
/* returns tangent at Bezier point evalBezier(t,G). */
vec4 evalBezierTan(in float t, in mat4 G) {
    vec4 derivT = vec4(3.0 * t * t, 2.0 * t, 1.0, 0.0);	// We take the derivative of cubic bezier function (power rule)
    return G * B * derivT;
}

// Helper function to compute the local-to-world transformation at parameter t
mat4 computeOrient(in float t, in mat4 G) {
	// Calculate the origin and axes for the local coordinate system
    vec4 p = evalBezier(t, G); // Position (origin)
    vec4 y_axis = normalize(evalBezierTan(t, G));	// Tangent (Y-axis)
    vec4 z_axis = vec4(0, 0, 1, 0);	// World Up (Z-axis)
    // Perpendicular (X-axis).We don't have to normalize it since the cross product of two orthonormal vectors is normal
    vec4 x_axis = vec4(cross(y_axis.xyz, z_axis.xyz), 0.0); 
    
    // Construct the local-to-world transformation matrix
    mat4 orient = mat4(x_axis, y_axis, z_axis, p);

	// Apply the twist if set
    if (moebius) {
    	// twisting around Y by PI * t, so the strip does a full rotation when it connects back to itself
        mat4 Twist = Ry(t * radians(180.f));
        orient = orient * Twist;
    }
    return orient;
}

void genVertex(in vec4 v, in mat4 matMVP, in vec4 col) {
	gl_Position =  matMVP * v;
	VertexOut.color = col;
	EmitVertex();
}

void main( )
{
	// We set the control points as col vectors as geometry matrix. I am confused why we would take them as row vectors
    mat4 G = mat4(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position, gl_in[3].gl_Position);
	
	mat4 matMVP = matP * matV * matGeo;  	 
	
    // Define colors for the track
    vec4 top_bottom_color = vec4(1.f, 0.f, 1.f, 1.0);
    vec4 side_color = vec4(1.f, 1.f, 0.f, 1.0);

    // Generate top triangle strip
    for (int i = 0; i <= uNum; ++i) {
    	// Map the 16 integers to [0,1]. We're converting i to a float to prevent truncation
        float t = float(i) / uNum;
        mat4 orient = computeOrient(t, G);
        
        // Top of strip, so H is positive and D constrols local left and right direction
        vec4 v_left  = orient * vec4(-D, 0, H, 1.0);
        vec4 v_right = orient * vec4( D, 0, H, 1.0);
        genVertex(v_left, matMVP, top_bottom_color);
        genVertex(v_right, matMVP, top_bottom_color);
    }
    EndPrimitive();
    
    // Generate bottom triangle strip
    for (int i = 0; i <= uNum; ++i) {
        float t = float(i) / uNum;
        mat4 orient = computeOrient(t, G);
        // Bottom of strip, so H is negative and D constrols local left and right direction
        vec4 v_left  = orient * vec4(-D, 0, -H, 1.0);
        vec4 v_right = orient * vec4( D, 0, -H, 1.0);
        genVertex(v_left, matMVP, top_bottom_color);
        genVertex(v_right, matMVP, top_bottom_color);
    }
    EndPrimitive();
    
    // Generate left triangle strip
    for (int i = 0; i <= uNum; ++i) {
        float t = float(i) / uNum;
        mat4 orient = computeOrient(t, G);
        // Strip joins top and bottom verts on left side of D direction
        vec4 v_top = orient * vec4(-D, 0.0, H, 1.0);
        vec4 v_bot = orient * vec4(-D, 0.0, -H, 1.0);
        genVertex(v_top, matMVP, side_color);
        genVertex(v_bot, matMVP, side_color);
    }
    EndPrimitive();

    // Generate Right triangle strip
    for (int i = 0; i <= uNum; ++i) {
        float t = float(i) / uNum;
        mat4 orient = computeOrient(t, G);
        // Strip joins top and bottom verts on right side of D direction
        vec4 v_top = orient * vec4(D, 0.0, H, 1.0);
        vec4 v_bot = orient * vec4(D, 0.0, -H, 1.0);
        genVertex(v_top, matMVP, side_color);
        genVertex(v_bot, matMVP, side_color);
    }
    EndPrimitive();
}
