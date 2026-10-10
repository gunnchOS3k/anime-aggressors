shader_type canvas_item;
render_mode unshaded;
// Original analytic distance fields. No image, sample, imported shader or screen capture.
uniform int family = 0;
uniform int kind = 0;
uniform float phase = 0.0;
uniform float clock_s = 0.0;
uniform float seed = 0.0;
uniform float density = 1.0;
uniform float flash = 1.0;
uniform vec4 accent : source_color = vec4(1.0, 0.3, 0.05, 1.0);
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+seed)*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float line(vec2 p, vec2 a, vec2 b, float w) {
 vec2 ab=b-a; float h=clamp(dot(p-a,ab)/max(dot(ab,ab),0.0001),0.0,1.0);
 return 1.0-smoothstep(w,w+0.018,length(p-a-ab*h));
}
float ring(vec2 p,float r,float w) { return 1.0-smoothstep(w,w+0.018,abs(length(p)-r)); }
void fragment() {
 vec2 p=(UV-0.5)*2.0; float r=length(p), a=atan(p.y,p.x);
 float n=noise(p*6.0+vec2(-clock_s*2.0,clock_s));
 float t=phase; float f=pow(max(0.0,1.0-t),1.5);
 float core=exp(-r*r*100.0)*max(0.0,1.0-t*4.0)*flash;
 float shape=0.0; float bits=0.0;
 // Nine different motion and distance-field grammars, not nine recolored discs.
 if (family==0) { // combustion: turbulent advancing tongues and pressure corona
  float edge=0.36+0.20*n+0.13*sin(a*5.0-clock_s*4.0);
  shape=(1.0-smoothstep(edge,edge+0.07,r))*smoothstep(-0.7,0.6,p.x)*0.72;
  shape+=ring(p,0.22+t*0.55+n*0.07,0.035)*0.48;
 } else if (family==1) { // armor/earth: angular compression, moving fracture planes
  float facet=max(abs(p.x)*0.82+abs(p.y)*0.56,abs(p.y));
  shape=(1.0-smoothstep(0.028,0.05,abs(facet-(0.26+t*0.5))))*0.7;
  for(int i=0;i<5;i++) { float q=float(i)*1.256+seed; vec2 d=vec2(cos(q),sin(q)); shape+=line(p,d*0.16,d*(0.42+t*0.4),0.013)*0.7; }
 } else if (family==2) { // electricity: seeded branching, moving irregular arcs
  for(int i=0;i<6;i++) { float q=float(i)*1.047+seed*0.13; vec2 d=vec2(cos(q),sin(q)); vec2 side=vec2(-d.y,d.x);
   vec2 last=vec2(0.0); for(int j=1;j<5;j++) { float k=float(j); vec2 next=d*(k*0.16)+side*(hash(vec2(float(i),k+floor(clock_s*(2.0+10.0*flash))))-0.5)*0.25;
    shape+=line(p,last,next,0.008)*0.85; if(j==3) shape+=line(p,next,next+side*0.18+d*0.1,0.006)*0.7; last=next; }
  }
 } else if (family==3) { // wind: sweeping nested crescents, open negative space
  for(int i=0;i<3;i++) { vec2 q=p+vec2(0.18-float(i)*0.16,0.0); shape+=ring(q,0.3+float(i)*0.16+t*0.18,0.015+0.008*float(i))*smoothstep(-0.25,0.4,q.x)*0.8; }
 } else if (family==4) { // ice: six faceted lances with abrupt formation
  for(int i=0;i<6;i++) { float q=float(i)*1.047; vec2 d=vec2(cos(q),sin(q)); float x=dot(p,d), y=abs(dot(p,vec2(-d.y,d.x)));
   shape+= (1.0-smoothstep(0.012,0.025,abs(y-max(0.0,0.62-x)*0.09)))*step(0.16,x)*step(x,0.64)*0.8;
  } shape+=ring(p,0.2,0.012)*0.5;
 } else if (family==5) { // gravity: elliptical orbit, inward moving satellite nodes
  shape=ring(p*vec2(0.75,1.3),0.42+t*0.1,0.019)*0.85;
  for(int i=0;i<4;i++) { float q=float(i)*1.57+clock_s*2.0; vec2 c=vec2(cos(q),sin(q))*max(0.14,0.62-t*0.4); shape+=exp(-dot(p-c,p-c)*480.0); }
 } else if (family==6) { // phase: dislocated seams, intermittent separated echoes
  for(int i=0;i<3;i++) { float x=float(i)*0.17-0.18+sin(clock_s*3.0)*0.06; shape+=line(p,vec2(x-0.2,-0.6),vec2(x+0.2,0.6),0.012)*(0.85-float(i)*0.2); }
  shape*=smoothstep(0.25,0.65,n);
 } else if (family==7) { // Yin: collapsing aperture and inward subtraction
  shape=ring(p,0.65-t*0.45,0.022)*0.8;
  for(int i=0;i<5;i++) { float q=float(i)*1.256+clock_s; vec2 d=vec2(cos(q),sin(q)); shape+=line(p,d*(0.7-t*0.48),d*(0.55-t*0.4),0.012)*0.7; }
  core=0.0;
 } else { // Yang: expanding structured hexagonal construction
  float hex=max(abs(p.x)*0.866+abs(p.y)*0.5,abs(p.y)); shape=(1.0-smoothstep(0.015,0.032,abs(hex-(0.3+t*0.25))))*0.8;
  for(int i=0;i<6;i++) { float q=float(i)*1.047; vec2 d=vec2(cos(q),sin(q)); shape+=line(p,d*0.16,d*(0.5+t*0.2),0.012)*0.75; }
 }
 // Directional slash/contact pressure; clears in under 0.3 s.
 float crescent=ring(p+vec2(0.35,0),0.5+t*0.12,0.023)*smoothstep(-0.1,0.5,p.x);
 if(kind==0 || kind==9) { shape+=crescent; }
 // Secondary motes within the same bounded mesh, seeded and density controlled.
 for(int i=0;i<10;i++) { float j=float(i); float q=hash(vec2(j,3))*6.283; vec2 d=vec2(cos(q),sin(q)); vec2 c=d*(0.22+t*(0.35+hash(vec2(j,8))*0.3));
  bits+=exp(-dot(p-c,p-c)*1400.0)*step(j,9.0*density)*0.7;
 }
 if(kind==1) { // defensive crescent, no body-contact bloom or explosion
  core=0.0; shape=shape*0.15+ring(p*vec2(1.0,0.8),0.35+t*0.28,0.027)*(0.4+0.6*smoothstep(-0.3,0.3,p.x)); bits*=0.25;
 } else if(kind==10) { core=0.0; shape*=0.65; bits*=0.2; } else if(kind==2) { // charge evolves continuously; no contact arc
  core=0.0; shape*=0.65; bits*=0.3; f=1.0;
 } else if(kind==3) { core=exp(-r*r*65.0)*0.6*flash; shape*=0.75; f=1.0; }
 else if(kind==4) { // irregular volumetric-looking smoke wisps, never straight launch lines
  float cloud=(1.0-smoothstep(0.26+noise(p*4.0+clock_s)*0.3,0.75,r)); shape=cloud*(0.18+0.28*n); bits=0.0; core=0.0;
 } else if(kind==5) { core=0.0; shape*=0.5; bits*=0.7; }
 else if(kind==6) { shape=crescent*0.55; core=0.0; bits=0.0; }
 else if(kind==7) { shape+=ring(p,0.2+t*0.7,0.025); core*=0.5; }
 else if(kind==8) { shape*=0.45; core=0.0; bits=0.0; }
 float alpha=clamp((shape*f+bits*f+core)*accent.a,0.0,0.88);
 vec3 ink=mix(accent.rgb,vec3(1.0,0.97,0.88),clamp(core,0.0,1.0)*0.8);
 COLOR=vec4(ink,alpha);
}
