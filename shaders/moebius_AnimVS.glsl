#version 330

uniform mat4 matVP;
uniform mat4 matM;

uniform int frame;
uniform bool moebius;

layout (location = 0) in vec3 vertex;
layout (location = 1) in vec3 normal;

varying vec4 color;	
 
mat4 S(in vec3 s) {
	// Standard homogeneous scaling matrix
	return mat4(
	vec4(s.x, 0, 0, 0),
	vec4(0, s.y, 0, 0),
	vec4(0, 0, s.z, 0),
	vec4(0, 0, 0, 1)
	);
}

mat4 T(in vec3 t) {
    return mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(t.x, t.y, t.z, 1.0)
    );
}

mat4 Ry(in float theta) {
	// Rotation of theta degress about the Y-axis
    float c = cos(theta);
    float s = sin(theta);
	return mat4(
        vec4(c, 0.0, s, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(-s, 0.0, c, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

const mat4 B = mat4(
    vec4(-1,  3, -3, 1),
    vec4( 3, -6,  3, 0),
    vec4(-3,  3,  0, 0),
    vec4( 1,  0,  0, 0)
);

// It is unclear whether we need to modify the given function template to use
// the control points directly, or just filling G0 and G1 is sufficient. We
// have opted to choose the latter option, since it results in cleaner code
vec4 evalBezier(in float t, in mat4 G) {
    vec4 T = vec4(pow(t, 3), pow(t, 2), t, 1.0);
    return G * B * T;
}

vec4 evalBezierTan(in float t, in mat4 G) {
    vec4 derivT = vec4(3.0 * t * t, 2.0 * t, 1.0, 0.0);	// We take the derivative of cubic bezier function (power rule)
    return G * B * derivT;
}
 
void main(void) {
	// set the control points of the Beziers. They should be 
	// the same as used by the geometry shader to generate the track.
	const vec4 P0 = vec4(+0.5, +0.5,  0.0, 1.0);	
	const vec4 P1 = vec4(+0.5, -0.5,  0.0, 1.0);	
	const vec4 P2 = vec4(-0.5, -0.5,  0.0, 1.0);	
	const vec4 P3 = vec4(-0.5, +0.5,  0.0, 1.0);
	const vec4 P4 = P3 + (P3-P2);
	const vec4 P5 = P0 + (P0-P1);
	
	// more constants: should be the same as the once in geom shader
	const float H = 0.025;   // half of the height of a band
	const float D = 0.1;    // half of the width of a band	
	
	
	// ToDo: fill Geometry "vectors" with control points
    mat4 G0 = mat4(P0, P1, P2, P3);  // 1st Bezier
    mat4 G1 = mat4(P3, P4, P5, P0);  // 2nd Bezier

    // compute time based on frame count
	float t = 4*float(frame)/1000;
	float s = mod(t, 2.0);
	
	float loop_s = mod(t, 4.0); // [0, 4] represents full 2-lap 
	
	// Choose which Bezier to evaluate based on s
	// TODO: compute local axis system on the track
	mat4 G;   // Active geometry matrix
    float u;  // parameter [0, 1] for active curve segment

    if (s < 1.0) {
        G = G0;
        u = s;
    } else {
        G = G1;
        u = s - 1.0; // u becomes [0, 1] for second segment
    }
    
    // Position on the curve (translation)
    vec4 p = evalBezier(u, G);

    // Tangent to the curve (local Y)
    vec4 y_axis = normalize(evalBezierTan(u, G));
    // World up vector
    vec4 z_axis = vec4(0.0, 0.0, 1.0, 0.0);             
    vec4 x_axis = vec4(cross(y_axis.xyz, z_axis.xyz), 0.0); 

    mat4 Orient = mat4(x_axis, y_axis, z_axis, p);
        
    // Todo: For Moebius twist the band
    mat4 Twist = moebius ? Ry(s * radians(90.f)) : mat4(1.0);
	
	// Todo: Finally, position and scale the original [-1/2,1/2]x[-1/2,1/2]x[-1/2,1/2] cube
	//       to fit precisely on the track in the local coordinate system
	//       establised by Orient and Twist.
	
	mat4 S_cube = S(vec3(2.0 * D, 2.0 * D, 2.0 * D));
	
	// We create a translation matrix to lift the cube onto the track, dependent on loop in mobius strip
	// This oneliner checks if we are on moebius strip, if yes flip sign of offset
	mat4 T_cube = moebius && (loop_s  >= 2.0) ? T(vec3(0.0, 0.0,  -(H + D))) : T(vec3(0.0, 0.0,  H + D));
	
	mat4 MM = Orient * Twist * T_cube * S_cube;
	
	gl_Position = (matVP * matM * MM) * vec4(vertex, 1);
	
	color = vec4(abs(normal), 1);		
}      	
