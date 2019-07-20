#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

varying vec4 vertColor;
varying vec4 vertTexCoord;
uniform sampler2D texture;
uniform vec3 color = vec3(1.0);
uniform vec3 colormid = vec3(1.0);
uniform vec3 colordark = vec3(1.0);
uniform float ditheroffset = 0;
vec2 res = vec2(320.,180.);


uniform float [16] bayer;

void main() {
  vec4 texColor = texture2D(texture, vertTexCoord.st).rgba;
  vec4 texColorcopy = texColor;
  if(texColor.b>0.01){
	  vec2 g= mod(vertTexCoord.st*res,vec2(4.0));
	  int fg = int(mod(int(g.x)+int(g.y)*4+int(ditheroffset*10.0*max( 1.0-(texColor.b+0.5),0.0)),16));
	  texColor.r=texColor.r*0.5+0.5;
	  float or = texColor.r;
	  float lor = float(int(or*2.0));
	  int res = 0;
	  if(2.0*mod(texColor.r,0.5)<=bayer[fg]/256.0){
		res = int(round(lor));	
	  }else{
		res = int(round(lor))+1;
	  }
	  if(res==0){
		texColor.rgb = colordark;
	  }
	  if(res==1){
		texColor.rgb = colormid;
	  }
	  if(res==2){
		texColor.rgb = color;
	  }
	  texColor.a=1.0;
	  
	  
  }else{
	texColor=vec4(vec3(0.0),1.0);
  }
  gl_FragColor = texColor;
}