
PGraphics drawBuffer;
PGraphics screenBuffer;
PShader dither;

void setup(){
  
  fullScreen(P2D);
  noSmooth();
  ((PGraphicsOpenGL)g).textureSampling(3);
  
  int base = 320;
  int min = base;
  initAudio();
  while(min<width){
    min+=base;
    resizeAm+=1;
  }
  min-=base;
  drawBuffer = createGraphics(base,180,P2D);
  ((PGraphicsOpenGL)drawBuffer).textureSampling(3);
  screenBuffer = createGraphics(width,height,P2D);
  ((PGraphicsOpenGL)screenBuffer).textureSampling(3);
  screenBuffer.noSmooth();
  drawBuffer.noSmooth();
  JSONArray itemdata = parseJSONArray(fileToString("gamedata.json"));
  for(int i = 0;i<itemdata.size();i++){
    Screen scr = new Screen(itemdata.getJSONObject(i));
    screenList.add(scr);
    if(itemdata.getJSONObject(i).hasKey("start")){
      switchScreen(scr.id);
    }
  }
  
  dither = loadShader("dither.glsl");
  dither.init();
  
}

Sample activebgMusic;
Sample fadeInBgMusic;
float timeofswitch = 0;

void setBgMusic(String name){
  if(fadeInBgMusic!=null){
    fadeInBgMusic.player.kill();
  }
  if(activebgMusic==null){
    activebgMusic = playStereoSample(name,true,0.1);
    return;
  }
  fadeInBgMusic = playStereoSample(name,true,0.1);
  fadeInBgMusic.player.setPosition(activebgMusic.player.getPosition());
  timeofswitch = tick;
}


float offsetX,offsetY;

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
  
  if(activebgMusic!=null){
    if(fadeInBgMusic!=null){
      float crossfade = max(0,1-(tick-timeofswitch)*0.02);
      activebgMusic.gain.setGain(0.1*crossfade);
      fadeInBgMusic.gain.setGain(0.1*(1-crossfade));
      if(crossfade<=0){
        activebgMusic.player.kill();
        activebgMusic = fadeInBgMusic;
         fadeInBgMusic = null;
      }
    }
  
  }
  
  offsetX=width/2-resizeAm*(drawBuffer.width/2);offsetY=height/2-resizeAm*(drawBuffer.height/2);
  tick++;
  background(0);
  drawBuffer.beginDraw();
  drawBuffer.clear();
  
  current.draw();
  for(int i =0;i<inventory.size();i++){
    drawBuffer.image(inventory.get(i).inventorySprite,i*30,drawBuffer.height-25);
  }
  
  
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
  updateAudio();
  //translate(width/2,height/2);
  
}

ArrayList<Item> inventory = new ArrayList();
Item getItemInven(String id){
  for(Item i:inventory){
    if(i.id.equals(id)){
      return i;
    }
  }
  return null;
}  
HashMap<String,Item> itemArchive = new HashMap();


class Item{
  String id;
  PImage worldSprite;
  PImage inventorySprite;
  
  Item(JSONObject data){
    id = data.getString("id");
    worldSprite=loadImage(data.getString("spritename")+"WORLD.png");
    inventorySprite=loadImage(data.getString("spritename")+"INVEN.png");
  }
}

abstract class Interactable{
  boolean locked = false;
  boolean invislocked = false;
  String playonUnlock;
  String id;
  
  String usesItem;
  boolean consumesItem;
  boolean itemPermUnlock;
  String unlocks;
  abstract void onMousePress();
  void draw(){}
  void unlock(){
    locked=false; 
    if(playonUnlock!=null){
      playSample(playonUnlock,false,0.4);
    }
  }
  void onFrame(int frame){}
}

ArrayList<Screen> screenList = new ArrayList();
Screen current = null;

void switchScreen(String id){
  
  for(Screen s:screenList){
    
    if(s.id.equals(id)){
      current = s;
      if(s.bgmusic!=null)
      setBgMusic(s.bgmusic);
    }
  }
  
  
}

ArrayList<Interactable> allInteracts = new ArrayList();
Interactable getInteract(String id){
  println("getting",id);
  for(Interactable s:allInteracts){
    println("checking",s.id);
    if(s.id.equals(id)){
      return s;
    }
  }
  return null;
}

