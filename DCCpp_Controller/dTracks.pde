//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Classes for Layouts and Tracks
//
//  Layout - defines a scaled region on the screen into which tracks
//           will be place using scaled coordinates
//
//  Track  - defines a curved or straight piece of track.
//         - placement on layout can be in absolute scaled coordinates
//           or linked to one end of a previously-defined track.
//         - tracks can be linked even across separate layouts
//         - define multiple overlapping tracks to create any type
//           of turnout, crossover, or other complex track
//////////////////////////////////////////////////////////////////////////

class Layout {
  float[] x = new float[2];
  float[] y = new float[2];
  float sFactor;

  Layout(int xCorner, int yCorner, int frameWidth, float layoutWidth, float layoutHeight) {
    this.x[0]=xCorner;
    this.y[0]=yCorner;
    sFactor=float(frameWidth)/layoutWidth;   // frameWidth in pixels, layoutWidth in mm, inches, cm, etc.
    this.x[1]=this.x[0]+layoutWidth*sFactor;
    this.y[1]=this.y[0]+layoutHeight*sFactor;
    check();
  } // Layout

  Layout(Layout layout) {
    this.x=layout.x;
    this.y=layout.y;
    this.sFactor=layout.sFactor;
  } // Layout

  void copy(Layout layout) {
    this.x=layout.x;
    this.y=layout.y;
    this.sFactor=layout.sFactor;
  } // copy

  boolean equals(Layout layout) {
    return((this.x[0]==layout.x[0])&&(this.y[0]==layout.y[0])&&(this.sFactor==layout.sFactor));
  } // equals

  void check() {
    println("Layout x1,y1,x2,y2,sf: ", x[0], y[0], x[1], y[1], sFactor);
    if (x[1] > width) {
      println("Layout too wide!");
      exit();
    }
    if (y[1] > height) {
      println("Layout too high!");
      exit();
    }
  }

  float toX(float layoutX) {
    float f = x[0] + layoutX*sFactor;
    if (f > x[1]) {
      println("Error in toX: ", layoutX, "->", f, " is outside the layout width!");
      //exit();
    }
    return f;
  }

  float toY(float layoutY) {
    float f = y[0] + layoutY*sFactor;
    if (f > y[1]) {
      println("Error in toY: ", layoutY, "->", f, " is outside the layout height!");
      //exit();
    }
    return f;
  }
} // Layout Class

//////////////////////////////////////////////////////////////////////////

class Track extends DccComponent {
  float[] x = new float[2];
  float[] y = new float[2];
  float[] a = new float[2];
  color tColor;
  float xR, yR;
  float r;
  float aStart, aEnd;
  int tStatus=1;         // specfies current track status (0=off/not visible, 1=on/visible)
  int hStatus=0;         // specifies if current track is highlighted (1) or normal (0)
  Layout layout;

  Track(Layout layout, float inX, float inY, float tLength, float angleDeg) {
    this.x[0]=inX;
    this.y[0]=inY;
    this.a[1]=angleDeg/360.0*TWO_PI;
    this.a[0]=this.a[1]+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
    println("Added track: ", layout.toX(x[0]), layout.toY(y[0]), layout.toX(x[1]), layout.toY(y[1]));
  } // Track - straight, absolute

  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float tLength, Layout layout) {
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[1]=track.a[trackPoint%2];
    this.a[0]=this.a[1]+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
    println("Added track: ", layout.toX(x[0]), layout.toY(y[0]), layout.toX(x[1]), layout.toY(y[1]));
  } // Track - straight, relative, Layout specified

  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float tLength) {
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[1]=track.a[trackPoint%2];
    this.a[0]=this.a[1]+PI;
    if (this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=track.layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
    println("Added track: ", layout.toX(x[0]), layout.toY(y[0]), layout.toX(x[1]), layout.toY(y[1]));
  } // Track - straight, relative, no Layout specified

  //////////////////////////////////////////////////////////////////////////

  Track(Layout layout, float inX, float inY, float curveRadius, float curveAngleDeg, float angleDeg) {
    float thetaR, thetaA;
    int d;

    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=angleDeg/360.0*TWO_PI;
    d=(thetaR>0)?1:-1;

    this.x[0]=inX;
    this.y[0]=inY;

    this.a[0]=thetaA+PI;
    if (this.a[0]>=TWO_PI)

      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if (this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if (this.a[1]<0)
      this.a[1]+=TWO_PI;

    this.r=curveRadius;

    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);

    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);

    if (d==1) {
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    } else {
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }

    this.layout=layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
    println("Added curved track: ",
      layout.toX(x[0]), layout.toY(y[0]),
      layout.toX(x[1]), layout.toY(y[1]),
      layout.toX(xR), layout.toY(yR),
      r, this.aStart, this.aEnd);
  } // Track - curved, absolute

  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float curveRadius, float curveAngleDeg, Layout layout) {
    float thetaR, thetaA;
    int d;

    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=track.a[trackPoint%2];
    d=(thetaR>0)?1:-1;

    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];

    this.a[0]=thetaA+PI;
    if (this.a[0]>=TWO_PI)

      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if (this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if (this.a[1]<0)
      this.a[1]+=TWO_PI;

    this.r=curveRadius;

    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);

    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);

    if (d==1) {
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    } else {
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }

    this.layout=layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
    println("Added curved track: ",
      layout.toX(x[0]), layout.toY(y[0]),
      layout.toX(x[1]), layout.toY(y[1]),
      layout.toX(xR), layout.toY(yR),
      r, this.aStart, this.aEnd);
  } // Track - curved, relative, Layout specified

  //////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float curveRadius, float curveAngleDeg) {
    float thetaR, thetaA;
    int d;

    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=track.a[trackPoint%2];
    d=(thetaR>0)?1:-1;

    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];

    this.a[0]=thetaA+PI;
    if (this.a[0]>=TWO_PI)

      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if (this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if (this.a[1]<0)
      this.a[1]+=TWO_PI;

    this.r=curveRadius;

    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);

    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);

    if (d==1) {
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    } else {
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }

    this.layout=track.layout;
    this.tColor=color(255, 255, 0);
    dccComponents.add(this);
    println("Added curved track: ",
      layout.toX(x[0]), layout.toY(y[0]),
      layout.toX(x[1]), layout.toY(y[1]),
      layout.toX(xR), layout.toY(yR),
      r, this.aStart, this.aEnd);
  } // Track - curved, relative, no Layout specified

  //////////////////////////////////////////////////////////////////////////

  float avgLayoutX() {
    return (layout.toX(x[0]) + layout.toX(x[1]))/2.0;
  }

  float avgLayoutY() {
    return (layout.toY(y[0]) + layout.toY(y[1]))/2.0;
  }

  void display() {

    if (tStatus==1) {                // track is visible
      if (hStatus==1)                // track is highlighted
        stroke(color(0, 255, 0));
      else
        stroke(tColor);
    } else {                          // track is not visible
      if (hStatus==1)                // track is highlighted
        stroke(color(255, 0, 0));
      else
        stroke(color(80, 80, 0));
    }

    strokeWeight(3);
    ellipseMode(RADIUS);
    noFill();
    if (r==0) {
      line(layout.toX(x[0]), layout.toY(y[0]), layout.toX(x[1]), layout.toY(y[1]));
    } else {
      arc(layout.toX(xR), layout.toY(yR), r*layout.sFactor, r*layout.sFactor, aStart, aEnd);
    }
  } // display()
} // Track Class

//////////////////////////////////////////////////////////////////////////