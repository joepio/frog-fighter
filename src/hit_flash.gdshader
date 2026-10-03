shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;
uniform float strength=0.0;
void fragment(){ALBEDO=vec3(1.0,.93,.73);ALPHA=strength;}
