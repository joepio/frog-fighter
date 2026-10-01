shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform float phase=0.0;
uniform float clock=0.0;
uniform float strength=1.0;
uniform float seed=0.0;
uniform bool jet=false;
uniform bool jet_contact=false;
uniform float jet_length=4.8;
uniform vec2 jet_up=vec2(0.0,1.0);
uniform float buoyancy=18.0;
uniform sampler2D heat_ramp : source_color, filter_linear, repeat_disable;
#include "res://src/fire_field.gdshaderinc"
void vertex(){
 if(jet){
  float distance=UV.x*jet_length;
  float age=distance/18.0;
  float spread=jet_contact ? 1.0+smoothstep(.65,1.0,UV.x)*.35 : 1.0;
  VERTEX=vec3(distance,(.5-UV.y)*(.18+distance*.55)*spread,0.0);
  VERTEX.xy+=jet_up*(.5*buoyancy*age*age);
 }
}
void fragment(){
 // Every fire wisp flows along local +X. Body wisps rotate this same field upward.
 vec2 p=UV-.5;
 vec2 flow=vec2(UV.x*4.8-clock*3.5+seed,UV.y*5.2+seed*.37);
 if(jet){flow.x=UV.x*jet_length*2.1-clock*14.0+seed;}
 vec2 warp=vec2(fire_fbm(flow+1.7),fire_fbm(flow-4.2));
 float n=fire_fbm(flow+warp*2.8);
 p.y+=sin(UV.x*7.0-clock*5.0+seed)*.055+(n-.5)*.28;
 float radius=length(p*vec2(1.7,2.05));
 float envelope=1.0-smoothstep(.08,.94,radius+(n-.5)*.28);
 float ribbons=smoothstep(.26,.73,n);
 float density=envelope*(.38+ribbons*.74);
 float border=fire_border(UV);
 float life=smoothstep(0.0,.10,phase)*(1.0-smoothstep(.55,1.0,phase));
 if(jet){
  // A connected nozzle-to-tip envelope. Turbulence moves inside it, never per-shot blobs.
  float tip=jet_contact ? 1.0 : 1.0-smoothstep(.83,1.0,UV.x);
  envelope=(1.0-smoothstep(.03,.50,abs(p.y)))*tip;
  float core=1.0-smoothstep(.02,.20,abs(p.y));
  density=envelope*(.52+ribbons*.40)+core*.12;
  // Impact stays luminous right up to the surface. Only a free tip dissipates early.
  border=smoothstep(0.0,.018,UV.x)*(1.0-smoothstep(jet_contact ? .995 : .90,1.0,UV.x));
  life=1.0;
 }
 // Mostly orange; variation comes from optical density. Additive overlap brightens the scene.
 float heat=clamp(pow(density,1.6)*(1.10-phase*.12),0.0,1.0);
 vec4 fire=texture(heat_ramp,vec2(heat,.5));
 ALBEDO=fire.rgb*1.25;
 ALPHA=(fire.a*pow(density,1.05)+envelope*.12)*border*life*strength;
}
