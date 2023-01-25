// Records event from pin 'lick' and sends it
// through serial port as the time of event from the
// "start". Cues will be triggered throgh pin "cue".
// Designed to be used with MATLAB.
//
// Program will wait for signal from MATLAB containing paramenters for experiment. Following parameters need to be in the format xxx+xxx+xxx+xxx+xxx+xxx+xxx+xxx+xxx+xxx+xxx+xxx+xxx
// Every temporal parameter is expressed in units of milliseconds. Parameters to be set in MATLAB include

// FOR THIS PROGRAM, CS+ IS DEFINED AS THE 12KhZ TONE INDEPENDENT OF ITS ASSOCIATION WITH REWARD. THIS IS CONFUSING BUT WAS WRITTEN BEFORE THE PROBABILITY FOR EACH CUE WAS
// ADDED. SO VIJAY DIDN'T WANT TO GO BACK AND CHANGE EVERY VARIABLE NAME.

// This version includes improved laser control (pulseoof, pulse duration, train duration), and PR ratio capablity (if thePR box is checked in the GUI, the required number of pressess will double in each trial
// the starting value will be that specified in the GUI. response requirement only doubles if the response criterion was met on previous trial. Both operanda are independant from each other). ADDED BY IT MAY 2017

// Version 5 includes corrected stop button functionality. 
// IMPORTANT: THIS VERSION delivers liquid US BEFORE the offset of the cue. Ideal for quinine induced lick attenuation 
// of optogenetic induced licking experiments

//1) rate of background rewards,
//2) magnitude of background rewards (open time for solenoid/pump),
//3) delay to fixed reward,
//4) magnitude of fixed reward,
//5) mean intertrial interval (ITI) from fixed reward to next tone based on an exponential distribution,
//6) maximum ITI, truncation for exponential distribution is set at minimum of maximum ITI or 3*meanITI
//7) tone duration
//8) total number of CSs in session (including CS+ and CS-)
//9) minimum delay between a background reward and the next cue presentation
//10) minimum delay between fixed reward to the next background reward
//11) number of CS- cues
//12) frequency of CS+ tone
//13) frequency of CS- tone; CS- tone is set as a pulsing stimulus at this frequency that turns on and off repeatedly with period=200ms for the duration set above as tone duration.
//14) Flag to run experiment without cues, delivering just a Poisson train of rewards. If nocuesflag==1, run experiment without cues
//15) Flag to run experiment with the background reward rates changing on a trial-by-trial basis. Every even trial has zero background rewards and odd trials has periods picked randomly from 6000,12000,15000,18000
//16) Flag to set ITI distribution. If == 1, draw from exponential. If not, draw from uniform
//17) laser latency with respect to cue
//18) laser duration: laser train duration (ms)
//19) laser period: Value of the period for laser remaining on in any cycle. So if you want 20Hz pulsing with 80% duty cyle, set to 40. Units in ms
//20) laser period off: Value of the period for laser remaining off in any cycle. So if you want 20Hz pulsing with 20% duty cyle, set to 10. Units in ms
//21) Total number of Poisson rewards when no cue is delivered and a Poisson train of rewards is delivered
//22) Whether laser is present on a trial-by-trial basis?
//23) CS+ probability; added on 12/7/2015
//24) CS- probability; added on 12/7/2015
//25) Flag to turn on laser at random points during the session for a duration equaling the cue-reward delay.; added on 2/23/2016
//26) Flag to check if 3kHz tone is produced by a different speaker or the same speaker as the 12kHz one.
//      Added by ITP for Operant conditioning Nov 2016:
//27) Flag for operant experiments
//28) Flag for Active left lever
//29) Flag for Active right lever
//30) Program type (type of R+ schedule) for left lever
//31) Program type (type of R+ schedule) for right lever
//32) FR number or PR increment factor for left lever
//33) FR number or PR increment factor for right lever
//34) Reward magnitude for Left lever
//35) Reward magnitude for Right lever
//36) Total trials in session
//37) Trial duration limit
          


#include <math.h>
#include <avr/wdt.h>

// Pins
int lick    = 5;   // lick sensor to pin 5
int speakerpulse = 6; // pin for pulsing speaker
int speaker = 8;   // speaker to pin 8
int pump    = 10;  // pump to pin 10
int laser   = 9;   // laser to pin 9
int ttloutpin = 3; // ttl out pin for starting imaging
int framein = 7;   // pin receiving the TTL input for frame start
int ttloutstoppin = 12; // ttl out pin for stopping imaging
//Pins for operant conditioning. Added by ITP Nov 2016
int leftL = 2; // pin for left lever
int rightL = 4; // pin for right lever
int leftLED = 11; // pin for LED for left lever
int rightLED = 13; // pin for LED for right lever


// Global variables
unsigned long reading;                     // variable to temporarily store data being read

unsigned long start;             // timestamp of start of session
unsigned long ts;                // current timestamp

boolean lickState;               // state of lickometer
boolean licked;                  // new lick or not
boolean lickwithdrawn;           // was previous lick withdrawn or not?
boolean ITIflag;                 // are you currently in ITI? This needs to be true to give background rewards
boolean CSminusflag;             // is current trial a CS- trial?
boolean nocuesflag;              // if ==1, run experiment without any cues, delivering a Poisson train of rewards (param[13])
boolean trialbytrialbgdrewflag;  // if ==1, run experiment by changing bgd reward rate on a trial-by-trial basis  (param[14])
boolean expitiflag;              // if ==1, itis are drawn from an exponential distribution (param[15])
unsigned long laserlatency;      // laser latency wrt cue (param[16]);
unsigned long laserduration;     // if ==1, session has laser turning on after reward for a duration equaling the delay between cue and reward (param[17]);
boolean randlaserflag;           // if ==1, session has laser turning on randomly for a duration equaling the delay between cue and reward (param[24]);
boolean lasertrialbytrialflag;   // if ==1, laser is turned on on a trial-by-trial basis(param[21])
boolean differentspeakerflag;    // if ==1, 3kHz tone is produced by a different speaker(param[25])
boolean framestate;              // state of frame input
boolean frameon;                 // did frame input turn on?



