//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Configuration and Initialization
//
//  * Defines all global variables and objects
//
//  * Reads and loads previous status data from status files
//
//  * Implements track layout(s), throttles, track buttons, route buttons,
//    cab buttons, function buttons, windows, current meter,
//    and all other user-specified components
//
//////////////////////////////////////////////////////////////////////////

// DECLARE "GLOBAL" VARIABLES and OBJECTS

  PApplet Applet = this;                         // Refers to this program --- needed for Serial class

  int cursorType;
  String baseID;
  boolean keyHold=false;
  boolean saveXMLFlag=false;
  int lastTime;
  PFont throttleFont, messageFont, buttonFont;
  color backgroundColor;
  XML dccStatusXML, arduinoPortXML, sensorButtonsXML, autoPilotXML, cabDefaultsXML, serverListXML;
  
  DccComponent selectedComponent, previousComponent;
  ArrayList<DccComponent> dccComponents = new ArrayList<DccComponent>();
  ArrayList<CabButton> cabButtons = new ArrayList<CabButton>();
  ArrayList<CallBack> callBacks = new ArrayList<CallBack>();
  ArrayList<DccComponent> buttonQueue = new ArrayList<DccComponent>();
  ArrayList<DccComponent> buttonQueue2 = new ArrayList<DccComponent>();
  HashMap<Integer,EllipseButton> remoteButtonsHM = new HashMap<Integer,EllipseButton>();
  ArrayList<MessageBox> msgAutoCab = new ArrayList<MessageBox>();
  HashMap<Integer,TrackSensor> sensorsHM = new HashMap<Integer,TrackSensor>();    
  HashMap<String,CabButton> cabsHM = new HashMap<String,CabButton>();
  HashMap<Integer,TrackButton> trackButtonsHM = new HashMap<Integer,TrackButton>();  
  
  ArduinoPort       aPort;
  PowerButton       powerButton;
  AutoPilotButton   autoPilot;
  CleaningCarButton cleaningCab;
  Throttle          throttleA;
  Layout            layout,layout2,layoutBridge;
  MessageBox        msgBoxMain, msgBoxDiagIn, msgBoxDiagOut, msgBoxClock;
  CurrentMeter      currentMeter;
  Window            mainWindow, accWindow, progWindow, portWindow, extrasWindow, opWindow, diagWindow, autoWindow, sensorWindow, ledWindow;
  ImageWindow       imageWindow;
  JPGWindow         helpWindow;
  MessageBox        msgAutoState, msgAutoTimer;
  InputBox          activeInputBox;
  InputBox          accAddInput, accSubAddInput;
  InputBox          progCVInput, progHEXInput, progDECInput, progBINInput;
  InputBox          opCabInput, opCVInput, opHEXInput, opDECInput, opBINInput, opBitInput;
  InputBox          shortAddInput, longAddInput;
  MessageBox        activeAddBox;
  MessageBox        portBox, portNumBox;
  MessageBox        ledHueMsg, ledSatMsg, ledValMsg, ledRedMsg, ledGreenMsg, ledBlueMsg;
  PortScanButton    portScanButton;
  LEDColorButton    ledColorButton;
  
  Minim              minim;
  AudioPlayer        klaxonSound;
  AudioPlayer        warningSound;

// DECLARE TRACK BUTTONS, ROUTE BUTTONS, and CAB BUTTONS WHICH WILL BE DEFINED BELOW AND USED "GLOBALLY"  

  TrackButton      tButton1,tButton2,tButton3,tButton4,tButton5;
  TrackButton      tButton6,tButton7,tButton8,tButton9,tButton10;
  TrackButton      tButton20,tButton30,tButton40,tButton50;
  
  RouteButton      rButton1,rButton2,rButton3,rButton4,rButton5,rButton6,rButton7;
  RouteButton      rButton10,rButton11,rButton12,rButton13,rButton14;
  RouteButton      rButtonR1,rButtonR2,rButton15,rButton16,rButton17,rButtonSpiral,rButtonReset,rButtonBridge;  

  CabButton        cab8601,cab54,cab1202,cab1506,cab622,cab2004,cab6021;
  
