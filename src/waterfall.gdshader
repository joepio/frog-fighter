shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform float flow_time=0.0;
varying vec3 point;
void vertex(){
	VERTEX.z+=sin(UV.y*26.0-flow_time*6.0+UV.x*11.0)*.028;
	point=VERTEX;
}
void fragment(){
	float threads=sin(UV.x*75.0+sin(UV.y*16.0-flow_time*4.0)*.5);
	float streak=pow(max(0.0,sin(UV.y*43.0-flow_time*12.0+UV.x*21.0)),7.0);
	vec3 deep=vec3(.14,.36,.30);
	vec3 foam=vec3(.73,.88,.80);
	ALBEDO=mix(deep,foam,.4+threads*.13+streak*.32);
	ROUGHNESS=.24;SPECULAR=.6;
	EMISSION=foam*streak*.12;
	ALPHA=smoothstep(0.0,.08,UV.x)*smoothstep(0.0,.08,1.0-UV.x)*(.65+streak*.25);
}
