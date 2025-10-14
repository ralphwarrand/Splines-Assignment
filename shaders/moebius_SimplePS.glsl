#version 330

in VertexData {
 vec4 color;
} VertexIn;

out vec4 outColor;

void main() {
   outColor = VertexIn.color;
}