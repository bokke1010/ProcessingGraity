double G = 0.0000000000667408;
float dt = 7f * 24f * 60f * 60f;
float lastMS = 0;
float defaultMass = 200f;

Vector2 mouseStart;
float mouseScale = 0.000001f;
float scrollScale = 0.0000001f;
float mc = 20f; // average mass of new planets

int coordToScreenPoint(float coord) {
  return (int)coord;
}

int screenPointToCoord(int screenPoint) {
  return int(screenPoint);
}

static class Vector2 {
  float x;
  float y;
  Vector2(float inX, float inY) {
    x = inX;
    y = inY;
  }

  static float distance(Vector2 a, Vector2 b) {
    return Vector2.length(Vector2.subtract(a, b));
  }

  static float length(Vector2 a) {
    return sqrt(pow(a.x, 2)+pow(a.y, 2) );
  }

  static Vector2 add (Vector2 a, Vector2 b) {
    return new Vector2(a.x + b.x, a.y + b.y);
  }

  static Vector2 subtract (Vector2 a, Vector2 b) {
    return new Vector2(a.x - b.x, a.y - b.y);
  }

  static Vector2 divide (Vector2 a, float b) {
    return new Vector2(a.x / b, a.y / b);
  }

  static Vector2 multiply (Vector2 a, float b) {
    return new Vector2(a.x * b, a.y * b);
  }

  static Vector2 multiply (Vector2 a, double b) {
    return new Vector2((float)(a.x * b), (float)(a.y * b));
  }

  static Vector2 normalize(Vector2 a) {
    return Vector2.divide(a, Vector2.length(a));
  }
}



class CelestialBody {
  float mass = 1;
  float radius = 1;
  Vector2 velocity = new Vector2(0f, 0f);
  Vector2 position = new Vector2(0f, 0f);
  CelestialBody(float inMass, Vector2 inVelocity, Vector2 inPosition) {
    mass = inMass;
    velocity = inVelocity;
    position = inPosition;
    radius = radius(mass);
  }

  float radius(float mass) {
    return pow(( ( mass / PI ) * 0.75f ), 1f/3f);
  }

  public void merge(CelestialBody other, CelestialBody selfCB) {
    float[] massFractions = {mass / (mass + other.mass), other.mass / (mass + other.mass)};

    other.position = Vector2.add(Vector2.multiply(position, massFractions[0]), Vector2.multiply(other.position, massFractions[1]));
    other.velocity = Vector2.add(Vector2.multiply(velocity, massFractions[0]), Vector2.multiply(other.velocity, massFractions[1]));

    println("My own mass is: " + str(mass) + ", and cb's (dominant) mass is: " + str(other.mass));
    other.mass = mass + other.mass;
    println("Cb's mass is: " + str(other.mass));

    other.radius = radius(other.mass);
    removeList.add(selfCB);
  }

  public void update( ArrayList<CelestialBody> others, float deltaTime) {
    for (int i = 0; i < others.size(); i++) {
      CelestialBody cb = others.get(i);
      if (!(cb == this)) {
        if (Vector2.distance(position, cb.position) < (radius + cb.radius)) {
          if (mass < cb.mass) {
            println("Collision registed, this is the dominant object. Distance: " + str(Vector2.distance(position, cb.position)));
            line(position.x, position.y, cb.position.x, cb.position.y);
            merge(cb, this);
          }
        }

        float distanceBetweenBodies = Vector2.distance(position, cb.position);

        // Work out gravity strenght and direction
        float gravitationalForce = ((float)(G * (double)mass * (double)cb.mass))/ pow(distanceBetweenBodies, 2);
        Vector2 gravityDirection = Vector2.normalize(Vector2.subtract(cb.position, position));
        Vector2 gravityVector = Vector2.multiply(gravityDirection, gravitationalForce/mass);
        // println("The gravity vector's X: " + str(gravityVector.x) + ". And the Y is: " + str(gravityVector.y) + ".");
        
        // Draw gravity vector
        float mp = 50f;
        Vector2 gravityVectorVis = Vector2.multiply(gravityDirection, gravitationalForce);
        line(coordToScreenPoint(position.x), coordToScreenPoint(position.y),
          coordToScreenPoint(position.x + gravityVectorVis.x * mp), coordToScreenPoint(position.y + gravityVectorVis.y * mp));
        
        // Adjust velocity and position accordingly
        velocity = Vector2.add(velocity, Vector2.multiply( gravityVector, deltaTime));
        position = Vector2.add(position, Vector2.multiply(velocity, deltaTime));
      }
    }
    fill(0,0,0,0);
    ellipse(coordToScreenPoint(position.x), coordToScreenPoint(position.y), 2* radius, 2* radius);
  }
}

ArrayList<CelestialBody> removeList = new ArrayList<CelestialBody>();

ArrayList<CelestialBody> bodies = new ArrayList<CelestialBody>();
void setup() {
  size(480, 480);
  frameRate(30);
}


void draw() {
  background(255);
  float frameTime = (lastMS - millis()) / 1000; // In seconds, for physics reasons.
  lastMS = millis();
  float updateSpeed = dt * frameTime;
  for (int i = 0; i < bodies.size(); i++) {
    bodies.get(i).update(bodies, updateSpeed);
  }
  ArrayList<CelestialBody> temp = new ArrayList<CelestialBody>(bodies);
  for (int i = 0; i < bodies.size(); i++) {
    for (int j = 0; j < removeList.size(); j++) {
      if (bodies.get(i) == removeList.get(j)) {
        temp.remove(i);
      }
    }
  }
  bodies = temp;

  //for (int i = 0; i < bodies.size(); i++){
  //  println("This is body" + str(i) + ", with a position of x: " + str(bodies.get(i).position.x) + ", y: "+ str(bodies.get(i).position.x) + ".");
  //}

  if (mousePressed) {
    line(coordToScreenPoint(mouseStart.x), coordToScreenPoint(mouseStart.y), mouseX, mouseY);
  }
}

void mousePressed() {
  mouseStart = new Vector2((float)screenPointToCoord(mouseX), (float)screenPointToCoord(mouseY));
}

void mouseReleased() {
  Vector2 end = new Vector2(screenPointToCoord(mouseX), screenPointToCoord(mouseY));
  Vector2 vel = Vector2.multiply(Vector2.subtract( end, mouseStart), mouseScale);
  println(str(vel.x));
  bodies.add(new CelestialBody(random(mc-1f, mc+1f), vel, mouseStart));
}

void mouseWheel(MouseEvent event) {
  mouseScale += event.getCount() * scrollScale;
  println(mouseScale);
}

void keyPressed() {
  if (key == 'm'){
    mc *= 2f;
  }
  if (key == 'n'){
    mc *= 0.5f;
  }
  println("Mass has been adjusted to: " + str(mc));
  // J is time acceleration, K is time slow (+10%, /1.1 respectively
  if (key == 'j'){
    dt *= 1.1f;
  }
  if (key == 'k'){
    dt /= 1.1f;
  }
  println("DeltaTime has been adjusted to:" + str(dt));
}
    
