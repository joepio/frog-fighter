shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform float opacity=1.0;
uniform float heat=1.0;
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float core=exp(-dot(p*vec2(1.1,1.8),p*vec2(1.1,1.8))*2.2);
 float edge=1.0-smoothstep(.65,1.0,length(p));
 ALBEDO=mix(vec3(1.0,.25,.025),vec3(1.0,.92,.65),heat);
 ALPHA=core*edge*opacity;
}