class Clicktrigger extends Interactable{
  int x,y,w,h;
  Clicktrigger(int x,int y,int w,int h){
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
  }
  void onMousePress(){
    boolean pass = false;
    if(isIn((mouseX-offsetX)/resizeAm,(mouseY-offsetY)/resizeAm,x,y,x+w,y+h)){
      if(usesItem!=null){
        Item use = getItemInven(usesItem);
        if(use==null){
          return;
        }
        if(consumesItem){
          inventory.remove(inventory.indexOf(use));
        }
        if(itemPermUnlock){
          locked = false;
        }
        pass = true;
      }
      if((!locked||pass)){
        getInteract(unlocks).unlock();
      }
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
    println(x,y,w,h);
    sid = screenid;
  }
  void onMousePress(){
    boolean pass = false;
    if(isIn((mouseX-offsetX)/resizeAm,(mouseY-offsetY)/resizeAm,x,y,x+w,y+h)){
      if(usesItem!=null){
        Item use = getItemInven(usesItem);
        if(use==null){
          return;
        }
        if(consumesItem){
          inventory.remove(inventory.indexOf(use));
        }
        if(itemPermUnlock){
          locked = false;
        }
        pass = true;
      }
      if((!locked||pass)){
        switchScreen(sid);
        if(unlocks!=null){
          getInteract(unlocks).unlock();
        }
      }
    }
  }
  

}
class FrameTrigger extends Interactable{
  int triggerframe ;
  boolean triggerOnce = true;
  boolean triggered = false;
  FrameTrigger (int frameToTrigger){
     triggerframe = frameToTrigger;
  }
  void onMousePress(){}
  @Override
  void onFrame(int frame){
    if(!locked&&triggerframe==frame){
      if(unlocks!=null&&(!triggerOnce||!triggered)){
        triggered = true;
        getInteract(unlocks).unlock();
      }
    }
  }
}
class ScreenSpriteChange extends Interactable{
  String sid;
  PImage[] newSprites;
  boolean loops;
  int animationspeed;
  ScreenSpriteChange (String screenid, String spritename, int frames, boolean loops,int animationspeed){
    sid = screenid;
    this.animationspeed = animationspeed;
    this.loops=loops;
    newSprites = new PImage[frames];
    for(int i=0;i<newSprites.length;i++){
      newSprites[i] = loadImage(spritename+i+".png");
      if(newSprites[i].height!=180){
        newSprites[i]=addBar(newSprites[i]);
      }
    }
  }
  void onMousePress(){}
  @Override
  void unlock(){
    super.unlock();
    for(Screen s:screenList){
      if(s.id.equals(sid)){
        s.animation = newSprites;
        s.loopAnimation=loops;
        s.frame=0;
        s.anispeed = animationspeed;
      }
    }
    if(unlocks!=null){
      getInteract(unlocks).unlock();
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
    boolean pass = false;
    if(usesItem!=null){
      Item use = getItemInven(usesItem);
      if(use==null){
        return;
      }
      if(consumesItem){
        inventory.remove(inventory.indexOf(use));
      }
      if(itemPermUnlock){
        locked = false;
      }
      pass = true;
    }
    if((!locked||pass)&&!collected&&isIn((mouseX-offsetX)/resizeAm,(mouseY-offsetY)/resizeAm,x,y,x+w,y+h)){
      
      println("wow");
      inventory.add(it);
      collected = true;
      if(unlocks!=null){
        getInteract(unlocks).unlock();
      }
    }
  }
  @Override
  void draw(){
    if(!collected){
     // drawBuffer.ellipse((mouseX-offsetX)/resizeAm,(mouseY-offsetY)/resizeAm,5,5);
      drawBuffer.image(it.worldSprite,x,y,w,h);
    }
  }

}


class Screen{
  PImage[] animation;
  String id;
  
  ArrayList<Interactable> interacts = new ArrayList();
  
  boolean loopAnimation = true;
  
  int anispeed = 50;
  PShader shader = null;
  JSONObject shaderdata;
  String bgmusic;
  
