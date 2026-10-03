shader_type spatial;
render_mode cull_disabled;
uniform sampler2D garden : source_color, filter_linear_mipmap;
uniform float flow_time=0.0;
varying vec3 point;
void vertex(){point=VERTEX;}
void fragment(){
 float t=flow_time;vec2 p=point.xz;
 float wave=sin(p.x*1.3+p.y*2.1+t*.7)*.5+sin(p.x*.65-p.y*3.0-t*.55)*.3;
 vec2 distortion=vec2(sin(p.y*2.3+t*.5),wave)*.017;
 vec3 reflected=texture(garden,vec2(UV.x,0.68-UV.y*.40)+distortion).rgb;
 vec3 pond=mix(vec3(.09,.25,.26),vec3(.24,.40,.39),wave*.3+.5);
 ALBEDO=mix(pond,reflected*vec3(.52,.72,.79),.24);
 float line=pow(max(0.0,sin(p.y*5.5+p.x*.28+wave*.8)),34.0);
 ALBEDO+=vec3(.17,.26,.24)*line*.60;
 NORMAL=normalize(NORMAL+vec3(sin(p.x*1.3+p.y*2.1+t*.7)*.055,0.0,cos(p.x*.65-p.y*3.0-t*.55)*.075));
 EMISSION=ALBEDO*.16;ROUGHNESS=.24;SPECULAR=.6;METALLIC=.12;
}
