shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform float age=0.0;
uniform float seed=0.0;
uniform bool shockwave=false;
uniform sampler2D heat_ramp : source_color, filter_linear, repeat_disable;
#include "res://src/fire_field.gdshaderinc"
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float r=length(p);
 if(shockwave){
  float phase=clamp(age/.28,0.0,1.0);
  float radius=.05+.88*pow(phase,.48);
  float turbulence=fire_fbm(p*6.0+vec2(seed,age*3.0));
  float band=exp(-pow((r-radius+(turbulence-.5)*.09)/(.035+.02*(1.0-phase)),2.0));
  ALBEDO=mix(vec3(1.0,.91,.70),vec3(1.0,.49,.12),phase);
  ALPHA=band*pow(1.0-phase,1.7)*.32*smoothstep(.27,.65,turbulence);
 }else{
  vec2 flow=p*3.4+vec2(seed,-age*3.0);
  float n=fire_fbm(flow+vec2(fire_fbm(flow+3.0),fire_fbm(flow-5.0))*1.5);
  float edge=1.0-smoothstep(.36,.99,r+(n-.5)*.40);
  float flash=1.0-smoothstep(.025,.115,age);
  float heat=clamp((1.0-r)*.80+n*.42+flash*.55-age*.50,0.0,1.0);
  vec4 color=texture(heat_ramp,vec2(heat,.5));
  float life=1.0-smoothstep(.16,.66,age);
  ALBEDO=mix(color.rgb,vec3(1.0,.98,.87),flash*(1.0-smoothstep(.1,.65,r)))*(1.4+flash*2.0);
  ALPHA=edge*color.a*life*fire_border(UV);
 }
}
