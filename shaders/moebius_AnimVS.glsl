#version 330

uniform mat4 matVP;
uniform mat4 matM;

uniform int frame;
uniform bool moebius;

layout (location = 0) in vec3 vertex;
layout (location = 1) in vec3 normal;

varying vec4 color;	
 
mat4 S(in vec3 s) {
	return mat4(0);
}

mat4 T(in vec3 t) {
	return mat4(0);   	
}

mat4 Ry(in float theta) {
        return mat4(0);
}

mat4 B = mat4(0);


vec4 evalBezier(in float t, in mat4 G) {
        return vec4(0);
}

vec4 evalBezierTan(in float t, in mat4 G) {
        return vec4(0);
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
	
	// A convenient constant
	const vec4 ez = vec4(0,0,1,0);
	
	// ToDo: fill Geometry "vectors" with control points
    mat4 G0 = mat4(0);  // 1st Bezier
    mat4 G1 = mat4(0);  // 2nd Bezier

    // compute time based on frame count
	float t = 4*float(frame)/1000;
	float s = mod(t, 2.0);
	
	// Choose which Bezier to evaluate based on s
	// TODO: compute local axis system on the track
    mat4 Orient = mat4(1.0);
        
    // Todo: For Moebius twist the band
    mat4 Twist = moebius?mat4(1.0):mat4(1.0);
	
	// Todo: Finally, position and scale the original [-1/2,1/2]x[-1/2,1/2]x[-1/2,1/2] cube
	//       to fit precisely on the track in the local coordinate system
	//       establised by Orient and Twist.
	mat4 MM = mat4(0.0);	// initially replace by 1.0 to start seeing the cube
	gl_Position = (matVP * matM * MM) * vec4(vertex, 1);
	
	color = vec4(abs(normal), 1);		
}      	
