
/*******************
Author:
Etienne Richan
12/07/2015

This tool simulates the slitscan effect by delaying pixels in a video a certain amount of frames depending on the darknes of a reference gradient image.

Usage:
1. Specify a video file path. 
  ***IMPORTANT*** : Videos must be located in the project's 'data' folder. 
  Video must be .mov type (only version tested, maybe other quicktime compatible types are supported)
2. Check video details and set the width and height.
3. (Optional) Set max delay. This can be changed while hte program is running.


Modes (GRADIENT recommended):
  GRADIENT : Uses the pixels of a gradient to apply the effect
  SLITS : Only in the up direction, might run a bit faster than gradient mode. 


Key controls:
Gradient controls:
  w: up gradient
  a: left gradient
  s: right gradient
  d: down gradient

Delay controls:
  Increased max delay means that the gradient is interpreted with a higher resolution, 
  but also means more time delay between the top and the bottom of the video. 

  = : Increase max_delay by 1
  - : Decrease max_delay by 1
  SHIFT & = : Increase max_delay by 10
  SHIFT & - : Decrease max_delay by 10



*******************/

import processing.video.*;
import java.util.concurrent.*;

static int GRADIENT = 0;
static int SLITS = 1;

int DELAY_MODE = GRADIENT;
String VIDEO_PATH = "cheetah.mov";
int VIDEO_WIDTH = 640;
int VIDEO_HEIGHT = 360;
int MAX_DELAY = 30;



Movie src_video;
PImage src_image;
PImage result_image;
ArrayList<PImage> source_array;

Semaphore lock;
boolean first_image = true;
Gradient g;

void setup() {

  size(VIDEO_WIDTH,VIDEO_HEIGHT);
  g = new Gradient(0, 0, width, height, color(255),color(0), UP, MAX_DELAY);
  image(g.getGradient(), 0, 0 );

  src_video = new Movie (this, VIDEO_PATH);
  src_video.loop();
  result_image = createImage(width, height, RGB);
  source_array = new ArrayList();
  lock = new Semaphore(1);

  frameRate(30);
}


void draw() {
  frame.setTitle(int(frameRate) + "fps");
}


void initSourceArray(PImage source){
  for( int i = 0; i<MAX_DELAY; i++ ) {
    source_array.add(source);
  }
  first_image = false;

}

void updateArray(boolean plus, int num){
  if (MAX_DELAY != source_array.size()){
    if (plus){
      for(int i = 0; i<num ; i++)
      {
        source_array.add(source_array.get(source_array.size() -1));
      }
    }
    else{
      for(int i = 0; i<num ; i++)
      {
        source_array.remove(source_array.size() -1);
      }
    }
  }
}

void acquireImages(PImage source, ArrayList<PImage> sourceArray){
  try {
    lock.acquire();

  
  }
  catch (InterruptedException e) {
    println(e);
  }  
  for( int i = MAX_DELAY -1; i>0; i-- ) {
    PImage temp =sourceArray.get(i -1); 
    if ( temp != null){
      sourceArray.set(i, temp);
    }
  }
  lock.release();
  sourceArray.set(0, source);

}

void copyVideoSlits(ArrayList<PImage> sourceArray, PImage result){

  int length =  result.pixels.length/MAX_DELAY;

  try {
    lock.acquire();
  }
    catch (InterruptedException e) {
      println(e);
    }  
  for (int i = 0; i < MAX_DELAY ; i++)
  {
    PImage temp =sourceArray.get(i); 
    if(temp != null)
    {
      int pos = i * length;

      //println("pos :" + pos);
      System.arraycopy(temp.pixels, pos, result.pixels, pos,  length);
    }    
  }
  lock.release();
  result.updatePixels();
}


void copyVideoGradient(ArrayList<PImage> sourceArray, PImage result){


  try {
    lock.acquire();
  }
    catch (InterruptedException e) {
      println(e);
    }  

  for ( int x =0; x< width; x++ )
  {
    for ( int y =0; y<height; y++)
    {
      int delay =  g.getDelayValue(x,y, MAX_DELAY);
      int pos =y*width + x;
      result.pixels[pos] = sourceArray.get(delay).pixels[pos];
    }
  }
  lock.release(); result.updatePixels();

}

void movieEvent(Movie m) {
  
  m.read();
  src_image = src_video.get();
  src_image.loadPixels();

  if (first_image){
    initSourceArray(src_image);
  }
  acquireImages(src_image, source_array);
  if (DELAY_MODE == GRADIENT)
  {
    copyVideoGradient(source_array, result_image);
  }
  else if (DELAY_MODE == SLITS)
  {
    copyVideoSlits(source_array, result_image);
  }
  
  image(result_image, 0,0);
  
}
public void incrementSlots(int num){
   try {
        lock.acquire();

        }
        catch (InterruptedException e) {
          println(e);
        }
      MAX_DELAY +=num;
      MAX_DELAY = min(MAX_DELAY, height -1);
      MAX_DELAY = max(MAX_DELAY, 1);

      println("MAX_DELAY : "  + MAX_DELAY);
      updateArray(num >=0, num);
      lock.release();
}

void  keyPressed() {
  switch (key) {
    case '=':
      incrementSlots(1);
    break;
    case '-':
      incrementSlots(-1);
    break;
    case '+':
      incrementSlots(10);
    break;
    case '_':
      incrementSlots(-10);
    break;
    case 'w':
      setGradientDirection(UP);
    break;
    case 's':
      setGradientDirection(DOWN);
    break;
    case 'a':
      setGradientDirection(LEFT);
    break;
    case 'd':
      setGradientDirection(RIGHT);
    break;
  } 
}

void setGradientDirection(int d){
  if(DELAY_MODE == GRADIENT){
    g.setGradientDirection(d);
  }
}
