#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

varying vec4 vertColor;
varying vec4 vertTexCoord;
uniform sampler2D texture;
uniform vec3 color = vec3(1.0);


uniform float [16] bayer;

void main() {
  vec4 texColor = texture2D(texture, vertTexCoord.st).rgba;
  vec2 g= mod(gl_FragCoord.xy,vec2(4.0));
  int fg = int(g.x)+int(g.y)*4;
  float or = texColor.r;
  float lor = float(int(or*2.0))/2.0;
  if(2.0*mod(texColor.r,0.5)<=bayer[fg]/256.0){
	texColor = vec4(vec3( lor)*color,1.0);
	
  }else{
	texColor = vec4(vec3( lor+0.5)*color,1.0);
  }
  gl_FragColor = texColor;
}