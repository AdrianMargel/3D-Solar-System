/*
  3D solar system
  ---------------
  This is a simple 3d simulation of the formation of a solar system.
  You can use the scroll wheel on your mouse to rotate the pitch of the camera.
  
  written by Adrian Margel, Spring 2018
*/

class Planet{
  
  //if the planet is alive, this just means it hasn't been destroyed by colliding into another planet
  boolean alive;
  
  //3d position of the planet
  PVector pos;
  //3d vector speed of the planet
  PVector speed;
  
  //how much the planet weighs
  float weight;
  //the density of the planet used to calculate the planet's size
  float density;
  
  //the color of the planet
  float hue;
  
  Planet(PVector p,PVector s,float w,float d,float h){
    alive=true;
    speed = s;
    pos = p;
    weight=w;
    density=d;
    hue=h;
  }
  
  void display(){
    pushMatrix();
    noStroke();
    fill(hue,255,255);
    
    translate(pos.x,pos.y,pos.z);
    sphere(sqrt(weight/density/PI));
    popMatrix();
  }
  
  //move the physical location of the planet
  void move(){
    if(alive){
      pos.add(speed);
    }
  }
  
  //calculate the forces on the planet and update the speed
  void recalc(ArrayList<Planet> planets,int me){
    //apply gravitational attraction between this planet and all other planets
    for(int i=0;i<planets.size();i++){
      if(i!=me){
        float gravity=1;
        float d = PVector.dist(pos, planets.get(i).pos);
        PVector temp = planets.get(i).pos.copy();
        float f=(gravity*weight*planets.get(i).weight/sq(d));
        speed.add((temp.sub(pos)).mult(f/(d*weight)));
      }
    }
  }
  
  //gravitational equation for refference:
  //(Msat • v^2) / R = (G • Msat • MCentral ) / R^2
  //v = sqrt(F * R / Msat)
  
  //creates an orbit likely to be stable based on the average gravitational force acting on it
  void guessOrbit(ArrayList<Planet> planets,int me){
    //calculate average forces
    PVector averageAttract=new PVector();
    for(int i=0;i<planets.size();i++){
      if(i!=me){
        float gravity=1;
        float d = PVector.dist(pos, planets.get(i).pos);
        PVector temp = planets.get(i).pos.copy();
        
        //simplified out weight here pt1
        //float f=(gravity*weight*planets.get(i).weight/sq(d));
        float f=(gravity*planets.get(i).weight/sq(d));
        
        averageAttract.add((temp.sub(pos)).mult(f));
      }
    }
    
    //add speed at a 90 degree angle to the gravity vector to create a stable orbit
    float dist=sqrt(sq(averageAttract.x)+sq(averageAttract.y)+sq(averageAttract.z));
    float angle=atan2(averageAttract.y,averageAttract.x);
    PVector direction=new PVector(cos(angle+PI/2),sin(angle+PI/2),0);
    
    //simplified out weight here pt2
    //speed.add(direction.mult(sqrt(dist/weight)));
    speed.add(direction.mult(sqrt(dist)));
  }
  
  //have planets collide with eachother
  void collide(ArrayList<Planet> planets,int me){
    //test against all other planets if alive
    for(int i=0;i<planets.size();i++){
      if(i!=me&&alive){
        float d = PVector.dist(pos, planets.get(i).pos);
        //if heavily overlapping with an alive planet
        //planets are allowed to somewhat overlap without colliding
        if(d<=(sqrt(planets.get(i).weight/planets.get(i).density/PI)+sqrt(weight/density/PI))/2&&planets.get(i).weight<=weight&&alive&&planets.get(i).alive){
          //kill the other planet
          planets.get(i).alive=false;
          
          //set to be the weighted average of the values for each planet in the collision
          float temp=planets.get(i).weight+weight;
          pos=(pos.mult(weight).add(planets.get(i).pos.mult(planets.get(i).weight))).div(temp);
          speed=(speed.mult(weight).add(planets.get(i).speed.mult(planets.get(i).weight))).div(temp);
          density=(density*(weight)+(planets.get(i).density*(planets.get(i).weight)))/(temp);
          
          //this looks a lot more complicated than it is
          //it's basically just converting the colors to vectors based on their hue and then using the weighted average of the two vectors to calculate the average hue.
          hue=
            (
              (
                atan2(
                  sin(hue/255*TWO_PI)*(weight)+sin(planets.get(i).hue/255*TWO_PI)*(planets.get(i).weight)
                  ,cos(hue/255*TWO_PI)*(weight)+cos(planets.get(i).hue/255*TWO_PI)*(planets.get(i).weight)
                )/TWO_PI*255
              )+255
            )%255;
          
          //add weights together
          weight+=planets.get(i).weight;
        }
      }
    }
  }
}

//how zoomed in the camera is
float zoom=-12;
//the camera rotation
float rot=0;

//the list of all planets
ArrayList<Planet> planets=new ArrayList<Planet>();

void setup(){
  //set color mode to use hue
  colorMode(HSB);
  //create window in 3d mode
  size(800,800,P3D);
  
  //create the sun in the center
  planets.add(new Planet(new PVector(0,0,0),new PVector(0,0,0),500000,10,0));
  
  //create all the planets randomly in a disk around the sun
  for(int i=0;i<1000;i++){
    float angle=random(0,TWO_PI);
    float dist=random(150,1000);
    planets.add(new Planet(new PVector(cos(angle)*dist,sin(angle)*dist,random(-100,100))
      ,new PVector(0,0,0)
      ,random(15,50),random(0.1,1),angle/TWO_PI*255));
  }
  
  //set black background
  background(0);
  
  //center camera
  translate(width/2,height/2);
  scale(pow(1.1,zoom));
  
  //start planets at a stable orbit and display them
  for(int i=planets.size()-1;i>=0;i--){
    planets.get(i).guessOrbit(planets,i);
    planets.get(i).display();
  }
}

void draw(){
  background(0);
  
  //position camera
  translate(width/2,height/2);
  scale(pow(1.1,zoom));
  rotateX(rot);
  
  //move camera to focus on the center of gravity
  PVector center=new PVector(0,0,0);
  float totalMass=0;
  for(int i=planets.size()-1;i>=0;i--){
    PVector temp=planets.get(i).pos.copy();
    center.add(temp.mult(planets.get(i).weight));
    totalMass+=planets.get(i).weight;
  }
  center.div(totalMass);
  translate(-center.x,-center.y);
  
  //apply gravity to planets
  for(int i=0;i<planets.size();i++){
    planets.get(i).recalc(planets,i);
  }
  
  //move planets and have them collide.
  //run collide before and after moving positions to miss fewer collisions
  //keep in mind that the positions and sizes can also change after the first collision creating a new collision
  for(int i=0;i<planets.size();i++){
    planets.get(i).collide(planets,i);
    planets.get(i).move();
    planets.get(i).collide(planets,i);
  }
  
  //remove dead (collided) planets and display the alive planets
  for(int i=planets.size()-1;i>=0;i--){
    if(!planets.get(i).alive){
      planets.remove(i);
    }else{
      planets.get(i).display();
    }
  }
}

//scrolling will rotate the camera
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  rot+=e/10;
}
