//+------------------------------------------------------------------+
//|   Mokuro89 SMI Alerts & Arrows                                   |
//|   Based On William Blau & Mladen SMI                             |
//|                                                                  |
//|   Copyright © 2016 / mokuro89@gmail.com                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "2016-2017, Mokuro89."
#property link        "mokuro89@gmail.com"

//------------------------------------------------------------------

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1  Lime
#property indicator_width1  2
#property indicator_color2  Red
#property indicator_width2  2

extern string  sideString="-------- 0-OFF 1-BEARS 2-BULLS --------";
extern int     side=0;
extern bool    AlertsOnlySelectedPairs=true;

extern int     Length=2;//15?
extern int     Smooth1     = 3;
extern int     Smooth2     = 3;
extern int     Signal      = 3;
extern int     Price       = PRICE_CLOSE;
extern double  OverBought1 =  60; //48.2
extern double  OverSold1   = -60; //-48.2
extern bool    AlertsOn                    = True;
extern bool    AlertsOnCurrent             = False;
extern bool    AlertsMessage               = false;
extern bool    AlertsNotification          = True;
extern bool    AlertsEmail                 = False;
extern bool    AlertsSound                 = False;
extern bool    ShowArrows=True;
extern bool    UseZigZag=True;
extern string  ZigZagSettings="--ZigZagSettings--";
extern int     InpDepth=55;     // Depth
extern int     InpDeviation=5;  // Deviation
extern int     InpBackstep=3;   // Backstep

double  ArrowDisplacement           = 1.0;
int     ArrowsUpCode                = 233;
int     ArrowsDnCode                = 234;

