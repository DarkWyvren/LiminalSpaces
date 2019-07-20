#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

varying vec4 vertColor;
varying vec4 vertTexCoord;
uniform sampler2D texture;
uniform float tick;
uniform float input1;
uniform float input2;
uniform float input3;
uniform float input4;
uniform vec3 cinput1;
uniform vec3 cinput2;
vec2 res = vec2(320.,180.);


void main() {
  vec4 texColor = texture2D(texture, vertTexCoord.st+vec2(input1* sin(input2*tick),input3* cos(input4*tick))).rgba;
  gl_FragColor = texColor;
}