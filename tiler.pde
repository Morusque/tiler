
import drop.*;
import test.*;

import processing.video.*;

SDrop drop;

PImage loadedPic;
PImage origPic;
PImage finalPic;

ArrayList<Tile> tiPool = new ArrayList<Tile>();

int currentImPoolIndex = 0;
int currentTiPoolIndex = 0;

float borderSize;

ArrayList<UIElement> uIElements = new ArrayList<UIElement>();

float[] hDivs, vDivs;

boolean shiftPressed = false;
boolean ctrlPressed = false;
boolean tabPressed = false;

int tileCutIntoX = 16;
int tileCutIntoY = 16;

int tileResultIntoX = 16;
int tileResultIntoY = 16;

int tileSubdivisions = 8;

float finalBorderSize = 0;

float seeCuts = 2;
PImage cutsPic;

PImage resultCutsPic;

int nbResultsSaved = 0;

boolean isCurrentlyProcessing = false;
boolean isPendingProcess = false;

int onlyUseTilesOnce = 0;

Capture video;

PApplet mainSketch;

void setup() {
  size(1500, 900);
  drop = new SDrop(this);
  mainSketch = this;
  hDivs = divideLength((float)width, new float[]{2, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 5});
  vDivs = divideLength((float)height, new float[]{2, 5, 5, 5, 30, 30, 5});
  uIElements.add(new UIElementValue("divide x", hDivs[2], vDivs[1], tileCutIntoX, 1, new Action() {
    public void trigger(Object o) {
      ((UIElementValue)o).value=max(((UIElementValue)o).value, 1);
      tileCutIntoX = floor(((UIElementValue)o).value);
      if (ctrlPressed && loadedPic!=null) {
        tileCutIntoY = round(tileCutIntoX*(float)loadedPic.height/(float)loadedPic.width);
        ((UIElementValue)getUIElement("divide y")).value = tileCutIntoY;
        computeCutsPic();
      }
      computeCutsPic();
    }
  }
  ));
  uIElements.add(new UIElementValue("divide y", hDivs[2], vDivs[2], tileCutIntoY, 1, new Action() {
    public void trigger(Object o) {
      ((UIElementValue)o).value=max(((UIElementValue)o).value, 1);
      tileCutIntoY = floor(((UIElementValue)o).value);
      if (ctrlPressed && loadedPic!=null) {
        tileCutIntoX = round(tileCutIntoY*(float)loadedPic.width/(float)loadedPic.height);
        ((UIElementValue)getUIElement("divide x")).value = tileCutIntoX;
        computeCutsPic();
      }
      computeCutsPic();
    }
  }
  ));
  uIElements.add(new UIElementValue("see cuts", hDivs[3], vDivs[1], seeCuts, 1, new Action() {
    public void trigger(Object o) {
      seeCuts = ((UIElementValue)o).value;
      computeCutsPic();
      computeResultCutsPic();
    }
  }
  ));
  uIElements.add(new UIElementValue("borders size", hDivs[8], vDivs[2], 0, 1, new Action() {
    public void trigger(Object o) {
      ((UIElementValue)o).value = finalBorderSize = max(((UIElementValue)o).value, 0);
      thread("process");
    }
  }
  ));
  uIElements.add(new UIElement("process", hDivs[10], vDivs[1], new Action() {
    public void trigger(Object o) {
      process();
    }
  }
  ));
  uIElements.add(new UIElement("export", hDivs[10], vDivs[2], new Action() {
    public void trigger(Object o) {
      File file = null;
      do {
        file = new File(sketchPath("results/result"+nf(nbResultsSaved, 4)+".png"));
        if (file.exists()) nbResultsSaved++;
      } while (file.exists());
      if (finalPic!=null) finalPic.save("results/result"+nf(nbResultsSaved++, 4)+".png");
    }
  }
  ));
  uIElements.add(new UIElement("load goal", hDivs[8], vDivs[1], new Action() {
    public void trigger(Object o) {
      if (loadedPic!=null) origPic = loadedPic;
      computeResultCutsPic();
      process();
    }
  }
  ));
  uIElements.add(new UIElement("load from cam", hDivs[3], vDivs[2], new Action() {
    public void trigger(Object o) {
      if (video==null) {
        video = new Capture(mainSketch);
        video.start();
      }
      while (!video.available()) {
        delay(1);
      }
      video.read();
      loadedPic = video.get();
      loadedPic.save(dataPath("pool/cam/camPic.png"));
      computeCutsPic();
    }
  }
  ));  
  uIElements.add(new UIElementValue("tile size x", hDivs[9], vDivs[1], tileResultIntoX, 1, new Action() {
    public void trigger(Object o) {
      ((UIElementValue)o).value=max(((UIElementValue)o).value, 1);
      tileResultIntoX = floor(((UIElementValue)o).value);
      if (ctrlPressed && origPic!=null) {
        tileResultIntoY = round(tileResultIntoX*(float)origPic.height/(float)origPic.width);
        ((UIElementValue)getUIElement("tile size y")).value = tileResultIntoY;
      }
      computeResultCutsPic();
      thread("process");
    }
  }
  ));
  uIElements.add(new UIElementValue("tile size y", hDivs[9], vDivs[2], tileResultIntoY, 1, new Action() {
    public void trigger(Object o) {
      ((UIElementValue)o).value=max(((UIElementValue)o).value, 1);
      tileResultIntoY = floor(((UIElementValue)o).value);
      if (ctrlPressed && origPic!=null) {
        tileResultIntoX = round(tileResultIntoY*(float)origPic.width/(float)origPic.height);
        ((UIElementValue)getUIElement("tile size x")).value = tileResultIntoX;
      }
      computeResultCutsPic();
      thread("process");
    }
  }
  ));
  uIElements.add(new UIElementValue("tile subdiv", hDivs[7], vDivs[1], tileSubdivisions, 1, new Action() {
    public void trigger(Object o) {
      ((UIElementValue)o).value=floor(max(((UIElementValue)o).value, 1));
      tileSubdivisions = floor(((UIElementValue)o).value);
      for (Tile ti : tiPool) ti.computeAverages();
      thread("process");
    }
  }
  ));
  uIElements.add(new UIElementValue("once only", hDivs[7], vDivs[2], onlyUseTilesOnce, 1, new Action() {
    public void trigger(Object o) {
      onlyUseTilesOnce = (onlyUseTilesOnce+1)%2;
      ((UIElementValue)o).value = onlyUseTilesOnce;
      thread("process");
    }
  }
  ));
  uIElements.add(new UIElement("clear tile pool", hDivs[6], vDivs[1], new Action() {
    public void trigger(Object o) {
      tiPool.clear();
    }
  }
  ));
  uIElements.add(new UIElement("add tiles", hDivs[6], vDivs[2], new Action() {
    public void trigger(Object o) {
      thread("addTiles");
    }
  }
  ));
}

