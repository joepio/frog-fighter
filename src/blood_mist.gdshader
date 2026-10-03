shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float phase=0.0;
uniform float opacity=.48;
uniform vec3 tint : source_color=vec3(.49,.055,.075);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float edge=1.0-smoothstep(.18,1.0,length(p));
 float billow=noise(UV*5.0+vec2(phase*.6,-phase*.45))*.65+noise(UV*13.0-vec2(phase*.7,phase*.4))*.35;
 float fine=noise(UV*64.0+phase*.4);
 float density=smoothstep(.17,.75,billow)*mix(.72,1.0,fine);
 ALBEDO=tint;
 ALPHA=edge*density*opacity*(1.0-phase)*(1.0-phase)*smoothstep(0.0,.035,phase);
}