unsigned long T_bgd;             // inverse of the background rate of rewards =1/lambda (param[0])
unsigned long r_bgd;             // magnitude of background reward (param[1]); in pump duration
unsigned long t_fxd;             // delay to fixed reward (param[2])
unsigned long r_fxd;             // magnitude of fixed reward (param[3]); in pump duration
unsigned long meanITI;           // mean duration of ITI for the exponential distribution OR minimum ITI for uniform distribution (param[4])
unsigned long maxITI;            // maximum duration of ITI (param[5])
unsigned long cueDur;            // duration of cue (param[6])
unsigned long sessionLim;        // total number of CSs in seesion (param[7]) (including CS+ and CS-)
unsigned long mindelaybgdtocue;  // minimum delay between background reward and the following cue (param[8])
unsigned long mindelayfxdtobgd;  // minimum delay between fixed reward to the next background reward (param[9])
unsigned long numCSminus;        // number of CS- cues (param[10])
unsigned long CSplusfreq;        // frequency of CS+ cues (param[11])
unsigned long CSminusfreq;       // frequency of CS- cues (param[12])
unsigned long truncITI;          // truncation for the exponential ITI distribution: set at 3 times the meanITI or that hardcoded in maxITI
unsigned long totbgdrew;         // total number of background rewards if nocuesflag == 1, i.e. when only Poisson rewards are delivered. (param[20])
unsigned long laserpulseperiod;  // The period for which laser is on in a cycle (ms) (param[18]);
unsigned long laserpulseoffperiod;// The period for which laser is off in a cycle (ms) (param[19]); If equal to laserpulseperiod, duty cycle is 50%
unsigned long csplusprob;        // CS+ probability in % (param[22])
unsigned long csminusprob;       // CS- probability in % (param[23])
unsigned long lasertrainduration; // ADDED BY ITP April 2017 to support operant optogenetic experiments (param[37])

unsigned long ttloutdur = 100;   // duration that the TTL out pin for starting imaging lasts. This happens only for the case where ITI is uniformly distributed
unsigned long baselinedur = 7000;// Duration prior to CS to turn on imaging through TTLOUTPIN. Only relevant when ITI is uniformly distributed

unsigned long nextcue;           // timestamp of next trial
unsigned long nextbgdrew;        // timestamp of next background reward onset
unsigned long nextfxdrew;        // timestamp of next fixed reward onset
unsigned long nextlaser;         // timestamp of next laser
unsigned long pumpOff;           // timestamp to turn off pump
unsigned long cueOff;            // timestamp to turn off cues (after cue started)
unsigned long cuePulseOff;       // timestamp to pulse cue off (for CS-)
unsigned long cuePulseOn;        // timestamp to pulse cue on (for CS-)
unsigned long nextttlouton;      // timestamp to turn on the TTL out pin for starting imaging
unsigned long nextttloutoff;     // timestamp to turn off the TTL out pin for starting imaging
unsigned long laserPulseOn;      // timestamp to turn on the laser on while pulsing
unsigned long laserPulseOff;     // timestamp to turn the laser off while pulsing
unsigned long laserOff;          // timestamp to turn the laser off

unsigned long u;                 // uniform random number for inverse transform sampling to create an exponential distribution
unsigned long sessionendtime;    // the time at which session ends. Set to 5s after last fixed reward
float temp;                      // temporary float variable for temporary operations
float temp1;                     // temporary float variable for temporary operations
unsigned long tempu;

int CSct;                        // number of cues delivered
int numbgdrew;                   // number of background rewards delivered

int *cueList = 0;                // Using dynamic allocation for defining the cuelist. Be very very careful with memory allocation. All sorts of problems can come about if the program becomes too large. This is done just to be able to set #CSs from MATLAB
//int elements = 0;
unsigned long T_bgdvec[120];     // inverse of the background rate of rewards for each trial. This assumes that if background reward changes on a trial-by-trial basis, there are a total of 120 trials
//unsigned long T_bgdvecnonzero[60]; // all the non-zero elements of the bgd vecs. Every other trial has zero background reward rate. This vector will be shuffled later
int *Laserontrial = 0;             // Is there laser on any given trial?

