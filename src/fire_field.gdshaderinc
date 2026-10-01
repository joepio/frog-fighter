float fire_hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float fire_noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(fire_hash(i),fire_hash(i+vec2(1,0)),f.x),mix(fire_hash(i+vec2(0,1)),fire_hash(i+vec2(1,1)),f.x),f.y);}
float fire_fbm(vec2 p){return fire_noise(p)*.57+fire_noise(p*2.07+7.1)*.28+fire_noise(p*4.13+17.3)*.15;}
float fire_border(vec2 uv){return smoothstep(0.0,.15,uv.x)*smoothstep(0.0,.15,1.0-uv.x)*smoothstep(0.0,.15,uv.y)*smoothstep(0.0,.15,1.0-uv.y);}