void draw() {
  if (isPendingProcess) {
    thread("process");
    isPendingProcess = false;
  }
  if (!isCurrentlyProcessing) {
    background(0xFF);
    // draw loaded image
    if (loadedPic!=null) imageFit(loadedPic, hDivs[2]+2, vDivs[4]+2, hDivs[5]-hDivs[2]-4, vDivs[6]-vDivs[4]-4, null);
    if (cutsPic!=null)   imageFit(cutsPic, hDivs[2]+2, vDivs[4]+2, hDivs[5]-hDivs[2]-4, vDivs[6]-vDivs[4]-4, null);
    // draw original
    if (origPic!=null)       imageFit(origPic, hDivs[8]+2, vDivs[4]+2, hDivs[8]-hDivs[5]-4, vDivs[5]-vDivs[4]-4, null);
    if (resultCutsPic!=null) imageFit(resultCutsPic, hDivs[8]+2, vDivs[4]+2, hDivs[8]-hDivs[5]-4, vDivs[5]-vDivs[4]-4, null);
    // draw final
    if (finalPic!=null)  imageFit(finalPic, hDivs[8]+2, vDivs[5]+2, hDivs[8]-hDivs[5]-4, vDivs[6]-vDivs[5]-4, null);
    // draw tiles pool
    if (tiPool.size()>0) {
      float tileSizeX = tiPool.get(0).im.width;
      float tileSizeY = tiPool.get(0).im.height;
      if (origPic!=null) {
        tileSizeX = (float)origPic.width/tileResultIntoX;
        tileSizeY = (float)origPic.height/tileResultIntoY;
      }
      float areaToFill = (hDivs[7]-hDivs[5])*(vDivs[6]-vDivs[4]-50);
      float scaleToFit = sqrt((areaToFill)/((tiPool.size()*(tileSizeX+1)*(tileSizeY+1))));   
      tileSizeX*=scaleToFit;
      tileSizeY*=scaleToFit;
      float currentDrawX = hDivs[5];
      float currentDrawY = vDivs[4];
      for (int i=0; i<tiPool.size(); i++) {
        image(tiPool.get(i).im, currentDrawX, currentDrawY, tileSizeX, tileSizeY);
        currentDrawX+=tileSizeX+1;
        if (currentDrawX>=hDivs[7]) {
          currentDrawX=hDivs[5];
          currentDrawY+=tileSizeY+1;
        }
      }
    }
    // draw ui elements
    for (UIElement uIE : uIElements) uIE.draw();
    if (tabPressed) {
      if (finalPic!=null) {
        background(0xFF);
        imageFit(finalPic, 0, 0, width, height, null);
      }
    }
  }
}