// Variables for OC experiments, added by ITP Nov 2016.
int R_val = 0; // variable for reading the pin status for right operandum
int L_val = 0; // variable for reading the pin status for left operandum
int Rcounter = 0; // variable for counting the number of responses in right operandum
int Lcounter = 0; // variable for counting the number of responses in left operandum
int RcurrentState = 0; // current state of Right operandum
int LcurrentState = 0; // current state of Left operandum
int RpreviousState = 0; // previous state of Right operandum
int LpreviousState = 0; // previous state for Left operandum
int leftPT;// if ==1 FR schedule, if===2 PR schedule in effect on left lever (param[29])
int rightPT;// if ==1 FR schedule, if===2 PR schedule in effect on right lever (param[30])
unsigned long rightRecInc; // defines the number of responses required to obtain a reward (FR schedules), or the increment factor in PR schedules (param[31]) for Right operandum
unsigned long leftRecInc;// defines the number of responses required to obtain a reward (FR schedules), or the increment factor in PR schedules (param[32]) for left operandum
unsigned long leftRWmag; // defines how long the reward delivery mechanism will be active for (ms) for left lever (param[33])
unsigned long rightRWmag; // defines how long the reward delivery mechanism will be active for (ms) for right lever (param[34])
boolean OperantExperiment; // if==1, it is an opperant conditioning experiment (param[26])
boolean leftActive; // if==1, left lever will result R+ when response criterion is met, if==0, no R+ will be delivered (param[27])
boolean rightActive;// if==1 right lever will result in R+ when response criterion is met, if==0, no R+ will be delivered (param[28])
unsigned long trialNumLim;// the number of trials in the session (param[35])
unsigned long trialTimeLimit;// the max duration of the trial if no reward is harvested (param[36])
int TrialNum = 1; // Trial number in operant experiments, increases by a unit following a reward, or uppon reaching trial time limit
//unsigned long ITIc = 0; //counts the number of total time spent in ITIs in the session
unsigned long Tstart = 0; // timestamp at the begining of trial
unsigned long TUts = 0; //timestamp when trial timed up
unsigned long trialTime = 0; //time of trial
int TUid= 0; // enables TU loops
unsigned long TUtoneON = 0; // determines on time of speaker on in Time-up conditions
unsigned long TUITI = 0; // establishes ITI in time-up conditions
int MNid = 0; // enables manual reward loops
unsigned long MNts = 0; //timestamp when manual reward was delivered
unsigned long MNtoneON=0; // determines on time of speaker following manual reward
unsigned long MNITI=0; // establishes ITI in time-up conditions
unsigned long MNr_fxd=0; // determines on time for pump following "manual reward" press
int LRCid=0;// indicates if response criterion in left lever has been met
unsigned long LRCts=0; // timestamp when left response criterion was met
unsigned long LRCtoneON=0;// determines on time of speaker upon meeting left criterion
unsigned long LRCITI = 0; // establishes ITI in left reward conditions
unsigned long LRCRWmag = 0;// determines on time for pump following left response criterion
unsigned long LRCRWdelay= 0;// determines delay until pump on
unsigned long LRts= 0;// minimum time at which a next response can be recorded
unsigned long LBOD= 10000;// the duration of time out when left lever is inactive

int RRCid=0;// indicates if response criterion in left lever has been met
unsigned long RRCts=0; // timestamp when left response criterion was met
unsigned long RRCtoneON=0;// determines on time of speaker upon meeting left criterion
unsigned long RRCITI = 0; // establishes ITI in left reward conditions
unsigned long RRCRWmag = 0;// determines on time for pump following left response criterion
unsigned long RRCRWdelay= 0;// determines delay until pump on
unsigned long RRts= 0;// minimum time at which a next response can be recorded
unsigned long RBOD= 10000;// the duration of time out when left lever is inactive
unsigned long rp=0;//right press ts
unsigned long lp=0;//left press ts


// SETUP code ////////////////
void setup() {
  wdt_disable();                   // Disable watchdog timer on bootup. This prevents constant resetting by the watchdog timer in the endSession() function
  // initialize arduino states
  Serial.begin(9600);
  randomSeed(analogRead(0));       // Generate a random sequence of numbers every time
  pinMode(lick, INPUT);
  pinMode(pump, OUTPUT);
  pinMode(speaker, OUTPUT);
  pinMode(ttloutpin, OUTPUT);
  pinMode(laser, OUTPUT);
  pinMode(ttloutstoppin, OUTPUT);
  pinMode(framein, INPUT);
  pinMode(leftL, INPUT);
  pinMode(rightL, INPUT);
  pinMode(leftLED, OUTPUT);
  pinMode(rightLED, OUTPUT);
  pinMode(speakerpulse,OUTPUT);


  // import parameters
  while (Serial.available() <= 0) {}  // wait for signal from MATLAB
  getParams();

  reading = 0;

  //  The following block is for the case when you want to pulse the lower frequency stimulus
  //  if (CSplusfreq < CSminusfreq) {
  //    pulseCSplusorminus = 0;            // Pulse CSplus if CSplusfreq<CSminusfreq; here pulseCSplusorminus = 0;
  //  }
  //  else {
  //    pulseCSplusorminus = 1;            // Pulse CSminus if CSplusfreq>=CSminusfreq; here pulseCSplusorminus = 1;
  //  }

  while (reading != 53) {              // Before "Start" is pressed in MATLAB GUI
    reading = Serial.read();           //Key code sent from MATLAB; =51 for testing CS+, = 52 for testing CS-, =53 for starting session, =50 for turning solenoid on for r_fxd duration, =54 for turning solenoid on, =55 for turning solenoid off, =56 for testing laser
    if (reading == 51) {                       // Test CS+
      tone(speaker, CSplusfreq);               // turn on tone
      delay(1000);
      noTone(speaker);
    }

    if (reading == 52) {       // Test CS-
      if (differentspeakerflag == 1) {
        tone(speakerpulse, CSminusfreq);               // turn on tone
        delay(200);                               // Pulse with 200ms cycle
        noTone(speakerpulse);
        delay(200);
        tone(speakerpulse, CSminusfreq);               // turn on tone
        delay(200);                               // Pulse with 200ms cycle
        noTone(speakerpulse);
        delay(200);
        tone(speakerpulse, CSminusfreq);               // turn on tone
        delay(200);
        noTone(speakerpulse);
      }
      else {
        tone(speaker, CSminusfreq);               // turn on tone
        delay(200);                               // Pulse with 200ms cycle
        noTone(speaker);
        delay(200);
        tone(speaker, CSminusfreq);               // turn on tone
        delay(200);                               // Pulse with 200ms cycle
        noTone(speaker);
        delay(200);
        tone(speaker, CSminusfreq);               // turn on tone
        delay(200);
        noTone(speaker);
      }
    }

    if (reading == 50) {                 // MANUAL PUMP
      digitalWrite(pump, HIGH);          // turn on pump
      delay(r_fxd);
      digitalWrite(pump, LOW);           // turn off pump
    }

    if (reading == 54) {                 // PRIME SOLENOID
      digitalWrite(pump, HIGH);          // turn on pump
    }

    if (reading == 55) {                 // TURN OFF SOLENOID
      digitalWrite(pump, LOW);           // turn off pump
    }

    if (reading == 56) {                 // TEST LASER
      digitalWrite(laser, HIGH);         // turn on LASER
      delay(1000);
      digitalWrite(laser, LOW);         // turn off LASER
    }

  }

  // UNCOMMENT THESE LINES FOR TRIGGERING IMAGE COLLECTION AT BEGINNING
  digitalWrite(ttloutpin, HIGH);
  delay(100);
  digitalWrite(ttloutpin, LOW);
  // TILL HERE

  // start session
  start = millis();                    // start time
  nextttlouton = 0;
  nextttloutoff = 0;

  truncITI = min(3 * meanITI, maxITI); //truncation is set at 3 times the meanITI or that hardcoded in maxITI; used for exponential distribution
  u = random(0, 10000);
  temp = (float)u / 10000;
  if (expitiflag == 1) {               // generate exponential random numbers for itis
    temp1 = (float)truncITI / meanITI;
    temp1 = exp(-temp1);
    temp1 = 1 - temp1;
    temp = temp * temp1;
    temp = -log(1 - temp);
    nextcue    = (unsigned long)mindelaybgdtocue + meanITI * temp; // set timestamp of first cue
    //nextlaser  = nextcue;
  }
  else if (expitiflag == 0) {          // generate uniform random numbers for itis
    tempu = (unsigned long)(maxITI - meanITI) * temp;
    nextcue    = meanITI + tempu; // set timestamp of first cue
    nextttlouton = nextcue - baselinedur;
    //nextlaser  = nextcue;
  }
  if (randlaserflag == 1) {
    temp = nextcue - mindelaybgdtocue;
    nextlaser = random(0, temp);
  }

  u = random(0, 10000);
  temp = (float)u / 10000;
  temp = log(temp);
  if (trialbytrialbgdrewflag == 0) {
    nextbgdrew = 0 - T_bgd * temp;
  }
  else if (trialbytrialbgdrewflag == 1) {
    nextbgdrew = 0 - T_bgdvec[0] * temp;
  }
  if (nextbgdrew > (nextcue - mindelaybgdtocue) && !nocuesflag) {
    nextbgdrew = 0;
  }
  cueOff     = nextcue + cueDur;           // get timestamp of first cue cessation
  ITIflag = true;
  pumpOff = 0;
  //if (sessionLim != 0) {
  //  delete [] cueList;
  //}

  CSct = 0;                            // Number of CSs is initialized to 0
  numbgdrew = 0;                       // Number of background rewards initialized to 0
  sessionendtime = 0;


}