////////////////////////////////////////////////////////////////////////
//  Initialize --- configures everything!
////////////////////////////////////////////////////////////////////////

  void Initialize(){
    colorMode(RGB,255);
    throttleFont=loadFont("OCRAExtended-26.vlw");
    messageFont=loadFont("LucidaConsole-18.vlw");
    buttonFont=loadFont("LucidaConsole-18.vlw");
    rectMode(CENTER);
    textAlign(CENTER,CENTER);
    backgroundColor=color(50,50,60);

    aPort=new ArduinoPort();
    
// READ, OR CREATE IF NEEDED, XML DCC STATUS FILE
    
    dccStatusXML=loadXML(STATUS_FILE);
    if(dccStatusXML==null){
      dccStatusXML=new XML("dccStatus");
    }

    arduinoPortXML=dccStatusXML.getChild("arduinoPort");
    if(arduinoPortXML==null){
      arduinoPortXML=dccStatusXML.addChild("arduinoPort");
      arduinoPortXML.setContent("Emulator");
    }
    
    serverListXML=dccStatusXML.getChild("serverList");
    if(serverListXML==null){
      serverListXML=dccStatusXML.addChild("serverList");
      serverListXML.setContent("127.0.0.1");
    }
    
    sensorButtonsXML=dccStatusXML.getChild("sensorButtons");
    if(sensorButtonsXML==null){
      sensorButtonsXML=dccStatusXML.addChild("sensorButtons");
    }

    autoPilotXML=dccStatusXML.getChild("autoPilot");
    if(autoPilotXML==null){
      autoPilotXML=dccStatusXML.addChild("autoPilot");
    }
    
    cabDefaultsXML=dccStatusXML.getChild("cabDefaults");
    if(cabDefaultsXML==null){
      cabDefaultsXML=dccStatusXML.addChild("cabDefaults");
    }
    
    saveXMLFlag=true;

    minim = new Minim(this);
    klaxonSound = minim.loadFile("klaxon.wav");
    warningSound = minim.loadFile("warning.wav");

// CREATE THE ACCESSORY CONTROL WINDOW
    
    accWindow = new Window(500,200,300,160,color(200,200,200),color(200,50,50));
    new DragBar(accWindow,0,0,300,10,color(200,50,50));
    new CloseButton(accWindow,288,0,10,10,color(200,50,50),color(255,255,255));
    new MessageBox(accWindow,150,22,0,0,color(200,200,200),20,"Accessory Control",color(200,50,50));
    new MessageBox(accWindow,20,60,-1,0,color(200,200,200),16,"Acc Address (0-511):",color(200,50,50));
    accAddInput = new InputBox(accWindow,230,60,16,color(200,200,200),color(50,50,200),3,InputType.DEC);
    new MessageBox(accWindow,20,90,-1,0,color(200,200,200),16,"Sub Address   (0-3):",color(200,50,50));
    accSubAddInput = new InputBox(accWindow,230,90,16,color(200,200,200),color(50,50,200),1,InputType.DEC);
    new AccessoryButton(accWindow,90,130,55,25,100,18,"ON",accAddInput,accSubAddInput);
    new AccessoryButton(accWindow,210,130,55,25,0,18,"OFF",accAddInput,accSubAddInput);
    accAddInput.setNextBox(accSubAddInput);
    accSubAddInput.setNextBox(accAddInput);
    
// CREATE THE SERIAL PORT WINDOW
    
    portWindow = new Window(500,200,500,170,color(200,200,200),color(200,50,50));
    new DragBar(portWindow,0,0,500,10,color(200,50,50));
    new CloseButton(portWindow,488,0,10,10,color(200,50,50),color(255,255,255));
    new MessageBox(portWindow,250,22,0,0,color(200,200,200),20,"Select Arduino Port",color(200,50,50));
    portScanButton = new PortScanButton(portWindow,100,60,85,20,100,18,"SCAN");
    new PortScanButton(portWindow,400,60,85,20,0,18,"CONNECT");
    new PortScanButton(portWindow,120,140,15,20,120,18,"<");
    new PortScanButton(portWindow,380,140,15,20,120,18,">");
    portBox = new MessageBox(portWindow,250,100,380,25,color(250,250,250),20,"",color(50,150,50));
    portBox.setMessage("Please press SCAN",color(150,50,50));
    portNumBox = new MessageBox(portWindow,250,140,0,0,color(200,200,200),20,"",color(50,50,50));

// CREATE THE PROGRAMMING CVs ON THE PROGRAMMING TRACK WINDOW
    
    progWindow = new Window(500,100,500,400,color(200,180,200),color(50,50,200));
    new DragBar(progWindow,0,0,500,10,color(50,50,200));
    new CloseButton(progWindow,488,0,10,10,color(50,50,200),color(255,255,255));
    new RectButton(progWindow,250,30,210,30,40,color(0),18,"Programming Track",ButtonType.TI_COMMAND,101);        
    
    new MessageBox(progWindow,20,90,-1,0,color(200,180,200),16,"CV (1-1024):",color(50,50,200));
    new MessageBox(progWindow,20,130,-1,0,color(200,180,200),16,"Value (HEX):",color(50,50,200));
    new MessageBox(progWindow,20,160,-1,0,color(200,180,200),16,"Value (DEC):",color(50,50,200));
    new MessageBox(progWindow,20,190,-1,0,color(200,180,200),16,"Value (BIN):",color(50,50,200));
    progCVInput = new InputBox(progWindow,150,90,16,color(200,180,200),color(200,50,50),4,InputType.DEC);
    progHEXInput = new InputBox(progWindow,150,130,16,color(200,180,200),color(200,50,50),2,InputType.HEX);
    progDECInput = new InputBox(progWindow,150,160,16,color(200,180,200),color(200,50,50),3,InputType.DEC);
    progBINInput = new InputBox(progWindow,150,190,16,color(200,180,200),color(200,50,50),8,InputType.BIN);
    progCVInput.setNextBox(progHEXInput);
    progHEXInput.setNextBox(progDECInput);
    progDECInput.setNextBox(progBINInput);
    progDECInput.linkBox(progHEXInput);
    progBINInput.setNextBox(progHEXInput);
    progBINInput.linkBox(progHEXInput);        
    new ProgWriteReadButton(progWindow,300,90,65,25,100,14,"READ",progCVInput,progHEXInput);
    new ProgWriteReadButton(progWindow,390,90,65,25,0,14,"WRITE",progCVInput,progHEXInput);

    new MessageBox(progWindow,20,240,-1,0,color(200,180,200),16,"ENGINE ADDRESSES",color(50,50,200));
    new MessageBox(progWindow,20,280,-1,0,color(200,180,200),16,"Short  (1-127):",color(50,50,200));
    new MessageBox(progWindow,20,310,-1,0,color(200,180,200),16,"Long (0-10239):",color(50,50,200));
    new MessageBox(progWindow,20,340,-1,0,color(200,180,200),16,"Active        :",color(50,50,200));
    shortAddInput = new InputBox(progWindow,190,280,16,color(200,180,200),color(200,50,50),3,InputType.DEC);
    longAddInput = new InputBox(progWindow,190,310,16,color(200,180,200),color(200,50,50),5,InputType.DEC);
    activeAddBox = new MessageBox(progWindow,190,340,-1,0,color(200,180,200),16,"?",color(200,50,50));
    new ProgAddReadButton(progWindow,300,240,65,25,100,14,"READ",shortAddInput,longAddInput,activeAddBox);
    new ProgShortAddWriteButton(progWindow,300,280,65,25,0,14,"WRITE",shortAddInput);
    new ProgLongAddWriteButton(progWindow,300,310,65,25,0,14,"WRITE",longAddInput);
    new ProgLongShortButton(progWindow,300,340,65,25,0,14,"Long",activeAddBox);
    new ProgLongShortButton(progWindow,390,340,65,25,0,14,"Short",activeAddBox);

// CREATE THE PROGRAMMING CVs ON THE MAIN OPERATIONS TRACK WINDOW
    
    opWindow = new Window(500,100,500,300,color(220,200,200),color(50,50,200));
    new DragBar(opWindow,0,0,500,10,color(50,50,200));
    new CloseButton(opWindow,488,0,10,10,color(50,50,200),color(255,255,255));
    new MessageBox(opWindow,250,30,0,0,color(220,200,200),20,"Operations Programming",color(50,100,50));
    new MessageBox(opWindow,20,90,-1,0,color(220,200,200),16,"Cab Number :",color(50,50,200));
    new MessageBox(opWindow,20,120,-1,0,color(220,200,200),16,"CV (1-1024):",color(50,50,200));
    new MessageBox(opWindow,20,160,-1,0,color(220,200,200),16,"Value (HEX):",color(50,50,200));
    new MessageBox(opWindow,20,190,-1,0,color(220,200,200),16,"Value (DEC):",color(50,50,200));
    new MessageBox(opWindow,20,220,-1,0,color(220,200,200),16,"Value (BIN):",color(50,50,200));
    opCabInput = new InputBox(opWindow,150,90,16,color(220,200,200),color(200,50,50),5,InputType.DEC);
    opCVInput = new InputBox(opWindow,150,120,16,color(220,200,200),color(200,50,50),4,InputType.DEC);
    opHEXInput = new InputBox(opWindow,150,160,16,color(220,200,200),color(200,50,50),2,InputType.HEX);
    opDECInput = new InputBox(opWindow,150,190,16,color(220,200,200),color(200,50,50),3,InputType.DEC);
    opBINInput = new InputBox(opWindow,150,220,16,color(220,200,200),color(200,50,50),8,InputType.BIN);
    opCVInput.setNextBox(opHEXInput);
    opHEXInput.setNextBox(opDECInput);
    opDECInput.setNextBox(opBINInput);
    opDECInput.linkBox(opHEXInput);
    opBINInput.setNextBox(opHEXInput);
    opBINInput.linkBox(opHEXInput);        
    new OpWriteButton(opWindow,300,90,65,25,0,14,"WRITE",opCVInput,opHEXInput);
    new MessageBox(opWindow,20,260,-1,0,color(220,200,200),16,"  Bit (0-7):",color(50,50,200));
    opBitInput = new InputBox(opWindow,150,260,16,color(220,200,200),color(200,50,50),1,InputType.DEC);
    new OpWriteButton(opWindow,300,260,65,25,50,14,"SET",opCVInput,opBitInput);
    new OpWriteButton(opWindow,390,260,65,25,150,14,"CLEAR",opCVInput,opBitInput);

// CREATE THE DCC++ CONTROL <-> DCC++ BASE STATION COMMUNICATION DIAGNOSTICS WINDOW
    
    diagWindow = new Window(400,300,500,120,color(175),color(50,200,50));
    new DragBar(diagWindow,0,0,500,10,color(50,200,50));
    new CloseButton(diagWindow,488,0,10,10,color(50,200,50),color(255,255,255));
    new MessageBox(diagWindow,250,20,0,0,color(175),18,"Diagnostics Window",color(50,50,200));
    new MessageBox(diagWindow,10,60,-1,0,color(175),18,"Sent:",color(50,50,200));
    msgBoxDiagOut=new MessageBox(diagWindow,250,60,0,0,color(175),18,"---",color(50,50,200));
    new MessageBox(diagWindow,10,90,-1,0,color(175),18,"Proc:",color(50,50,200));
    msgBoxDiagIn=new MessageBox(diagWindow,250,90,0,0,color(175),18,"---",color(50,50,200));

// CREATE THE AUTOPILOT DIAGNOSTICS WINDOW 
    
    autoWindow = new Window(400,300,500,330,color(175),color(50,200,50));
    new DragBar(autoWindow,0,0,500,10,color(50,200,50));
    new CloseButton(autoWindow,488,0,10,10,color(50,200,50),color(255,255,255));
    new MessageBox(autoWindow,250,20,0,0,color(175),18,"AutoPilot Window",color(50,50,150));
    msgAutoState=new MessageBox(autoWindow,0,180,-1,0,color(175),18,"?",color(50,50,250));
    msgAutoTimer=new MessageBox(autoWindow,55,310,-1,0,color(175),18,"Timer =",color(50,50,250));
    
// CREATE THE SENSORS DIAGNOSTICS WINDOW 
    
    sensorWindow = new Window(400,300,500,350,color(175),color(50,200,50));
    new DragBar(sensorWindow,0,0,500,10,color(50,200,50));
    new CloseButton(sensorWindow,488,0,10,10,color(50,200,50),color(255,255,255));
    new MessageBox(sensorWindow,250,20,0,0,color(175),18,"Sensors Window",color(50,50,150));

// CREATE THE HELP WINDOW
      
  helpWindow=new JPGWindow("helpMenu.jpg",1000,650,100,50,color(0,100,0));    
        
// CREATE THE EXTRAS WINDOW:

    extrasWindow = new Window(500,200,500,250,color(255,255,175),color(100,100,200));
    new DragBar(extrasWindow,0,0,500,10,color(100,100,200));
    new CloseButton(extrasWindow,488,0,10,10,color(100,100,200),color(255,255,255));
    new MessageBox(extrasWindow,250,20,0,0,color(175),18,"Extra Functions",color(50,50,200));
//    new RectButton(extrasWindow,260,80,120,50,85,color(0),16,"Sound\nEffects",0);        

// CREATE THE LED LIGHT-STRIP WINDOW:

    ledWindow = new Window(500,200,550,425,color(0),color(0,0,200));
    new DragBar(ledWindow,0,0,550,10,color(0,0,200));
    new CloseButton(ledWindow,538,0,10,10,color(0,0,200),color(200,200,200));
    new MessageBox(ledWindow,275,20,0,0,color(175),18,"LED Light Strip",color(200,200,200));
    ledColorButton=new LEDColorButton(ledWindow,310,175,30,201,0.0,0.0,1.0);
    new LEDColorSelector(ledWindow,150,175,100,ledColorButton);
    new LEDValSelector(ledWindow,50,330,200,30,ledColorButton);
    ledHueMsg = new MessageBox(ledWindow,360,80,-1,0,color(175),18,"Hue:   -",color(200,200,200));
    ledSatMsg = new MessageBox(ledWindow,360,115,-1,0,color(175),18,"Sat:   -",color(200,200,200));
    ledValMsg = new MessageBox(ledWindow,360,150,-1,0,color(175),18,"Val:   -",color(200,200,200));
    ledRedMsg = new MessageBox(ledWindow,360,185,-1,0,color(175),18,"Red:   -",color(200,200,200));
    ledGreenMsg = new MessageBox(ledWindow,360,220,-1,0,color(175),18,"Green: -",color(200,200,200));
    ledBlueMsg = new MessageBox(ledWindow,360,255,-1,0,color(175),18,"Blue:  -",color(200,200,200));

// CREATE TOP-OF-SCREEN MESSAGE BAR AND HELP BUTTON

    msgBoxMain=new MessageBox(width/2,12,width,25,color(200),20,"Searching for Base Station: "+arduinoPortXML.getContent(),color(30,30,150));
    new HelpButton(width-50,12,22,22,150,20,"?");

// CREATE CLOCK

    msgBoxClock=new MessageBox(30,700,-100,30,backgroundColor,30,"00:00:00",color(255,255,255));
    
// CREATE POWER BUTTON, QUIT BUTTON, and CURRENT METER
    
    powerButton=new PowerButton(75,475,100,30,100,18,"POWER");
    new QuitButton(200,475,100,30,250,18,"QUIT");
    // 675 == Arduino motor shield 2A current limit, based on 1.65V/A and analogRead 0-1023 scale having 0.0049V/step.
    // 214 == Pololu motor shielf 2A current limit, based on 0.525V/A and same analog read stuff.
    currentMeter = new CurrentMeter(25,550,150,100,214,5);

// CREATE THROTTLE, DEFINE CAB BUTTONS, and SET FUNCTIONS FOR EACH CAB
    
    int tAx=175;
    int tAy=225;
    int rX=800;
    int rY=550;

    throttleA=new Throttle(tAx,tAy,1.3);
    
    cab2004 = new CabButton(tAx-125,tAy-150,50,30,150,15,3,throttleA);
    cab2004.setThrottleDefaults(100,50,-50,-45);
    cab2004.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab2004.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab2004.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);
    
    cab622 = new CabButton(tAx-125,tAy-100,50,30,150,15,100,throttleA);
    cab622.setThrottleDefaults(53,30,-20,-13);
    cab622.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab622.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab622.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);

    cab8601 = new CabButton(tAx-125,tAy-50,50,30,150,15,8601,throttleA);
    cab8601.setThrottleDefaults(77,46,-34,-30);
    cab8601.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab8601.setFunction(35,15,60,22,60,10,0,"Lights",ButtonType.NORMAL,CabFunction.F_LIGHT,CabFunction.R_LIGHT);

    cab6021 = new CabButton(tAx-125,tAy,50,30,150,15,6021,throttleA);
    cab6021.setThrottleDefaults(50,25,-25,-15);
    cab6021.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab6021.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab6021.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);

    cab54 = new CabButton(tAx-125,tAy+50,50,30,150,15,54,throttleA);
    cab54.setThrottleDefaults(34,14,-5,-3);
    cab54.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab54.setFunction(35,15,60,22,60,10,10,"Radiator\nFan",ButtonType.NORMAL);
    cab54.setFunction(35,45,60,22,60,10,11,"Air Fill\n/Release",ButtonType.ONESHOT);
    cab54.setFunction(35,75,60,22,60,10,14,"Passenger\nDep/Arr",ButtonType.ONESHOT);
    cab54.setFunction(35,105,60,22,60,10,18,"City\nSounds",ButtonType.ONESHOT);
    cab54.setFunction(35,135,60,22,60,10,19,"Farm\nSounds",ButtonType.ONESHOT);
    cab54.setFunction(35,165,60,22,60,10,21,"Lumber\nMill",ButtonType.ONESHOT);
    cab54.setFunction(35,195,60,22,60,10,20,"Industry\nSounds",ButtonType.ONESHOT);
    cab54.setFunction(35,225,60,22,60,10,13,"Crossing\nHorn",ButtonType.ONESHOT,CabFunction.S_HORN);
    cab54.setFunction(35,255,60,22,60,10,22,"Alternate\nHorn",ButtonType.NORMAL);
    cab54.setFunction(35,285,60,22,60,10,8,"Mute",ButtonType.NORMAL);
    cab54.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab54.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab54.setFunction(35,45,60,22,60,10,1,"Bell",ButtonType.NORMAL,CabFunction.BELL);
    cab54.setFunction(35,75,60,22,60,10,2,"Horn",ButtonType.HOLD,CabFunction.HORN);
    cab54.setFunction(35,105,60,22,60,10,3,"MARS\nLight",ButtonType.REVERSE,CabFunction.D_LIGHT);
    cab54.setFunction(35,135,16,22,60,10,9,"1",ButtonType.NORMAL);
    cab54.setFunction(14,135,16,22,60,10,5,"+",ButtonType.ONESHOT);
    cab54.setFunction(56,135,16,22,60,10,6,"-",ButtonType.ONESHOT);
    cab54.setFunction(35,165,60,22,60,10,15,"Freight\nDep/Arr",ButtonType.ONESHOT);
    cab54.setFunction(35,195,60,22,60,10,16,"Facility\nShop",ButtonType.ONESHOT);
    cab54.setFunction(35,225,60,22,60,10,17,"Crew\nRadio",ButtonType.ONESHOT);
    cab54.setFunction(35,255,60,22,60,10,7,"Coupler",ButtonType.ONESHOT);
    cab54.setFunction(35,285,60,22,60,10,4,"Dynamic\nBrake",ButtonType.NORMAL);
    cab54.setFunction(35,315,60,22,60,10,12,"Brake\nSqueal",ButtonType.ONESHOT);

    cab1202 = new CabButton(tAx-125,tAy+100,50,30,150,15,1202,throttleA);
    cab1202.setThrottleDefaults(34,25,-24,-18);
    cab1202.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab1202.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab1202.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);

    cab1506 = new CabButton(tAx-125,tAy+150,50,30,150,15,1506,throttleA);
    cab1506.setThrottleDefaults(61,42,-30,-22);    
    cab1506.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab1506.setFunction(35,15,60,22,60,10,1,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab1506.setFunction(35,45,60,22,60,10,0,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);
    cab1506.setFunction(35,75,60,22,60,10,3,"D-Lights",ButtonType.NORMAL,CabFunction.D_LIGHT);
    
//  CREATE THE IMAGE WINDOW FOR THROTTLE A (must be done AFTER throttle A is defined above)

    imageWindow=new ImageWindow(throttleA,975,450,200,50,color(200,50,50));    

// CREATE AUTO PILOT BUTTON and CLEANING CAR BUTTON (must be done AFTER cab buttons are defined above)

    autoPilot=new AutoPilotButton(325,650,100,50,30,18,"AUTO\nPILOT");
    cleaningCab=new CleaningCarButton(extrasWindow,28,80,80,120,50,40,16,"Cleaning\nCar");        
      
// CREATE MAIN LAYOUT AND DEFINE ALL TRACKS

// Begin Cloverly 2017 Layout. 
    colorMode(RGB, 255);
    Cloverly2017();
  } // Initialize
    
  class Turnout {
    Track straight;
    Track divergent;
    TrackButton button;
    
    // Constructor:
    // - prior: Previous track segment to link to.
    // - slength: Length of straight.
    // - radious: Radius of divergent track.
    // - arc: Arc length of divergent track.
    // - id: The accessory ID for the button.
    // - dprior: Previous track to link divergent track to. if null, use prior.    
    Turnout(Track prior, int slength, int radius, int arc, int id, Track dprior) {
      straight = new Track(prior, 1, slength);
      divergent = new Track(dprior == null ? prior : dprior, 1, radius, arc);
      button = new TrackButton(20, 20, id);
      button.addTrack(straight, 0);
      button.addTrack(divergent, 1);
    }

  }  
     
  Turnout new5117R(Track prior, int id, Track dprior) {
    return new Turnout(prior, 180, 360, -30, id, dprior);
  }
  Turnout new5117L(Track prior, int id, Track dprior) {
    return new Turnout(prior, 180, 360, 30, id, dprior);    
  }  
  
  void Cloverly2017() {
    // x-width in mm stretched to accomodate top-layer alongside,
    // instead of above the bottom layer.
    // x in px, y in px, width in px, width in mm, height in mm
    Layout baseLayout = new Layout(225,50,width-225,5000, 3100);
    
    // Small dots to visually help define the layout bounds in the display.
    /*Track topLeft = new Track(baseLayout, 0, 0, 10, 0);
    Track topRight = new Track(baseLayout, 4170, 0, 10, 0);
    Track bottomLeft = new Track(baseLayout, 0, 3050, 10, 0);
    Track bottomRight = new Track(baseLayout, 4170, 3050, 10, 0);*/

    // The 180mm straight in the middle of the outer track curve at the
    // left hand end of the table serves as our anchor for the
    // rest of the base loop. The x values of these anchors are -100 of their
    // true positions on the table to assist the visual layout in the program.
    Track outerLeftAnchor = new Track(baseLayout, 106, 517, 180, 270); // 1 x 5106
    // The parallel 45mm+90mm straight in the inner track serves a similar purpose.
    Track innerLeftAnchor = new Track(baseLayout, 179, 540, 45+90, 270);  // 1 x 5108 + 5107
    
    // Remainder of the outer curve
    Track outerCurveBack = new Track(outerLeftAnchor, 0, 360, -90); // 3 x 5100
    Track outerCurveFront = new Track(outerLeftAnchor, 1, 360, 90); // 3 x 5100
    Track outerCurveToStation = new Track(outerCurveFront, 1, 33+22); // 5109, 5110
    
    // Remainder of the inner curve
    Track innerCurveBack = new Track(innerLeftAnchor, 0, 286, -90); // 2 x 5120
    Track innerCurveFront = new Track(innerLeftAnchor, 1, 286, 90); // 2 x 5120
    Track innerCurveToStation = new Track(innerCurveFront, 1, 70); // 5129
    
    // Inner curve/base layer features
    Station station = new Station(outerCurveToStation, innerCurveToStation);
    StationSidings sidings = new StationSidings(innerCurveBack);
    Town town = new Town(sidings.rightEntry.straight, station.innerRight.straight);
    MountainSidings ms = new MountainSidings(town.msLeft.straight, town.msRight.straight);
    FrontFeature feature = new FrontFeature(ms.toFeature.divergent);
    
    // Outer curve/mountain spiral
    SpiralClimb spiral = new SpiralClimb(outerCurveBack);
    MountainDescent descent = new MountainDescent(spiral.top);
    
  }
  
  class MountainDescent {
    Track c1, c2, c3, c4;
    Track d1, d2, d3, d4;
    
    MountainDescent(Track top) {
      c1 = new Track(top, 1, 360, -30);
      d1 = new Track(c1, 1, 180*7);
      c2 = new Track(d1, 1, 360, -30*6);
      // Altered from true geometry for aesthetic
      // layout purposes on screen (e.g. minimise
      // overlap between layers and intersections).
      // Track is functionally accurate.
      d2 = new Track(c2, 1, 180);
      c3 = new Track(d2, 1, 360, 30*2);
      d3 = new Track(c3, 1, (180*7)-20);
      c4 = new Track(d3, 1, 360, 30);
      d4 = new Track(c4, 1, (180*3).);
    }
  }
  
  class SpiralClimb {
    Track t1, t2;
    Track hillClimb;
    Track s1, s2, s3, s4, s5, top;
    
    SpiralClimb(Track entry) {
       t1 = new Track(entry, 1, 360, 30);
       t2 = new Track(t1, 1, 360, -30); //<>//
       // Actually 10, +5 to push out to the side for visual display.
       hillClimb = new Track(t2, 1, (180*15)+50); 
       s1 = new Track(hillClimb, 1, 360, -30);
       s2 = new Track(s1, 1, 180*6);
       s3 = new Track(s2, 1, 360, -30*7);
       s4 = new Track(s3, 1, 180*3);
       s5 = new Track(s4, 1, 360, -30*6);
       top = new Track(s5, 1, 180*3);
    }
  }

  class FrontFeature { //<>//
    Track f1, f2, f3, f4;
    
    FrontFeature(Track prior) {
      f1 = new Track(prior, 1, 360, -30*2);
      f2 = new Track(f1, 1, 360, 15);
      f3 = new Track(f2, 1, 360, -30);
      f4 = new Track(f3, 1, 180*5);
    }
  }
  
  class Town {
    Track town, frontTunnel, ft1, ft2, ft3;
    Track bs1, bs2, bs3, bs4, bs5; //below spiral.
    Turnout msRight, msLeft; // mountain sidings turnouts.

    Town(Track backEntry, Track frontEntry ) {
      town = new Track(backEntry, 1, 180*11);
      bs1 = new Track(town, 1, 360, -30);
      bs2 = new Track(bs1, 1, 360, 30);
      bs3 = new Track(bs2, 1, 360, -30);
      bs4 = new Track(bs3, 1, 360, 30);
      bs5 = new Track(bs4, 1, 360, -30*3);
      msRight = new5117R(bs5, 15, null);

      frontTunnel = new Track(frontEntry, 1, (180*4) + 70 + 22);
      ft1 = new Track(frontTunnel, 1, 360, -30);
      ft2 = new Track(ft1, 1, 180);
      msLeft = new5117L(ft2, 14, null);
      ft3 = new Track(msLeft.divergent, 1, 360, 30*2);
    }
  }

  class MountainSidings {
    Turnout entry, exit;
    Turnout t12t34;
    Turnout toFeature;
    Turnout t1t2, t3t4, t5t6;
    Track t1C, t1, t2, t3C, t3, t4, t5, t6C, t6;
    Track toBack, toFront, eeLink, tfC1, tfC2;
    
    MountainSidings(Track frontPoint, Track rearPoint) {
      toBack = new Track(rearPoint, 1, (180*2) + 90);
      tfC1 = new Track(frontPoint, 1, 360, 7.5);
      toFront = new Track(tfC1, 1, 90+45);
      tfC2 = new Track(toFront, 1, 360, -1*(30+7.5));
      
      exit = new5117R(toBack, 30, tfC2);
      eeLink = new Track(exit.straight, 1, 90);
      entry = new5117R(eeLink, 31, null);
      t12t34 = new5117L(entry.divergent, 32, null);
      t5t6 = new5117L(entry.straight, 33, null);
      toFeature = new5117R(t12t34.straight, 34, null);
      t3t4 = new5117R(t12t34.divergent, 35, null);
      t1t2 = new5117L(toFeature.straight, 36, null);
      
      t1C = new Track(t1t2.straight, 1, 360, 30);
      t1 = new Track(t1C, 1, 180*3);
      t2 = new Track(t1t2.divergent, 1, 180*4);
      t3C = new Track(t3t4.divergent, 1, 360, 30);
      t3 = new Track(t3C, 1, 180*3);
      t4 = new Track(t3t4.straight, 1, 180*4);
      t5 = new Track(t5t6.straight, 1, 180*5);
      t6C = new Track(t5t6.divergent, 1, 360, -30);
      t6 = new Track(t6C, 1, 180*4);
    }
  }
  
  class StationSidings {
    Turnout leftEntry, rightEntry, t1t2;
    Track t1Curve, t1, t2, t3;
    
    StationSidings(Track entry) {
      leftEntry = new5117R(entry, 11, null);
      rightEntry = new5117R(leftEntry.straight, 12, null);
      t1t2 = new5117R(leftEntry.divergent, 13, null);
      t1Curve = new Track(t1t2.divergent, 1, 360, 30);
      t1 = new Track(t1Curve, 1, 180 * 2);  
      t2 = new Track(t1t2.straight, 1, 180*4);
      t3 = new Track(rightEntry.divergent, 1, 180*5);
    }
  }

  class Station {
    Turnout innerLeft, outerLeft, innerRight, outerRight;
    Turnout p1Left, p1Right, p2Left, p2Right, p3Left, p3Right;
    Track p1, p2, p3, p1LeftCurve, p1RightCurve;
    Track xoverLeft, xoverLeftD, xoverRight, xoverRightD;
    
    Station(Track outerEntry, Track innerEntry) {
      // Draw the station, left to right, starting with the entry points from the
      // inner & outer tracks.
      innerLeft = new5117R(innerEntry,  1, null);
      outerLeft = new5117R(outerEntry, 2, null);
      
      // Next the points/lead-in to the individual platforms, draw in order of
      // the inner track (plat 3) through to the front track (plat 1) so references
      // to the preceeding turnouts are available.
      p3Left = new5117R(innerLeft.straight, 3, null);       
      xoverLeft = new Track(outerLeft.straight, 1, 180);                   // 5114
      xoverLeftD = new Track(innerLeft.divergent, 1, 180);      
      p2Left = new5117L(xoverLeft, 4, p3Left.divergent);
      p1LeftCurve = new Track(outerLeft.divergent, 1, 360, 30);
      p1Left = new5117L(p1LeftCurve, 5, xoverLeftD);
      
      // Now the platform straights.
      p3 = new Track(p3Left.straight, 1, (180*5) + 45);      // 5106 x 5, 5108
      p2 = new Track(p2Left.straight, 1, 45 + (180*3));      // 5108, 5106 x 3
      p1 = new Track(p1Left.straight, 1, (33*2) + (180*3));  // 5109 x2, 5106 x 3
      
      // Now the right-hand side points, in reverse order to above. If you look at
      // a diagram of the track, you'll see why the ordering to have the preceeding
      // track piece references available makes sense.
      p1Right = new5117L(p1, 6, null);
      p1RightCurve = new Track(p1Right.straight, 1, 360, 30);      
      p2Right = new5117L(p2, 7, null);
      xoverRight = new Track(p2Right.straight, 1, 180);                 // 5114
      xoverRightD = new Track(p1Right.divergent, 1, 180);      
      p3Right = new5117R(p3, 8, p2Right.divergent);
      
      // Finally the points back onto the inner/outer tracks.
      innerRight = new5117R(p3Right.straight, 9, xoverRightD);
      outerRight = new5117R(xoverRight, 10, p1RightCurve);
    }
  }
  
//////////////////////////////////////////////////////////////////////////