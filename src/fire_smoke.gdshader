shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float clock=0.0;
uniform float phase=.5;
uniform float seed=0.0;
uniform float strength=1.0;
#include "res://src/fire_field.gdshaderinc"
void fragment(){
 vec2 flow=UV*4.3+vec2(seed,clock*.8);
 float n=fire_fbm(flow+vec2(fire_fbm(flow+3.0),fire_fbm(flow-7.0))*2.0);
 float edge=1.0-smoothstep(.14,.55,length(UV-.5)+(n-.5)*.18);
 float life=smoothstep(0.0,.15,phase)*(1.0-smoothstep(.65,1.0,phase));
 ALBEDO=mix(vec3(.085,.075,.07),vec3(.24,.22,.20),n);
 ALPHA=edge*fire_border(UV)*(.18+n*.38)*strength*life;
}