// LOOP code ////////////////

////Check if OC experiment and execute accordingly. Added by ITP Dec 2016.

void loop() {
  if (OperantExperiment == 1) {
    ts = millis() - start;               // find time since start
    reading = Serial.read();             // look for signals from MATLAB

   if (TUid!=3 and MNid!=4 and LRCid!=4 and RRCid!=4){
    digitalWrite(leftLED, HIGH);
    digitalWrite(rightLED, HIGH);

   }

   if (reading == 49) {                 // STOP BUTTON, END SESSION
      endSession();         
    }


    if (TrialNum <= trialNumLim) { // run for as long as the trial number limit is unreached
      licking();
//      frametimestamp();


trialTime=ts - Tstart;

//time up:

      if (trialTime > trialTimeLimit && TUid == 0 && LRCid==0) {
        
        TUid = 1;
        TUts = ts;
        TUtoneON = TUts + cueDur;
        TUITI = TUts + cueDur + meanITI;

        Serial.print(23); //indicates the trial limit was reached
        Serial.print(" ");
        Serial.print(ts);
        Serial.print(" ");
        Serial.print(1);//indicates the reward was not given
        Serial.print(" ");
        Serial.print(TrialNum); // indicates trial number
        Serial.print('\n');


      }
      if (trialTime > trialTimeLimit && ts <= TUtoneON && TUid==1 && LRCid==0) {
        tone(speakerpulse, CSminusfreq);
        Serial.print(6); //indicates the DS- was triggered
        Serial.print(" ");
        Serial.print(ts);
        Serial.print(" ");
        Serial.print(1);//indicates the reward was not given
        Serial.print(" ");
        Serial.print(TrialNum); // indicates trial number
        Serial.print('\n');
        TUid=2;
      }

      if (trialTime > trialTimeLimit && ts > TUtoneON && ts < TUITI && TUid==2 && LRCid==0 ) {
        noTone(speakerpulse);
        digitalWrite(leftLED, LOW);
        digitalWrite(rightLED, LOW);
        TUid=3;
      }

      if (trialTime > trialTimeLimit && ts > TUITI && TUid==3) {
        TrialNum = TrialNum + 1;
        Lcounter = 0;
        Rcounter = 0;
        TUid=0;
        digitalWrite(leftLED, HIGH);
        digitalWrite(rightLED, HIGH);
        Tstart = ts;
        Serial.print(80); //indicates the beggining of a new trial
        Serial.print(" ");
        Serial.print(Tstart);
        Serial.print(" ");
        Serial.print(1);//indicates the reward was not given
        Serial.print(" ");
        Serial.print(TrialNum); // indicates trial number
        Serial.print('\n');        
      }   //time up ends here
      

   //MAnual rewards   
if (reading == 50 && MNid==0 && LRCid==0 && RRCid==0 && TUid == 0) {                 // MANUAL PUMP
      MNid=1;
      MNts=ts;
      MNtoneON = MNts + cueDur;
      MNITI = MNts + cueDur + meanITI;
      MNr_fxd = MNts + cueDur + r_fxd;
      nextlaser=ts+laserlatency; //coment this line to omit laser for manual reward
      laserOff=ts+laserlatency+laserduration; //comment this line to omit laser for manual reward
      
      Serial.print(50); //indicates "manual reward" was pressed
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
        Serial.print(1);//indicates the reward was not given
        Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');}
      if (ts<=MNtoneON && MNid==1){
      tone(speaker, CSplusfreq);
                    
          Serial.print(5); //indicates the DS+ was triggered
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          MNid=2;}
          
       if(ts>MNtoneON && MNid==2){   
      noTone(speaker);
      digitalWrite(pump, HIGH);// turn on pump
      Serial.print(4); //indicates the pump was activated
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(0);//indicates the reward was given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
      MNid=3;}

      if(ts>=MNr_fxd && MNid==3){
            digitalWrite(pump, LOW); // turn off pump
                
          digitalWrite(leftLED, LOW);
          digitalWrite(rightLED, LOW);
          MNid=4;}
          
         if(ts>MNITI && MNid==4){
          TrialNum = TrialNum + 1; //start a new trial following reward delivery and ITI
          Lcounter = 0;
          Rcounter = 0;
          digitalWrite(leftLED, HIGH);
          digitalWrite(rightLED, HIGH);                   
          Tstart=ts;
          Serial.print(80); //indicates the beggining of a new trial
          Serial.print(" ");
          Serial.print(Tstart);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          MNid=0;}  
// Manual rewards ends here//

                  
                  /* Left operandum FR: input reading  */
     
        L_val = digitalRead(leftL); // read input value of left operandum
        if (ts<=2 && L_val == HIGH){ // avoid counting a false response if circuit is closed at the beginning of the session//
          LpreviousState = 1;
        }
        if (L_val == HIGH) { // check if the input is HIGH (operandum closes circuit)
          LcurrentState = 1;
        }
        else {
          LcurrentState = 0;
        }
      
      /* Left operandum: restricting response to press and release action, count the number of responses */
      if (LcurrentState != LpreviousState){
        
      if(LcurrentState==1 && ts>LRts) {
                   
        
          
           
      /* Left operandum: record response if the FR criterion has not been met */
           if (LRCid==0 && RRCid==0){
           
            tone(speaker, CSplusfreq, 20);    
          Serial.print(21); //indicates the left lever was pressed
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          Lcounter = Lcounter + 1;
         
          
           }
          if (LRCid!=0 || RRCid!=0){             
          Serial.print(212); //indicates the left lever was pressed, but not counted (i.e. durig CS+ or ITI,)
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          
           } 
          
          
      }  
      
      LpreviousState = LcurrentState;
      LRts=ts+20;
      }
      
        
        /* Left operandum: deliver reward and DS+ if the FR criterion is met */
        if (Lcounter>0 && Lcounter % leftRecInc == 0 && leftActive==1 && LRCid==0) {
          
      
      LRCid=1;
      LRCts=ts;
      LRCtoneON = LRCts + cueDur;
      LRCITI = LRCts + cueDur + meanITI;
      LRCRWmag = LRCts + t_fxd + leftRWmag;
      LRCRWdelay = LRCts + t_fxd;
      nextlaser=ts+laserlatency; //coment this line to omit laser for left lever
      laserOff=ts+laserlatency+laserduration; //comment this line to omit laser for left lever
      
                    
         
          tone(speaker, CSplusfreq);
          Serial.print(5); //indicates the DS+ was triggered
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          
          }

          //deliver liquid
if (Lcounter % leftRecInc == 0 && leftActive==1 && LRCid==1 && ts>=LRCRWdelay) {
          digitalWrite(pump, HIGH);
          Serial.print(4); //indicates the pump was activated
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(0);//indicates the reward was given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          LRCid=2;}
          
          if (Lcounter % leftRecInc == 0 && leftActive==1 && LRCid==2 && ts>=LRCRWmag) {
          digitalWrite(pump, LOW);
          digitalWrite(leftLED, LOW);
          digitalWrite(rightLED, LOW);
          LRCid=3;}

          if (ts >= nextlaser && nextlaser != 0 && laserduration > 0) {
      Serial.print(7);                         // code data as laser timestamp
      Serial.print(" ");
      Serial.print(ts);                        // send timestamp of laser
      Serial.print(" ");
      Serial.print(1);
      Serial.print(" ");
      Serial.print(TrialNum); // indicates trial number
      Serial.print('\n');
      digitalWrite(laser, HIGH);
      laserPulseOff = ts + laserpulseperiod;
      laserOff = ts + laserduration;
      nextlaser = 0;
    }

    
    // Pulse LASER
    if (ts >= laserPulseOff && laserPulseOff != 0 && ts < laserOff && laserduration > 0) {
      digitalWrite(laser, LOW);                   // turn off laser
      laserPulseOn = ts + laserpulseoffperiod;
      laserPulseOff = 0;
    }

    if (ts >= laserPulseOn && laserPulseOn != 0 && ts < laserOff && laserduration > 0) {
      digitalWrite(laser, HIGH);                   // turn on laser
      laserPulseOn = 0;
      laserPulseOff = ts + laserpulseperiod;
    }
          if(ts>=laserOff){
             digitalWrite(laser, LOW);  
          }
          
         if (Lcounter % leftRecInc == 0 && leftActive==1 && LRCid==3 && ts>=LRCtoneON) {
          noTone(speaker);
          LRCid=4;}

          

          if (Lcounter % leftRecInc == 0 && leftActive==1 && LRCid==4 && ts>LRCITI) {
           
          TrialNum = TrialNum + 1; //start a new trial following reward delivery and ITI
          Lcounter = 0;
          Rcounter = 0;
          Tstart=ts;
          if (leftPT== 2){
          leftRecInc=leftRecInc*2;}
          
          
          Serial.print(80); //indicates the beggining of a new trial
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          LRCid=0;
          RRCid=0;}// unblock right lever counter
// end active left lever criterion met loops         
//          
//        

 /* Left operandum innactive: deliver  DS- if the FR criterion is met */
        if (Lcounter>0 && Lcounter % leftRecInc == 0 && leftActive==0 && LRCid==0) {
      
          
      LRCid=1;
      LRCts=ts;
      LRCtoneON = LRCts + cueDur;
      LRCITI = LRCts + cueDur + LBOD;
      LRCRWmag = LRCts + t_fxd + leftRWmag;
      LRCRWdelay = LRCts + t_fxd;
          
          noTone(speaker);
          noTone(speakerpulse);
          tone(speakerpulse, CSminusfreq);
          
          Serial.print(6); //indicates the DS+ was triggered
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          
          }
          
          
         if (Lcounter % leftRecInc == 0 && leftActive==0 && LRCid==1 && ts>LRCtoneON) {
          
          noTone(speakerpulse);
          
          LRCid=3;}

//          if (Lcounter % leftRecInc == 0 && leftActive==0 && LRCid==2 && ts>=LRCtoneON) {
//          
//          
//          LRCid=3;}
          
          if (Lcounter % leftRecInc == 0 && leftActive==0 && LRCid==3 && ts<=LRCITI) {
          
          digitalWrite(leftLED, LOW);
          digitalWrite(rightLED, LOW);
          LRCid=4;}

          if (Lcounter % leftRecInc == 0 && leftActive==0 && LRCid==4 && ts>LRCITI) {
           
          TrialNum = TrialNum + 1; //start a new trial following reward delivery and ITI
          Lcounter = 0;
          Rcounter = 0;
          Tstart=ts;
          
          Serial.print(80); //indicates the beggining of a new trial
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          LRCid=0;
          RRCid=0;}// unblock right lever counter
// end inactive left lever criterion met loops




   /* Right operandum FR: input reading  */
      
        R_val = digitalRead(rightL); // read input value of right operandum
        if (ts<=2 && R_val == HIGH){ // avoid counting a false response if circuit is closed at the beginning of the session//
          RpreviousState = 1;
        }
        if (R_val == HIGH) { // check if the input is HIGH (operandum closes circuit)
          RcurrentState = 1;
        }
        else {
          RcurrentState = 0;
        }
      
      /* Right operandum: restricting response to press and release action, count the number of responses */
      if (RcurrentState != RpreviousState){
        
      if(RcurrentState==1 && ts>RRts) {
                   
        
          
           
      /* Right operandum: record response if the FR criterion has not been met */
           if (RRCid==0 && LRCid==0 ){
            
            tone(speaker, CSplusfreq/2, 20);    
          Serial.print(22); //indicates the left lever was pressed
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          Rcounter = Rcounter + 1;
          
          
           }
                if (RRCid!=0 || LRCid!=0) {             
          Serial.print(222); //indicates the left lever was pressed, but not counted (i.e. durig CS+ or ITI,)
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          
           } 
          
          
      }  
      
      RpreviousState = RcurrentState;
      RRts=ts+20;
      }
      
        
        /* Right operandum: deliver reward and DS+ if the FR criterion is met */
        if (Rcounter>0 && Rcounter % rightRecInc == 0 && rightActive==1 && RRCid==0) {
      LRCid=5; //block left reward counter    
      RRCid=1;
      RRCts=ts;
      RRCtoneON = RRCts + cueDur;
      RRCITI = RRCts + cueDur + meanITI;
      RRCRWmag = RRCts + t_fxd + rightRWmag;
      RRCRWdelay = RRCts + t_fxd;
      nextlaser=ts+laserlatency;// COMENT THIS LINE TO DISABLE LASER FOR RIGHT LEVER
      laserOff=ts+laserlatency+laserduration;
          
          
         
          
          tone(speaker, CSplusfreq);
          Serial.print(5); //indicates the DS+ was triggered
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          
          }

          if (Rcounter % rightRecInc == 0 && rightActive==1 && RRCid==1 && ts>=RRCRWdelay) {
          digitalWrite(pump, HIGH);
          Serial.print(4); //indicates the pump was activated
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(0);//indicates the reward was given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          RRCid=2;}
          
          if (Rcounter % rightRecInc == 0 && rightActive==1 && RRCid==2 && ts>=RRCRWmag) {
          digitalWrite(pump, LOW);
          digitalWrite(leftLED, LOW);
          digitalWrite(rightLED, LOW);
          RRCid=3;}

          if (ts >= nextlaser && nextlaser != 0 && laserduration > 0) {
      Serial.print(7);                         // code data as laser timestamp
      Serial.print(" ");
      Serial.print(ts);                        // send timestamp of laser
      Serial.print(" ");
      Serial.print(1);
      Serial.print(" ");
      Serial.print(TrialNum); // indicates trial number
      Serial.print('\n');
      digitalWrite(laser, HIGH);
      laserPulseOff = ts + laserpulseperiod;
      laserOff = ts + laserduration;
      nextlaser = 0;
    }
    
    // Pulse LASER
    if (ts >= laserPulseOff && laserPulseOff != 0 && ts < laserOff && laserduration > 0) {
      digitalWrite(laser, LOW);                   // turn off laser
      laserPulseOn = ts + laserpulseoffperiod;
      laserPulseOff = 0;
    }

    if (ts >= laserPulseOn && laserPulseOn != 0 && ts < laserOff && laserduration > 0) {
      digitalWrite(laser, HIGH);                   // turn on laser
      laserPulseOn = 0;
      laserPulseOff = ts + laserpulseperiod;

    }

    if(ts>=laserOff){
             digitalWrite(laser, LOW);  
          }
          
          
         if (Rcounter % rightRecInc == 0 && rightActive==1 && RRCid==3 && ts>=RRCtoneON) {
          noTone(speaker);
          RRCid=4;}

          

          if (Rcounter % rightRecInc == 0 && rightActive==1 && RRCid==4 && ts>RRCITI) {
           
          TrialNum = TrialNum + 1; //start a new trial following reward delivery and ITI
          Lcounter = 0;
          Rcounter = 0;
          Tstart=ts;
          if (rightPT== 2){
          rightRecInc=rightRecInc*2;}
          
          Serial.print(80); //indicates the beggining of a new trial
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          RRCid=0;
          LRCid=0;} //unblock left reward counter
// end active right lever criterion met loops         
//          
//        

 /* Right operandum innactive: deliver  DS- if the FR criterion is met */
        if (Rcounter>0 && Rcounter % rightRecInc == 0 && rightActive==0 && RRCid==0) {

          
      RRCid=1;
      RRCts=ts;
      RRCtoneON = RRCts + cueDur;
      RRCITI = RRCts + cueDur + RBOD;
      RRCRWmag = RRCts + t_fxd + rightRWmag;
      RRCRWdelay = RRCts + t_fxd;
          
          noTone(speaker);
          noTone(speakerpulse);
          tone(speakerpulse, CSminusfreq);
          
          Serial.print(6); //indicates the DS+ was triggered
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          
          }
          
          
         if (Rcounter % rightRecInc == 0 && rightActive==0 && RRCid==1 && ts>RRCtoneON) {
          
          noTone(speakerpulse);          
          RRCid=3;}


          if (Rcounter % rightRecInc == 0 && rightActive==0 && RRCid==3 && ts<=RRCITI) {
          
          digitalWrite(leftLED, LOW);
          digitalWrite(rightLED, LOW);
          RRCid=4;}

          if (Rcounter % rightRecInc == 0 && rightActive==0 && RRCid==4 && ts>RRCITI) {
           
          TrialNum = TrialNum + 1; //start a new trial following reward delivery and ITI
          Lcounter = 0;
          Rcounter = 0;
          Tstart=ts;
          
          Serial.print(80); //indicates the beggining of a new trial
          Serial.print(" ");
          Serial.print(ts);
          Serial.print(" ");
          Serial.print(1);//indicates the reward was not given
          Serial.print(" ");
          Serial.print(TrialNum); // indicates trial number
          Serial.print('\n');
          RRCid=0;} //unblock right response counter
// end of inactive right lever criterion met loops
      
    
    
      
    }// closes trial number loop

    if (TrialNum > trialNumLim) { // end session and stop experiment when the trial number limit is reached
      digitalWrite(leftLED, LOW);
      digitalWrite(rightLED, LOW);
      endSession(); 
      
    }
    
  }// closes "if" operant loop
}//closes void loop

// Accept parameters from MATLAB
void getParams() {
  int pn = 37;                              // number of parameter inputs
  unsigned long param[pn];                  // parameters

  for (int p = 0; p < pn; p++) {
    reading = Serial.parseInt();           // read parameter
    param[p] = reading;                    // convert to int
  }
  reading = 0;

  T_bgd                  = param[0];                   // get T=1/lambda, in ms
  r_bgd                  = param[1];                   // get r_bgd, ms open time for the pump
  t_fxd                  = param[2];                   // get delay to fixed reward, in ms
  r_fxd                  = param[3];                   // get magnitude of fixed reward
  meanITI                = param[4];                   // get meanITI, in ms
  maxITI                 = param[5];                   // get maxITI, in ms
  cueDur                 = param[6];                   // get cue duration, in ms
  sessionLim             = param[7];                   // get CS limit
  mindelaybgdtocue       = param[8];                   // get minimum delay between a background reward and the next cue, in ms
  mindelayfxdtobgd       = param[9];                   // get minimum delay between a fixed reward and the next background reward, in ms
  numCSminus             = param[10];                  // get number of CS- trials
  CSplusfreq             = param[11];                  // get frequency of CS+ tone
  CSminusfreq            = param[12];                  // get frequency of CS- tone
  nocuesflag             = (boolean)param[13];
  trialbytrialbgdrewflag = (boolean)param[14];
  expitiflag             = (boolean)param[15];
  laserlatency           = param[16];                  // latency wrt to cue
  laserduration          = param[17];
  laserpulseperiod       = param[18];                  // laser on pulse duration
  laserpulseoffperiod    = param[19];                  // laser pulse off period
  totbgdrew              = param[20];                  // total number of background rewards to stop the session if the session just has Poisson rewards, i.e. nocuesflag == 1
  lasertrialbytrialflag  = (boolean)param[21];         // laser on a trial-by-trial basis?
  csplusprob             = param[22];                  // CS+ probability in %
  csminusprob            = param[23];                  // CS- probability in %
  randlaserflag          = (boolean)param[24];         // Random laser flag
  differentspeakerflag   = (boolean)param[25];         // Different speaker for pulsing tone or not
  //Added by ITP for Operant conditioning. Nov-Dec 2016
  OperantExperiment      = (boolean)param[26];       // flag for operant experiment
  leftActive             = (boolean)param[27];       // flag for active left operandum. If false, responses will not be rewarded
  rightActive            = (boolean)param[28];       // flag for active right operandum. If false, responses will not be rewarded
  leftPT                 = param[29];                // Deetermines type of schedule for left lever. 1 for FR, 2 for PR
  rightPT                = param[30];                // Deetermines type of schedule for right lever. 1 for FR, 2 for PR
  leftRecInc             = param[31];                // the requierd response ratio (for FR) or response increment factor (for PR) for left lever
  rightRecInc            = param[32];                // the requierd response ratio (for FR) or response increment factor (for PR) for right lever
  leftRWmag              = param[33];                // reward magnitude for left operandum
  rightRWmag             = param[34];                // reward magnitude for right operandum
  trialNumLim            = param[35];                // total number of trials in an operant session
  trialTimeLimit         = param[36];                // time limit for each operant trial
  

  CSplusfreq = CSplusfreq * 1000;          // convert frequency from kHz to Hz
  CSminusfreq = CSminusfreq * 1000;        // convert frequency from kHz to Hz

}

// Check lick status //////
void licking() {
  boolean prevLick;

  prevLick  = lickState;                   // record previous lick state
  lickState = digitalRead(lick);           // record new lick state
  licked    = lickState > prevLick;        // determine if lick occured
  lickwithdrawn = lickState < prevLick;    // determine if lick was withdrawn

  if (OperantExperiment == 1) {

    if (licked) {                            // if lick
      Serial.print(1);                       //   code data as lick timestamp
      Serial.print(" ");
      Serial.print(ts);                      //   send timestamp of lick
      Serial.print(" ");
      Serial.print(1);//indicates the reward was not given
      Serial.print(" ");
      Serial.print(TrialNum);
      Serial.print('\n');

    }

    if (lickwithdrawn) {                     // if lick withdrawn
      Serial.print(2);                       //   code data as lick withdrawn timestamp
      Serial.print(" ");
      Serial.print(ts);                      //   send timestamp of lick
      Serial.print(" ");
      Serial.print(1);//indicates the reward was not given
      Serial.print(" ");
      Serial.print(TrialNum);
      Serial.print('\n');
    }
  }
  if (OperantExperiment == 0) {

    if (licked) {                            // if lick
      Serial.print(1);                       //   code data as lick timestamp
      Serial.print(" ");
      Serial.print(ts);                      //   send timestamp of lick
      Serial.print(" ");
      Serial.print(0);
      Serial.print('\n');

    }

    if (lickwithdrawn) {                     // if lick withdrawn
      Serial.print(2);                       //   code data as lick withdrawn timestamp
      Serial.print(" ");
      Serial.print(ts);                      //   send timestamp of lick
      Serial.print(" ");
      Serial.print(0);
      Serial.print('\n');
    }
  }

}

//void frametimestamp() {
//  boolean prevframe;
//  prevframe = framestate;
//  framestate = digitalRead(framein);
//  frameon = framestate > prevframe;
//
//  if (frameon) {
//    Serial.print(9);                       //   code data as frame timestamp
//    Serial.print(" ");
//    Serial.print(ts);                      //   send timestamp of frame
//    Serial.print(" ");
//    Serial.print(0);
//    Serial.print('\n');
//  }
//
//}


// DELIVER CUE //////////////
//void cues() {
//  if (cueList[CSct] == 0) {
//    Serial.print(5);                         // code data as CS+ timestamp
//    Serial.print(" ");
//    Serial.print(ts);                        // send timestamp of cue
//    Serial.print(" ");
//    Serial.print(0);
//    Serial.print('\n');
//    tone(speaker, CSplusfreq);               // turn on tone
//    cuePulseOff = 0;                         // No cue pulsing
//    cuePulseOn = 0;                          // No cue pulsing
//  }
//  else if (cueList[CSct] == 1) {
//    Serial.print(6);                         // code data as CS- timestamp
//    Serial.print(" ");
//    Serial.print(ts);                        // send timestamp of cue
//    Serial.print(" ");
//    Serial.print(0);
//    Serial.print('\n');
//    if (differentspeakerflag == 1) {
//      tone(speakerpulse, CSminusfreq);              // turn on CS- tone
//    }
//    else {
//      tone(speaker, CSminusfreq);              // turn on CS- tone
//    }
//    cuePulseOff = ts + 200;                  // No cue pulsing
//    cuePulseOn = 0;                          // No cue pulsing
//  }
//
//  nextfxdrew = ts + t_fxd;                 // next fixed reward comes at a fixed delay following cue onset
//  cueOff  = ts + cueDur;                   // set timestamp of cue cessation
//}

void deliverlasertocues() {
//  if (lasercueflag == 1 && lasertrialbytrialflag == 0) {  // If laser should be turned on during cue-reward delay for the whole session
//    Serial.print(7);                         // code data as laser timestamp
//    Serial.print(" ");
//    Serial.print(ts);                        // send timestamp of cue
//    Serial.print(" ");
//    Serial.print(0);
//    Serial.print('\n');
//    digitalWrite(laser, HIGH);
//    laserPulseOff = ts + laserpulseperiod;
//    laserOff = ts + t_fxd;
//    nextlaser = 0;
//  }
//  else if (lasercueflag == 1 && lasertrialbytrialflag == 1) {
//    if (Laserontrial[CSct] == 1) {
//      Serial.print(7);                         // code data as laser timestamp
//      Serial.print(" ");
//      Serial.print(ts);                        // send timestamp of cue
//      Serial.print(" ");
//      Serial.print(0);
//      Serial.print('\n');
//      digitalWrite(laser, HIGH);
//      laserPulseOff = ts + laserpulseperiod;
//      laserOff = ts + t_fxd;
//      nextlaser = 0;
//    }
//  }
}

void software_Reboot()
{
  wdt_enable(WDTO_500MS);
  while (1)
  {
  }
  wdt_reset();
}

// End session //////////////
void endSession() {
  digitalWrite(ttloutstoppin, HIGH);
  delay(100);
  digitalWrite(ttloutstoppin, LOW);
  Serial.print(0);                       //   code data as end of session
  Serial.print(" ");
  Serial.print(ts);                      //   send timestamp
  Serial.print(" ");
  Serial.print(0);
  Serial.print('\n');

  digitalWrite(pump, LOW);                 //  turn off pump
  noTone(speaker);                         //  turn off tone
  delay(100);                              //  wait
  //while(1){}                               //  Stops executing the program
  //asm volatile (" jmp 0");                 //  reset arduino; this is unclean and doesn't reset the hardware
  delete [] cueList;
  int *cueList = 0;
  delete [] Laserontrial;
  int *Laserontrial = 0;
  software_Reboot();

}

  

      

