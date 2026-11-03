shader_type canvas_item;
render_mode unshaded;
// Independently authored analytical elemental defenses. No texture, copied
// artwork, screen input, gameplay mask, silhouette fill or high-frequency flash.
uniform int family = 0;
uniform int kind = 12;
uniform float phase = 0.0;
uniform float clock_s = 0.0;
uniform float seed = 0.0;
uniform float density = 1.0;
uniform float flash = 0.0;
uniform vec4 accent : source_color = vec4(1.0);
uniform int secondary_family = 0;
uniform vec4 secondary_accent : source_color = vec4(1.0);
uniform float integrity_layers = 0.0;
uniform float initial_integrity = 0.0;
uniform float breakthrough = 0.0;
uniform float clash_ornament = 1.0;
uniform float strain = 0.0;
uniform float warning_tier = 0.0;
uniform float cue = 0.0; // 0 owned guard, 1 contact, 2 rupture, 3 Perfect Guard

float stroke(vec2 p,vec2 a,vec2 b,float width) {
 vec2 d=b-a;float h=clamp(dot(p-a,d)/max(.0001,dot(d,d)),0.0,1.0);
 return 1.0-smoothstep(width*1.55,width*1.55+.014,length(p-a-d*h));
}
float rim(vec2 p,float r,float w) {return 1.0-smoothstep(w*1.45,w*1.45+.014,abs(length(p)-r));}
float grammar(int f,vec2 p,float time,float damage) {
 float r=length(p),a=atan(p.y,p.x),s=0.0;
 if(f==0) { // open furnace lobes: contained heat, never a filled explosion
  float radius=.62+.035*sin(a*5.0-time*1.3)+.018*sin(a*9.0+time*.7);
  s=rim(p,radius,.018+.012*damage)*(.55+.3*sin(a*5.0+time));
  s+=rim(p,.51,.009)*smoothstep(-.1,.55,p.x)*.35;
 } else if(f==1) { // overlapping armor buttresses and compression joints
  float facet=max(abs(p.x)*.9+abs(p.y)*.35,abs(p.y));
  s=(1.0-smoothstep(.022,.043,abs(facet-.59)))*.85;
  for(int i=0;i<4;i++){float y=(float(i)-1.5)*.23;s+=stroke(p,vec2(.46-abs(y)*.2,y),vec2(.66-abs(y)*.2,y),.013)*.6;}
 } else if(f==2) { // stable routed current and branching electrical joints
  for(int i=0;i<6;i++){float q=float(i)*1.047;vec2 d=vec2(cos(q),sin(q));vec2 b=d*.58+vec2(-d.y,d.x)*.055;
   s+=stroke(p,d*.48,b,.009)+stroke(p,b,d*.7,.009);
   s+=stroke(p,b,b+vec2(d.y,-d.x)*.1,.006)*.65;}
  s+=rim(p,.57,.006)*.24;
 } else if(f==3) { // open aerodynamic curls, staggered pressure crescent
  for(int i=0;i<3;i++){float j=float(i);vec2 q=p+vec2(.1-j*.1,.03*sin(time*.6+j));s+=rim(q,.47+j*.1,.012)*smoothstep(-.4,.25,q.x)*(.6-j*.1);}
 } else if(f==4) { // formed crystal braces with frost lattice intersections
  for(int i=0;i<6;i++){float q=float(i)*1.047;vec2 d=vec2(cos(q),sin(q)),e=vec2(cos(q+1.047),sin(q+1.047));s+=stroke(p,d*.65,e*.65,.013)*.7;
   s+=stroke(p,d*.52,d*.7,.009)*.5;}
 } else if(f==5) { // complementary orbit planes, stable visible mass nodes
  s=rim(p*vec2(.8,1.25),.57,.012)*.6+rim(p*vec2(1.2,.82),.58,.009)*.4;
  for(int i=0;i<3;i++){float q=float(i)*2.094+time*.45;vec2 c=vec2(cos(q),sin(q))*.62;s+=exp(-dot(p-c,p-c)*1600.0)*.7;}
 } else if(f==6) { // separated phase surfaces, visible negative-space seams
  for(int i=0;i<3;i++){float x=(float(i)-1.0)*.18;s+=stroke(p,vec2(x-.25,-.58),vec2(x+.22,.56),.009)*.5;
   s+=stroke(p,vec2(x-.21,-.58),vec2(x+.26,.56),.004)*.2;}
  s*=smoothstep(.2,.45,r);
 } else if(f==7) { // subtraction folds inward; a coherent pale enclosing rim
  s=rim(p,.64,.014)*.6+rim(p,.49,.007)*.3;
  for(int i=0;i<5;i++){float q=float(i)*1.257;vec2 d=vec2(cos(q),sin(q));s+=stroke(p,d*.68,d*.53,.01)*.6;}
 } else { // outward ordered construction, aligned hard-light braces
  float h=max(abs(p.x)*.866+abs(p.y)*.5,abs(p.y));s=(1.0-smoothstep(.016,.035,abs(h-.59)))*.75;
  for(int i=0;i<6;i++){float q=float(i)*1.047;vec2 d=vec2(cos(q),sin(q));s+=stroke(p,d*.51,d*.7,.009)*.5;}
 }
 return s;
}
void fragment() {
 vec2 p=(UV-.5)*2.0;
 float t=clamp(phase,0.0,1.0),damage=clamp(strain,0.0,1.0);
 vec2 q=p;
 if(cue>1.5 && cue<2.5)q=p/(1.0+t*.42);
 float primary=grammar(family,q,clock_s,damage);
 // Durability changes structure: stable missing wedges and branching cracks.
 // There is no time-modulated warning flicker, including Reduced mode.
 float crack=0.0;
 for(int i=0;i<3;i++){
  float j=float(i),angle=j*2.14+.4+float(family)*.16;
  vec2 d=vec2(cos(angle),sin(angle)),side=vec2(-d.y,d.x);
  float enabled=step(j+.5,warning_tier);
  vec2 bend=d*.52+side*.055;
  crack+=(stroke(q,d*.38,bend,.009)+stroke(q,bend,d*.72,.007))*enabled;
 }
 float silhouette=primary*(.88+.10*damage)+crack*.48;
 vec3 ink=accent.rgb;
 if(cue>.5 && cue<1.5) {
  float attacker=grammar(secondary_family,p*.9,clock_s,0.0);
  silhouette+=attacker*.42;ink=mix(ink,secondary_accent.rgb,.28);
 }
 if(cue>1.5 && cue<2.5) {
  silhouette*=1.0-smoothstep(.1,.95,t);
  // Separate, finite fragment trajectories; no surviving guard core.
  for(int i=0;i<6;i++){float a=float(i)*1.047+float(family)*.11;vec2 d=vec2(cos(a),sin(a));float start=family==7?.72-t*.4:.55+t*.3;silhouette+=stroke(p,d*start,d*(start+.1),.01)*(1.0-t)*step(float(i),5.0*density)*.55;}
 } else if(cue>2.5) {
  silhouette+=rim(p,.42+t*.22,.015)*.6;
  silhouette*=pow(max(0.0,1.0-t),.8);
 } else if(cue>.5) silhouette*=pow(max(0.0,1.0-t),1.3);
 // The central character stays unobscured in every intensity mode.
 silhouette*=smoothstep(.24,.38,length(p));
 float alpha=clamp(silhouette*accent.a,0.0,.76);
 // Narrow pale edge improves separation from like-colored costumes. No fill,
 // extra particle, flash, screen input, camera or gameplay change.
 vec3 edge_ink=mix(ink,vec3(.94,.96,1.0),clamp(silhouette-.55,0.0,.22));
 COLOR=vec4(edge_ink,alpha);
}