float[] divideLength(float l, float[] ds) {
  float[] fs = new float[ds.length];
  float t = 0;
  for (float d : ds) t+=d;
  float cV = 0;
  for (int i=0; i<fs.length; i++) {
    fs[i] = l*cV/t;
    cV+=ds[i];
  }
  return fs;
}

class Tile {
  PImage im;
  color[][] avgC;
  Tile(PImage im) {
    this.im=im;
    computeAverages();
  }
  void computeAverages() {
    avgC = new color[tileSubdivisions][tileSubdivisions];
    for (int x=0; x<tileSubdivisions; x++) {
      for (int y=0; y<tileSubdivisions; y++) {
        color thisColor = color(0);
        int nbAdded = 0;
        for (int x2 = floor((float)im.width*x/tileSubdivisions); x2 < floor((float)im.width*(x+1)/tileSubdivisions); x2++) {
          for (int y2 = floor((float)im.height*y/tileSubdivisions); y2 < floor((float)im.height*(y+1)/tileSubdivisions); y2++) {
            thisColor = lerpColor(im.get(x2, y2), thisColor, nbAdded==0?0:1.0f/(float)nbAdded);
            nbAdded++;
          }
        }
        avgC[x][y] = thisColor;
      }
    }
  }
}

class UIElement {
  String label = "";
  String name = "";
  PVector pos;
  PVector size = new PVector(125, 30);
  Action a;

  UIElement (String label, float x, float y, Action a) {
    this.label=label;
    this.name=label;
    this.pos = new PVector(x, y);
    this.a = a;
  }

  void draw() {
    stroke(0);
    noFill();
    rect(pos.x, pos.y, size.x, size.y);
    fill(0);
    textSize(12);
    text(label, pos.x+10, pos.y+20);
  }

  void clic(int x, int y) {
    if (x>=pos.x) {
      if (y>=pos.y) {
        if (x<=pos.x+size.x) {
          if (y<=pos.y+size.y) {
            typeTrigger();
            a.trigger(this);
          }
        }
      }
    }
  }

  void typeTrigger() {
  }
}

class UIElementValue extends UIElement {
  float value;
  float step;

  UIElementValue(String label, float x, float y, float value, float step, Action a) {
    super(label, x, y, a);
    this.value = value;
    this.step = step;
  }

  void draw() {
    stroke(0);
    noFill();
    rect(pos.x, pos.y, size.x, size.y);
    fill(0);
    textSize(12);
    text(label+" "+floor(value), pos.x+10, pos.y+20);
  }

  void typeTrigger() {
    if (mouseButton==RIGHT) value -= step * (shiftPressed?10:1);
    if (mouseButton==LEFT) value += step * (shiftPressed?10:1);
  }
}