double smo[];
double sms[];
double tBuffer[][6];
double smoUa[];
double smoUb[];
double smoDa[];
double smoDb[];
double state[];
double trend[];
double BuySignal[];
double SellSignal[];
double PositionSignals[];
double orderTypes[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int init()
  {

   IndicatorBuffers(12);
   SetIndexBuffer(0,BuySignal);  SetIndexStyle(0,DRAW_ARROW,EMPTY,1);  SetIndexArrow(0,ArrowsUpCode);
   SetIndexBuffer(1,SellSignal); SetIndexStyle(1,DRAW_ARROW,EMPTY,1);  SetIndexArrow(1,ArrowsDnCode);

   SetIndexBuffer(2,smo);        SetIndexLabel(2,NULL);
   SetIndexBuffer(3,sms);        SetIndexLabel(3,NULL);
   SetIndexBuffer(4,smoUa);      SetIndexLabel(4,NULL);
   SetIndexBuffer(5,smoUb);      SetIndexLabel(5,NULL);
   SetIndexBuffer(6,smoDa);      SetIndexLabel(6,NULL);
   SetIndexBuffer(7,smoDb);      SetIndexLabel(7,NULL);

   SetIndexBuffer(8,state);      SetIndexLabel(8,NULL);
   SetIndexBuffer(9,trend);      SetIndexLabel(9,NULL);
   SetIndexBuffer(10,PositionSignals);      SetIndexLabel(10,NULL);
   SetIndexBuffer(11,orderTypes);      SetIndexLabel(11,NULL);

   string PriceType;
   switch(Price)
     {
      case PRICE_CLOSE:    PriceType = "Close";    break;  // 0
      case PRICE_OPEN:     PriceType = "Open";     break;  // 1
      case PRICE_HIGH:     PriceType = "High";     break;  // 2
      case PRICE_LOW:      PriceType = "Low";      break;  // 3
      case PRICE_MEDIAN:   PriceType = "Median";   break;  // 4
      case PRICE_TYPICAL:  PriceType = "Typical";  break;  // 5
      case PRICE_WEIGHTED: PriceType = "Weighted"; break;  // 6
     }

   Length  = MathMax(Length ,1);
   Smooth1 = MathMax(Smooth1,1);
   Smooth2 = MathMax(Smooth2,1);
   IndicatorShortName(" Stochastic Momentum ("+Length+","+Smooth1+","+Smooth2+","+PriceType+")");

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#define ema10 0
#define ema11 1
#define ema12 2
#define ema20 3
#define ema21 4
#define ema22 5
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
  
  
  
   if(StringFind(Symbol(),"JPY")>-1)
     {
      int _2Real=100;}else{_2Real=10000;
     }
   int counted_bars=IndicatorCounted();
   int i2,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   limit=MathMin(Bars-counted_bars,Bars-1);

   if(ArrayRange(tBuffer,0)!=Bars) ArrayResize(tBuffer,Bars);

   double alpha1 = 2.0 /(1.0+Smooth1);
   double alpha2 = 2.0 /(1.0+Smooth2);
   double alphas = 2.0 /(1.0+Signal);

   for(i2=limit,r=Bars-i2-1; i2>=0; i2--,r++)
     {
      double hh = High[iHighest(NULL,0,MODE_HIGH,Length,i2)];
      double ll =  Low[ iLowest(NULL,0,MODE_LOW ,Length,i2)];
      double pr = iMA(NULL,0,1,0,MODE_SMA,Price,i2);

      tBuffer[r][ema10] = pr - 0.5*(hh+ll);
      tBuffer[r][ema20] =           hh-ll;
      if(i2>=Bars-3)
        {
         tBuffer[r][ema11] = tBuffer[r][ema10];
         tBuffer[r][ema12] = tBuffer[r][ema10];
         tBuffer[r][ema21] = tBuffer[r][ema20];
         tBuffer[r][ema22] = tBuffer[r][ema20];
         continue;
        }

      tBuffer[r][ema11] = tBuffer[r-1][ema11] + alpha1*(tBuffer[r][ema10]-tBuffer[r-1][ema11]);
      tBuffer[r][ema12] = tBuffer[r-1][ema12] + alpha2*(tBuffer[r][ema11]-tBuffer[r-1][ema12]);
      tBuffer[r][ema21] = tBuffer[r-1][ema21] + alpha1*(tBuffer[r][ema20]-tBuffer[r-1][ema21]);
      tBuffer[r][ema22] = tBuffer[r-1][ema22] + alpha2*(tBuffer[r][ema21]-tBuffer[r-1][ema22]);

      smo[i2]=100.00*tBuffer[r][ema12]/(0.5*tBuffer[r][ema22]);

      if(Signal>1)
         sms[i2]=sms[i2+1]+alphas*(smo[i2]-sms[i2+1]);
     }

   for(i2=limit; i2>=0; i2--)
     {

      BuySignal[i2]  = EMPTY_VALUE;
      SellSignal[i2] = EMPTY_VALUE;
      PositionSignals[i2]=EMPTY_VALUE;
      trend[i2]=trend[i2+1];

      if(smo[i2] >  sms[i2]) trend[i2] =  1;
      if(smo[i2] <  sms[i2]) trend[i2] = -1;
      if(smo[i2]==sms[i2]) trend[i2]=0;

      double gap=ArrowDisplacement*iATR(NULL,0,100,i2);
      int zigzagBuffer=iCustom(NULL,0,"ZigZag",InpDepth,InpDeviation,InpBackstep,i2);
      bool buyArrowSent=false;
      bool sellArrowSent=false;
      if(ShowArrows)
        {
         if((trend[i2]!=trend[i2+1]) && (trend[i2]==1) && (smo[i2]<OverSold1 || (smo[i2+1]<OverSold1 && sms[i2+1]<OverSold1)))
           {
            if(UseZigZag)
              {
               if(zigzagBuffer==2)
                 {
                  BuySignal[i2]=Low[i2]-gap;
                  buyArrowSent = true;
                 }
                 }else{
               BuySignal[i2]=Low[i2]-gap;
               buyArrowSent = true;
              }
           }
         if((trend[i2]!=trend[i2+1]) && (trend[i2]==-1) && (smo[i2]>OverBought1 || (smo[i2+1]>OverBought1 && sms[i2+1]>OverBought1)))
           {
            if(UseZigZag)
              {
               if(zigzagBuffer==1)
                 {
                  SellSignal[i2]=High[i2]+gap;
                  sellArrowSent = true;
                 }
                 }else{
               SellSignal[i2]=High[i2]+gap;
               sellArrowSent = true;
              }
           }
        }

      if(AlertsOn)
        {
         if(AlertsOnCurrent)
            int whichBar = 0;
         else   whichBar = 1;

         if(trend[whichBar]!=trend[whichBar+1])
           {
            int iterationValue= 0;
            if(trend[whichBar]==1 &&(smo[whichBar]<OverSold1||(smo[whichBar+1]<OverSold1 && sms[whichBar+1]<OverSold1)))
              {

               if(UseZigZag)//BULLS
                 {
                  if(buyArrowSent)
                    {
                     doAlert(whichBar,"MA Cross Up",1);
                     iterationValue=i2;
                    }

                    } else {
                  doAlert(whichBar,"MA Cross Up",1);
                  iterationValue=i2;
                 }

               if(iterationValue!=0)
                 {
                  PositionSignals[i2]=i2;
                  orderTypes[i2]=1;
                 }
              }
            if(trend[whichBar]==-1 && (smo[whichBar]>OverBought1 || (smo[whichBar+1]>OverBought1 && sms[whichBar+1]>OverBought1)))
              {
               if(UseZigZag)//BEARS
                 {
                  if(sellArrowSent)
                    {
                     iterationValue=i2;
                     doAlert(whichBar,"MA Cross Down",-1);
                    }
                    }else{
                  iterationValue=i2;
                  doAlert(whichBar,"MA Cross Down",-1);
                 }

               if(iterationValue!=0)
                 {
                  PositionSignals[i2]=i2;
                  orderTypes[i2]=-1;
                 }
              }
            
           }
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void doAlert(int forBar,string doWhat,int sides)
  {
   
   if(IsTesting()){
      return(0);
   }
   
   static string   previousAlert="Nothing";
   static datetime previousTime;
   string message;
   string timeframe;
   string AlertSellPairs;
   string AlertBuyPairs;

   if(previousAlert!=doWhat || previousTime!=Time[forBar])
     {
      previousAlert  = doWhat;
      previousTime   = Time[forBar];

      message=StringConcatenate(Symbol()," "+doWhat);

      bool sendMessage=true;
      int Handle;                          // Style of vertical line
      string File_Name="Mokuro_Alert_config.csv";        // Name of the file
      string text;

      //--------------------------------------------------------------- 3 --
      Handle=FileOpen(File_Name,FILE_CSV|FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE,";");// File opening
      if(Handle<0) // File opening fails
        {
         if(GetLastError()==4103) // If the file does not exist,..
            Alert("No file named ",File_Name);//.. inform trader
         else                             // If any other error occurs..
         Alert("Error while opening file ",File_Name);//..this message
         //PlaySound("Bzrrr.wav");          // Sound accompaniment
         return(0);                          // Exit start()      
        }
      //--------------------------------------------------------------- 4 --
      while(FileIsEnding(Handle)==false)  // While the file pointer..
        {                                 // ..is not at the end of the file
         //--------------------------------------------------------- 5 --
         text=FileReadString(Handle);// Date and time of the event (date)
         if(StringFind(text,"//",0)!=-1)
           {
            continue;
           }
         if(StringFind(text,"BEARS",0)!=-1)
           {
            AlertSellPairs=text;
           }
         if(StringFind(text,"BULLS",0)!=-1)
           {
            AlertBuyPairs=text;
           }
        }
      FileClose(Handle);                // Close file
                                        //WindowRedraw(); 
      if(AlertsOnlySelectedPairs)
        {
         sendMessage=false;

         if(sides==-1)
           {
            if((StringFind(AlertSellPairs,Symbol(),0)!=-1))
              {
               sendMessage=true;
              }

           }
         if(sides==1)
           {
            if((StringFind(AlertBuyPairs,Symbol(),0)!=-1))
              {
               sendMessage=true;
              }

           }
        }
      if(sendMessage)
        {
         if(AlertsMessage) Alert(message);
         if(AlertsNotification) SendNotification(message);
         if(AlertsEmail) SendMail(StringConcatenate(Symbol(),"SMI "),message);
         if(AlertsSound) PlaySound("alert2.wav");
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
