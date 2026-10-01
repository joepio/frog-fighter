shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, fog_disabled;
uniform sampler2D backdrop : source_color, filter_linear;
void fragment(){
	vec2 d=1.0/vec2(textureSize(backdrop,0));
	vec3 c=vec3(0.0);float total=0.0;
	// Dense Gaussian taps replace the separated nine-sample grid that made blocky echoes.
	for(int y=-2;y<=2;y++){
		for(int x=-2;x<=2;x++){
			float weight=exp(-float(x*x+y*y)/3.0);
			c+=texture(backdrop,clamp(UV+vec2(float(x),float(y))*d*1.4,vec2(0),vec2(1))).rgb*weight;
			total+=weight;
		}
	}
	c/=total;
	float center=1.0-smoothstep(.05,.60,length(UV-vec2(.5,.48)));
	ALBEDO=mix(c,vec3(dot(c,vec3(.3,.5,.2))),.12)*(.74-center*.18);
}
