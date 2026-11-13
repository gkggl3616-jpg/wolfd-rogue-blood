shader_type canvas_item;
uniform float aspect=1.77778;
void fragment(){
 vec2 p=(UV-vec2(0.5))*vec2(aspect,1.0);
 float radius=0.42;
 float d=length(p);
 float lines=max(1.0-step(0.0008,abs(p.x)),1.0-step(0.0008,abs(p.y)));
 float alpha=d>radius?1.0:lines;
 COLOR=vec4(0.0,0.0,0.0,alpha);
}