  Screen(JSONObject data){
    id = data.getString("id");
    animation = new PImage[data.getInt("frames")];
    for(int i=0;i<animation.length;i++){
      animation[i] = loadImage(data.getString("name")+i+".png");
    }
    loopAnimation = data.getBoolean("loop");
    if(data.hasKey("shader")){
      shaderdata = data.getJSONObject("shader");
      shader = loadShader(shaderdata.getString("name"));
      shader.init();
      
      
    }
    bgmusic = data.getString("bgmusic");
    JSONArray interacts = data.getJSONArray("interact");

    for(int i = 0;i<interacts.size();i++){
      JSONObject current = interacts.getJSONObject(i);
      Interactable in=null;
      switch(current.getString("type")){
        case "screen switch":
          ScreenSwitch sw = new ScreenSwitch(current .getInt("x"),current .getInt("y"),current .getInt("w"),current .getInt("h"),current .getString("screen id"));
          in = sw;
          
        break;
        case "item collect":
          String iid = current .getJSONObject("item").getString("id");
          if(!itemArchive.containsKey(iid )){
            itemArchive.put(iid ,new Item(current .getJSONObject("item")));
          }
          ItemCollect ic = new ItemCollect(current .getInt("x"),current .getInt("y"),current .getInt("w"),current .getInt("h"),iid );
          in = ic;
        break;
        case "change screen sprite":
          ScreenSpriteChange ssc = new ScreenSpriteChange(current.getString("screen id"),current .getString("spritename"),current.getInt("frames"),current.getBoolean("loops"),current.getInt("animation delay"));
          in = ssc;
        break;
        case "frame trigger":
          FrameTrigger ft = new FrameTrigger(current .getInt("frame"));
          in = ft;
          break;
        case "click trigger":
          Clicktrigger ct = new Clicktrigger(current .getInt("x"),current .getInt("y"),current .getInt("w"),current .getInt("h"));
          in = ct;
        break;
      }  
      in.id = current .getString("id");
      in.locked = current.hasKey("lock");
      in.unlocks = current.getString("unlocks trigger");
      in.usesItem = current.getString("needs item");
      
      if(current.hasKey("consumes item")){
        in.consumesItem = current.getBoolean("consumes item");
      }
      if(current.hasKey("item unlocks trigger")){
        in.itemPermUnlock = current.getBoolean("item unlocks trigger");
      }
      if(current.hasKey("invisible while locked")){
        in.invislocked = current.getBoolean("invisible while locked");
      }
      in.playonUnlock = current.getString("play on unlock");
      //invislocked 
      this.interacts.add(in);
      allInteracts.add(in);
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
  float atick = 0;
  int frame = 0;
  void draw(){
    if(tick>anispeed){
      tick=0;
      frame++;
    }
    tick++;
    atick++;
    if(shader!=null){
      println(tick);
      shader.set("tick",atick);
      shader.set("input1",shaderdata.getFloat("input1"));
      shader.set("input2",shaderdata.getFloat("input2"));
      shader.set("input3",shaderdata.getFloat("input3"));
      shader.set("input4",shaderdata.getFloat("input4"));
      shader.set("input5",shaderdata.getFloat("input5"));
      shader.set("input6",shaderdata.getFloat("input6"));
      drawBuffer.shader(shader);
    }
    drawBuffer.image(animation[(loopAnimation?frame:min(frame,animation.length-1))%animation.length],0,0);
    for(Interactable i:interacts){
      if(i.invislocked&&i.locked){
        continue;
      }
      i.onFrame(frame%animation.length);
      i.draw();
    }
    drawBuffer.resetShader();
  }
  
  
 
  
}

PImage addBar(PImage p){
  PGraphics pg = createGraphics(320,180);
  pg.beginDraw();
  pg.background(0);
  pg.image(p,0,26);
  pg.endDraw();
  return pg;
}

boolean isTouching(float qx,float qy,float qx2,float qy2,float gx,float gy,float gx2,float  gy2){
  return (!(gx2<=qx||gy2<=qy||gx>=qx2||gy>=qy2));
}
// point in box
boolean isIn(float qx,float qy,float gx,float gy,float gx2,float  gy2){
  return (!(gx2<qx||gy2<qy||gx>qx||gy>qy));
}
