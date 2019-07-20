
PGraphics drawBuffer;


int resizeAm = 0;
void setup(){
  
  fullScreen(P2D);
  int base = 320;
  int min = base;
  
  while(min<width){
    min+=base;
    resizeAm+=1;
  }
  min-=base;
  drawBuffer=  createGraphics(base,round(base/2.5),P2D);
  
  
}

void mousePressed(){
  current.onMouseClick();
}

void draw(){
  current.draw();
}


abstract class Interactable{
  abstract void onMousePress();
}

ArrayList<Screen> screenList = new ArrayList();
Screen current = null;

void switchScreen(String id){
  for(Screen s:screenList){
    if(s.id.equals(id)){
      current = s;
    }
  }
}

class ScreenSwitch extends Interactable{
  int x,y,w,h;
  String sid;
  ScreenSwitch(int x,int y,int w,int h,String screenid){
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    sid = screenid;
  }
  void onMousePress(){
    if(isIn(mouseX,mouseY,x,y,x+w,y+h)){
      switchScreen(sid);
    }
  }

}




class Screen{
  PImage[] animation;
  String id;
  
  ArrayList<Interactable> interacts = new ArrayList();
  
  boolean loopAnimation = true;
  
  Screen(JSONObject data){
    animation = new PImage[data.getInt("frames")];
    for(int i=0;i<animation.length;i++){
      animation[i] = loadImage(data.getString("name")+i+".png");
    }
    loopAnimation = data.getBoolean("loop");
    
    JSONArray interacts = data.getJSONArray("interact");
    for(int i = 0;i<interacts.size();i++){
      JSONObject current = interacts.getJSONObject(i);
      switch(current.getString("type")){
        case "screen switch":
          ScreenSwitch sw = new ScreenSwitch(data.getInt("x"),data.getInt("y"),data.getInt("w"),data.getInt("h"),data.getString("screen id"));
          this.interacts.add(sw);
        break;
      }
    }
  }
  
  Screen(String file, int amount){
    animation = new PImage[amount];
    for(int i=0;i<amount;i++){
      animation[i] = loadImage(file+i+".png");
    }
  }
  
  void onMouseClick(){
    for(Interactable i:interacts){
      i.onMousePress();
    }
  }
  
  
  int tick = 0;
  int frame = 0;
  void draw(){
    if(tick>50){
      tick=0;
      frame++;
    }
    tick++;
    
    drawBuffer.image(animation[(loopAnimation?frame:max(frame,animation.length-1))%animation.length],0,0);
  
  }
  
  
 
  
}

boolean isTouching(float qx,float qy,float qx2,float qy2,float gx,float gy,float gx2,float  gy2){
  return (!(gx2<=qx||gy2<=qy||gx>=qx2||gy>=qy2));
}
// point in box
boolean isIn(float qx,float qy,float gx,float gy,float gx2,float  gy2){
  return (!(gx2<qx||gy2<qy||gx>qx||gy>qy));
}
