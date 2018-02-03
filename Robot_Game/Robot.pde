class Robot
{
  PVector position, velocity, acceleration;
  float w, h;
  float angle, a_velocity, a_acceleration;
  color robotColor;
  
  Rectangle rectangle;    //Nonrotated
  Rectangle frontRectangle;
  Area collisionBox;      //Rotated
  Area frontCollisionBox; //Front Box Rotated
  
  float speed;
  float a_speed;
  
  float maxSpeed;
  
  Cube cube;
  
  boolean intakeActive;
  boolean canIntake;
  
  Robot(float x, float y, float w, float h, float angle, color robotColor)
  {
    position = new PVector(x, y);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    
    this.angle = angle;
    a_velocity = 0;
    a_acceleration = 0;
    
    this.speed = 0.75;
    this.a_speed = 0.5;
    
    this.maxSpeed = 5.0;
    
    this.w = w;
    this.h = h;
    
    this.rectangle = new Rectangle((int) position.x - width / 2, (int) position.y - height / 2, (int) w, (int) h);
    
    this.robotColor = robotColor;
    this.cube = null;
    
    this.intakeActive = false;
    this.canIntake = true;
  }
  
  void update(ArrayList<Area> objects, ArrayList<Cube> cubes)
  {
    updateCollisionBox();
    
    //Calculate Forces
    calculateAirResistance();
    
    updatePositions(objects, cubes);
    if(intakeActive && this.cube == null) handleCollisions(cubes);
    if(intakeActive && canIntake && this.cube != null) ejectCube(cubes);
    
    if(this.cube != null) updateCubePosition();
  }
  
  void updateCollisionBox()
  {
    rectangle.setLocation((int) (position.x - w / 2), (int) (position.y - h / 2));
    collisionBox = new Area(rectangle);
    
    frontRectangle = new Rectangle((int) (position.x - w / 4), (int) (position.y - h / 2 - 1), (int) w / 2, (int) h / 2);
    frontCollisionBox = new Area(frontRectangle);
    
    AffineTransform transform = new AffineTransform();
    transform.rotate(radians(angle), position.x, position.y);
    
    collisionBox.transform(transform);
    frontCollisionBox.transform(transform);
  }
  
  void calculateAirResistance()
  {
    applyAngularForce(-0.1 * a_velocity);
    applyForce(PVector.mult(velocity, -0.1));
  }
  
  void updatePositions(ArrayList<Area> objects, ArrayList<Cube> cubes)
  {
    Area unified = new Area();
    for(Area area : objects)
    {
      unified.add(area);
    }
    int DIVISIONS = 150;
    
    if(velocity.magSq() > maxSpeed * maxSpeed) velocity.setMag(maxSpeed);
    if(velocity.magSq() < 0.01) velocity.mult(0);
    
    //Apply all of the forces to the position
    this.velocity.add(acceleration);
    
    PVector move = PVector.div(this.velocity, DIVISIONS);
    for(int i = 0; i < DIVISIONS; i++)
    {
      this.position.add(move);
      updateCollisionBox();
      if(intersects(unified))
      {
        this.position.sub(move);
        break;
      }
      
      for(Cube cube : cubes)
      {
        if(intersects(cube.getArea()))
        {
          this.position.sub(move);
          break;
        }
      }
    }
    
    this.a_velocity += this.a_acceleration;
    float moveAngle = this.a_velocity / DIVISIONS;
    for(int i = 0; i < DIVISIONS; i++)
    {
      this.angle += moveAngle;
      updateCollisionBox();
      if(intersects(unified))
      {
        this.angle -= moveAngle;
        break;
      }
      
      for(Cube cube : cubes)
      {
        if(intersects(cube.getArea()))
        {
          this.angle -= moveAngle;
          break;
        }
      }
    }
    
    angle = angle % 360;
    if(angle < 0) angle += 360;
    if(abs(a_velocity) < 0.001) a_velocity = 0;
    
    //Reset the acceleration
    this.acceleration.mult(0);
    this.a_acceleration = 0;
  }
  
  void handleCollisions(ArrayList<Cube> cubes)
  {
    Iterator<Cube> iterator = cubes.iterator();
    while(iterator.hasNext())
    {
      Cube cube = (Cube) iterator.next();
      if(intersectsFront(cube.getArea()))
      {
        this.cube = cube;
        iterator.remove();
        intakeActive = false;
        canIntake = false;
        break;
      }
    }
  }
  
  void ejectCube(ArrayList<Cube> cubes)
  {
    cubes.add(cube);
    this.cube = null;
  }
  
  void updateCubePosition()
  {
    this.cube.position = PVector.add(position, PVector.fromAngle(radians(angle - 90)).mult(h * 2 / 3.0));
  }
  
  void applyForce(PVector force)
  {
    acceleration.add(force);
  }
  
  void applyAngularForce(double force)
  {
    a_acceleration += force;
  }
  
  void draw()
  {
    pushMatrix();
    
    translate(position.x, position.y);
    rotate(radians(angle));
    
    fill(this.robotColor);
    rectMode(CENTER);
    rect(0, 0, w, h);
    
    popMatrix();
  }
  
  void input(HashSet<Character> keys)
  {
    if(keys.contains('d')) applyAngularForce(a_speed);
    if(keys.contains('a')) applyAngularForce(-a_speed);
    if(keys.contains('w'))
    {
      PVector moveForce = PVector.fromAngle(radians(angle - 90)).mult(speed);
      applyForce(moveForce);
    }
    if(keys.contains('s'))
    {
      PVector moveForce = PVector.fromAngle(radians(angle - 90 + 180)).mult(speed);
      applyForce(moveForce);
    }
    intakeActive = keys.contains(' ');
    if(!keys.contains(' ')) canIntake = true;
  }
  
  boolean intersects(Area other)
  {
    return collisionBox.intersects(other.getBounds()) && other.intersects(collisionBox.getBounds());
  }
  
  boolean intersectsFront(Area other)
  {
    return frontCollisionBox.intersects(other.getBounds()) && other.intersects(frontCollisionBox.getBounds());
  }
}