interface Action {
  public void trigger(Object o);
}

UIElement getUIElement(String s) {
  for (UIElement b : uIElements) if (b.name.equals(s)) return b;
  return null;
}

void mousePressed() {
  for (UIElement uIE : uIElements) uIE.clic(mouseX, mouseY);
}

void keyPressed() {
  if (keyCode == SHIFT) shiftPressed = true;
  if (keyCode == CONTROL) ctrlPressed = true;
  if (keyCode == TAB) tabPressed = true;
}

void keyReleased() {
  if (keyCode == SHIFT) shiftPressed = false;
  if (keyCode == CONTROL) ctrlPressed = false;
  if (keyCode == TAB) tabPressed = false;
}

void imageFit(PImage im, float x, float y, float w, float h, PGraphics gr) {
  float xScale = w/(float)im.width;
  float yScale = h/(float)im.height;
  float finalScale = min(xScale, yScale);
  float finalSizeX = im.width*finalScale;
  float finalSizeY = im.height*finalScale;
  float internalPosX = (w-finalSizeX)/2;
  float internalPosY = (h-finalSizeY)/2;
  if (gr!=null) gr.image(im, x+internalPosX, y+internalPosY, finalSizeX, finalSizeY);
  else image(im, x+internalPosX, y+internalPosY, finalSizeX, finalSizeY);
}

void computeCutsPic() {
  if (seeCuts<=0) cutsPic = null;
  else {
    if (loadedPic!=null) {
      float scaledSeeCuts = seeCuts * max(loadedPic.width/(hDivs[5]-hDivs[2]-4), loadedPic.height/(vDivs[6]-vDivs[4]-4)); 
      PGraphics temp = createGraphics(loadedPic.width, loadedPic.height, JAVA2D);
      temp.beginDraw();
      temp.stroke(0);
      temp.strokeWeight(scaledSeeCuts);
      for (float x=0; x<tileCutIntoX; x++) temp.line((float)temp.width* x/tileCutIntoX, 0, (float)temp.width*x/tileCutIntoX, temp.height);
      for (float y=0; y<tileCutIntoY; y++) temp.line(0, (float)temp.height*y/tileCutIntoY, temp.width, (float)temp.height*y/tileCutIntoY);
      temp.endDraw();
      cutsPic = temp.get();
    }
  }
}

void computeResultCutsPic() {
  if (origPic!=null) {
    float scaledSeeCuts = seeCuts * max(origPic.width/(hDivs[8]-hDivs[5]-4), origPic.height/(vDivs[5]-vDivs[4]-4));
    PGraphics temp = createGraphics(origPic.width, origPic.height, JAVA2D);
    temp.beginDraw();
    temp.stroke(0);
    temp.strokeWeight(scaledSeeCuts);
    for (float x=0; x<tileResultIntoX; x++) temp.line((float)temp.width* x/tileResultIntoX, 0, (float)temp.width*x/tileResultIntoX, temp.height);
    for (float y=0; y<tileResultIntoY; y++) temp.line(0, (float)temp.height*y/tileResultIntoY, temp.width, (float)temp.height*y/tileResultIntoY);
    temp.endDraw();
    resultCutsPic = temp.get();
  }
}

void addTiles() {
  computeCutsPic();
  if (loadedPic==null) return;
  for (float y=0; y<tileCutIntoY; y++) {
    for (float x=0; x<tileCutIntoX; x++) {
      PImage thisTilePic = loadedPic.get(floor((float)x*loadedPic.width/tileCutIntoX), floor((float)y*loadedPic.height/tileCutIntoY), floor(loadedPic.width/tileCutIntoX), floor(loadedPic.height/tileCutIntoY));
      tiPool.add(new Tile(thisTilePic));
    }
  }
  process();
}

