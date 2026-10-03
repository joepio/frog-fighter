shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float age=0.0;
uniform float seed=0.0;
#include "res://src/fire_field.gdshaderinc"
void fragment(){
 vec2 p=(UV-.5)*2.0;
 vec2 flow=UV*4.5+vec2(seed,age*.55);
 float n=fire_fbm(flow+vec2(fire_fbm(flow+7.0),fire_fbm(flow-3.0))*2.2);
 float shape=1.0-smoothstep(.30,.95,length(p)+(n-.5)*.32);
 float life=smoothstep(.06,.23,age)*(1.0-smoothstep(.75,1.65,age));
 float ember=(1.0-smoothstep(.15,.55,age))*(1.0-smoothstep(.0,.8,length(p)));
 vec3 soot=mix(vec3(.09,.075,.06),vec3(.37,.34,.29),n*.75+(1.0-UV.y)*.25);
 ALBEDO=mix(soot,vec3(.84,.32,.055),ember*.7);
 ALPHA=shape*life*(.42+n*.32)*fire_border(UV);
}
