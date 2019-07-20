
PGraphics drawBuffer;
PGraphics screenBuffer;
PShader dither;

void setup(){
  
  fullScreen(P2D);
  noSmooth();
  ((PGraphicsOpenGL)g).textureSampling(3);
  
  int base = 320;
  int min = base;
  
  while(min<width){
    min+=base;
    resizeAm+=1;
  }
  min-=base;
  drawBuffer = createGraphics(base,180);
  screenBuffer = createGraphics(width,height,P2D);
  ((PGraphicsOpenGL)screenBuffer).textureSampling(3);
  screenBuffer.noSmooth();
  JSONArray itemdata = parseJSONArray(fileToString("gamedata.json"));
  for(int i = 0;i<itemdata.size();i++){
    Screen scr = new Screen(itemdata.getJSONObject(i));
    screenList.add(scr);
    if(itemdata.getJSONObject(i).hasKey("start")){
      current=scr;
    }
  }
  
  dither = loadShader("dither.glsl");
  dither.init();
  
  
  
  
  
}
int resizeAm = 0;

String fileToString(String file){
  BufferedReader br = createReader(file);
  String out="";
  try{
    String p="";
    
    while((p=br.readLine())!=null){
      out+=p+"\n";
    }
    out=out.substring(0,out.length()-1);
  }catch(Exception e){}
  
  return out;

}

void mousePressed(){
  current.onMouseClick();
}

float tick=0;
void draw(){
  tick++;
  background(0);
  drawBuffer.beginDraw();
  drawBuffer.background(0);
  
  current.draw();
  drawBuffer.endDraw();
  
  screenBuffer.beginDraw();
  screenBuffer.background(0);
  dither.set("color",200/255f,191/255f,231/255f);
  dither.set("colormid",163/255f,73/255f,164/255f);
  dither.set("colordark",0.1,0.1,0.1);
  dither.set("ditheroffset",tick*0.05);
  dither.set("bayer",new float[]{0,    8*16, 2*16, 10*16,
                12*16,4*16, 14*16, 6*16,
                3*16 ,11*16,1*16 , 9*16,
                15*16,7*16, 13*16, 5*16});
  screenBuffer.shader(dither);
  screenBuffer.image(drawBuffer,width/2-resizeAm*(drawBuffer.width/2),height/2-resizeAm*(drawBuffer.height/2),resizeAm*drawBuffer.width,resizeAm*drawBuffer.height);
  screenBuffer.endDraw();
  
  
  image(screenBuffer,0,0);
  //translate(width/2,height/2);
  
}


HashMap<String,Item> itemArchive = new HashMap();


class Item{
  String id;
  PImage worldSprite;
  PImage inventorySprite;
  
  Item(JSONObject data){
    id = data.getString("id");
  }
}

abstract class Interactable{
  abstract void onMousePress();
  void draw(){}
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

class ItemCollect extends Interactable{
  int x,y,w,h;
  Item it;
  boolean collected = false;
  ItemCollect(int x,int y,int w,int h,String itemid){
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    it = itemArchive.get(itemid);
  }
  void onMousePress(){
    if(isIn(mouseX,mouseY,x,y,x+w,y+h)){
      
    }
  }
  @Override
  void draw(){
    if(!collected){
      
    }
  }

}


class Screen{
  PImage[] animation;
  String id;
  
  ArrayList<Interactable> interacts = new ArrayList();
  
  boolean loopAnimation = true;
  
  Screen(JSONObject data){
    id = data.getString("id");
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
          ScreenSwitch sw = new ScreenSwitch(current .getInt("x"),current .getInt("y"),current .getInt("w"),current .getInt("h"),current .getString("screen id"));
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