void process() {

  int tileResultIntoXTmp = tileResultIntoX;
  int tileResultIntoYTmp = tileResultIntoY;
  int tileSubdivisionsTmp = tileSubdivisions;

  if (isCurrentlyProcessing) {
    isPendingProcess = true;
    return;
  }

  if (tiPool.size()==0||origPic==null) return;

  isCurrentlyProcessing = true;

  Tile[][] resultMap = new Tile[tileResultIntoXTmp][tileResultIntoYTmp];  

  boolean[] used = new boolean[tiPool.size()];
  for (int i=0; i<used.length; i++) used[i]=false;

  for (int x=0; x<tileResultIntoXTmp; x++) {
    for (int y=0; y<tileResultIntoYTmp; y++) {
      
      int nbUnused = 0;
      for (int i=0; i<used.length; i++) if (!used[i]) nbUnused++;
      if (nbUnused==0) for (int i=0; i<used.length; i++) used[i]=false;
      
      PImage goal = origPic.get(floor((float)x*origPic.width/tileResultIntoXTmp), floor((float)y*origPic.height/tileResultIntoYTmp), floor((float)origPic.width/tileResultIntoXTmp), floor((float)origPic.height/tileResultIntoYTmp));

      color[][] thisAvgC = new color[tileSubdivisionsTmp][tileSubdivisionsTmp];
      for (int x3=0; x3<tileSubdivisionsTmp; x3++) {
        for (int y3=0; y3<tileSubdivisionsTmp; y3++) {
          color thisColor = color(0);
          int nbAdded = 0;
          for (int x2 = floor((float)goal.width*x3/tileSubdivisionsTmp); x2 < floor((float)goal.width*(x3+1)/tileSubdivisionsTmp); x2++) {
            for (int y2 = floor((float)goal.height*y3/tileSubdivisionsTmp); y2 < floor((float)goal.height*(y3+1)/tileSubdivisionsTmp); y2++) {
              thisColor = lerpColor(goal.get(x2, y2), thisColor, nbAdded==0?0:1.0f/(float)nbAdded);
              nbAdded++;
            }
          }
          thisAvgC[x3][y3] = thisColor;
        }
      }

      float bestScore = -1;
      Tile bestTile = null;
      int bestTileIndex = -1;
      for (int i=0; i<tiPool.size(); i++) {
        float thisScore = computeScore(thisAvgC, tiPool.get(i).avgC);
        if (thisScore!=-1) {
          if (bestScore==-1 || thisScore<bestScore) {
            if (used[i]==false||onlyUseTilesOnce==0) {
              bestScore=thisScore;
              bestTile = tiPool.get(i);
              bestTileIndex=i;
            }
          }
        }
      }

      if (bestTileIndex!=-1) used[bestTileIndex]=true;

      resultMap[x][y] = bestTile;
    }
  }

  PGraphics result = createGraphics(origPic.width, origPic.height, JAVA2D);
  result.beginDraw();
  PVector tSize = new PVector(floor(result.width/tileResultIntoXTmp), floor(result.height/tileResultIntoYTmp));
  for (int x=0; x<tileResultIntoXTmp; x++) {
    for (int y=0; y<tileResultIntoYTmp; y++) {
      if (resultMap[x][y]!=null) {
        result.image(resultMap[x][y].im, tSize.x*x, tSize.y*y, tSize.x, tSize.y);
        if (finalBorderSize>0) {
          result.noFill();
          result.stroke(0);
          result.strokeWeight(finalBorderSize);
          result.rect(tSize.x*x, tSize.y*y, tSize.x, tSize.y);
        }
      }
    }
  }
  result.endDraw();
  finalPic = result.get();

  isCurrentlyProcessing = false;
}

float computeScore(color[][]a, color[][] b) {
  if (a.length==0||b.length==0) return -1;
  if (a.length!=b.length||a[0].length!=b[0].length) return -1;
  float result = 0;
  for (int x=0; x<a.length; x++) {
    for (int y=0; y<a[x].length; y++) {
      result += sqrt(pow(red(a[x][y])-red(b[x][y]), 2)+pow(green(a[x][y])-green(b[x][y]), 2)+pow(blue(a[x][y])-blue(b[x][y]), 2));
    }
  }
  return result;
}

void dropEvent(DropEvent theDropEvent) {
  try {
    loadedPic = loadImage(theDropEvent.file().getAbsolutePath());
    computeCutsPic();
  } 
  catch(Exception e) {
    println(e);
  }
}
