#version 330

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 normal;

out VertexData {
 vec4 color;
 vec4 pos;
} OutData;

void main() {
   OutData.color = vec4(sign(pos.xy), 0.0, 1.0);
   OutData.pos = vec4(pos, 1.0);
   
   gl_Position = vec4(pos, 1);
}
