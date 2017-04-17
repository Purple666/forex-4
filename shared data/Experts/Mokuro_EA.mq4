//+------------------------------------------------------------------+
//|   Mokuro89 Expert                                                |
//|                                                                  |
//|   Copyright © 2016 / mokuro89@gmail.com                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "2016-2017, Mokuro89."
#property link        "mokuro89@gmail.com"

//to use with ATRPeriods
bool           useMinimalDistance=true;
extern bool    sendNotifications=true;
extern ENUM_TIMEFRAMES ATRperiod;
extern double  Lts=0.01;
extern bool    useLtsPercentSL=false;
extern bool    ATRStopLoss=true;
extern bool    BasketSameStopLoss=true;
extern bool    BreakEvenMode=false;
extern double  ATRMinDistanceMultiplier=0.5;
extern double  ATRTakeProfitMultiplier=0.5;
extern double  ATRStopLossMultiplier=5;
extern double  ATRBasketTPMultiplier=0.5;
extern double  ATRBasketBreakEvenMultiplier=0.1;

extern string   DATEFORMAT="DATEFORMAT EXAMPLE: 2017.03.01 09:00";
extern string  StrategyTesterDateFrom="";
extern string  StrategyTesterDateTo="";
extern bool    HAChangeColourBE=false;
bool    useZigZag=false;
double  ZigZagDepth=55;

//STRATEGY TESTER

//GANN
extern bool    useAutoTrading=false;
extern bool    useGANN=false;
extern ENUM_TIMEFRAMES  GANNTimeFrame=PERIOD_D1;
extern double  GANNperiod=5;
extern bool    useGANNMX=true;
extern ENUM_TIMEFRAMES gannMXTimeFrame=PERIOD_M5;
extern double  gannMXperiod=5;
bool    useGANNHTF=false;
int     gannHTFPeriod01=240;
int     gannHTFPeriod02=1440;
int     gannHTFPeriod03=10080;
double  GANNChannelperiod=5;
bool    GANNChannelSendOrders=true;
extern bool    useGANNChannelAutoClose=false;
bool    useGANNAutoSide=false;
bool    useGANNAutoClose=false;

bool    useTripleTFGannSide=false;
bool    useTDICross=false;
bool    useTDICrossHTF=false;
int     TDICrossHTFPeriod01=240;
int     TDICrossHTFPeriod02=1440;
int     TDICrossHTFPeriod03=10080;
//QUANTUM
//extern bool    useQuantum=false;
//extern int     quantumDepth=55;
bool    useRenkoStochAlert=false;
int     Length      = 2;
int     Smooth1     = 3;
int     Smooth2     = 3;
int     Signal      = 3;
int     Price       = PRICE_CLOSE;
double  OverBought1 =  60;
double  OverSold1   = -60;
//incremental lot

extern bool    useIncrementalLot=false;
extern double  incrementalLotMultiplier=0.5;

double  ArrowDisplacement           = 1.0;
int     ArrowsUpCode                = 233;
int     ArrowsDnCode                = 234;
/////////////

extern bool   SendOrders=true;
string AlertSellPairs=""; //AUDJPY;AUDUSD;
string AlertBuyPairs="";

int
Total,                           // Amount of orders in a window 
Tip=-1,                          // Type of selected order (B=0,S=1)
TotalOrders=20,                  // Max number of orders
Ticket;                          // Order number
double
Lot,// Amount of lots in a selected order
    // Amount of lots in an opened order
Min_Lot,                         // Minimal amount of lots
Step,                            // Step of lot size change
Free,                            // Current free margin
One_Lot,                         // Price of one lot
                                 //Price,                           // Price of a selected order
SL,                              // SL of a selected order
TP;                              // TP за a selected order
bool
Ans=false;                     // Server response after closing

double smo[];
double sms[];
double tBuffer[][6];
double smoUa[];
double smoUb[];
double smoDa[];
double smoDb[];
double state[];
double BuySignal[];
double SellSignal[];
double ATRPips;
double tickvalue;
//--------------------------------------------------------------- 2 --
double trend[];
//--------------------------------------------------------------- 2 --
#define ema10 0
#define ema11 1
#define ema12 2
#define ema20 3
#define ema21 4
#define ema22 5
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  StopLossPercent=1;

int     pips2points;    // slippage  3 pips    3=points    30=points
double  pips2dbl;       // Stoploss 15 pips    0.015      0.0150
int     pips;    // DoubleToStr(dbl/pips2dbl, Digits.pips)
int pipMult=10000;
int manageOrders=0,useM30RSI=0,useRunner=0,offlineMode=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {
   if(Digits%2==1)
     {      // DE30=1/JPY=3/EURUSD=5 forum.mql4.com/43064#515262
      pips2dbl=Point*10; pips2points=10;   pips=1;
        } else {    pips2dbl=Point;    pips2points=1;   pips=0;
     }
   if(StringFind(Symbol(),"JPY",0)!=-1)
     {
      pipMult=100;
     }
   ATRPips=MathCeil(pipMult *(iATR(NULL,ATRperiod,100,0)));

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {

   if(Time[0]>=StrToTime("2018.01.01 00:00"))
     {
      return(0);
     }
// Orders accounting
   Total=0;
   int Handle;                          // Style of vertical line
   string File_Name="Mokuro_EA_config.csv";        // Name of the file
   string text;
   AlertSellPairs=NULL;
   AlertBuyPairs=NULL;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!IsTesting())
     {
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
         if(StringFind(text,Symbol(),0)!=-1)
           {
            //declare variables used later
            string to_split=text;   // A string to split into substrings
            string sep="_";                // A separator as a character
            ushort u_sep;                  // The code of the separator character
            string result[];               // An array to get strings
            //--- Get the separator code
            u_sep=StringGetCharacter(sep,0);
            //--- Split the string to substrings
            int k=StringSplit(to_split,u_sep,result);
            //--- Show a comment 
            //////Printformat("Strings obtained: %d. Used separator '%s' with the code %d",k,sep,u_sep);
            //--- Now output all obtained strings
            if(k>0)
              {
               //result[0] -> SYMBOL
               //result[1] -> BULLS/BEARS
               if(result[1]=="BEARS")
                 {
                  AlertSellPairs=Symbol();
                 }
               else if(result[1]=="BULLS")
                 {
                  AlertBuyPairs=Symbol();
                 }

               if(useGANNAutoSide)
                 {   ///GANNNN
                  AlertBuyPairs=Symbol();
                  AlertSellPairs=Symbol();
                 }
               //result[2] -> SL in % of equity
               StopLossPercent=result[2];

               //Manage orders - 0 false, 1 true
               manageOrders=1;

               //Only send orders if RSI cross 50lvl
               //useM30RSI=result[4];
               BreakEvenMode=result[3];//useM30RSI=0;

                                       //useRunner=result[4];

               //OFFLINE-MODE
               //offlineMode=result[5];

              }
           }
        }
      FileClose(Handle);                // Close file
     }
   else
     {
      AlertSellPairs=Symbol();
      AlertBuyPairs=Symbol();
      StopLossPercent=1;
      manageOrders=1;
     }
//--------------------------------------------------------------- 8 --
//--------------------------------------------------------------- 5 --

   if(offlineMode==1)
     {
      bool offline=manageOfflineMode();
      if(offline)
        {
         return(0);
        }
     }

// Trading criteria
   int counted_bars=IndicatorCounted();
   int limit;

   tickvalue=(MarketInfo(Symbol(),MODE_TICKVALUE));
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Digits==5 || Digits==3)
     {
      tickvalue=tickvalue*10;
     }

//if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   limit=MathMin(Bars-counted_bars,Bars-1);
   if(ArrayRange(tBuffer,0)!=Bars) ArrayResize(tBuffer,Bars);

   if(useRenkoStochAlert)
     {
      double buySignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,0,1);
      double sellSignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,1,1);
      double positionSignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,10,1);
      double orderTypes=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,11,1);

      if(orderTypes==1) doStuff(1,"MA Cross Up",1);//&& positionSignal == i2
      if(orderTypes==-1) doStuff(1,"MA Cross Down",-1);
     }

   int sendOrder=0;

   if(useGANNMX)
     {
      double gannMX=iCustom(NULL,gannMXTimeFrame,"GannHiLo-Histo",gannMXperiod,2,1); //0 atualcadle , 1 last candle
                                                                                     //gannMX==1?sendOrder=1:sendOrder=sendOrder;
      //gannMX==-1?sendOrder=-1:sendOrder=sendOrder;
      if(gannMX==1)//&&dRSIPriceLine0>dTradeSignalLine0 //

        {
         //closeAll(-1);
         sendOrder=1;//&& positionSignal == i2

        }
      if(gannMX==-1)//&&dRSIPriceLine0<dTradeSignalLine0
        {
         sendOrder=-1;//&& positionSignal == i2
        }
     }

   if(useAutoTrading)
     {
      double movingHigh=iMA(Symbol(),ATRperiod,GANNChannelperiod,1,MODE_SMMA,PRICE_HIGH,1);
      double movingLow=iMA(Symbol(),ATRperiod,GANNChannelperiod,1,MODE_SMMA,PRICE_LOW,1);
      if(iClose(Symbol(),ATRperiod,1)<movingHigh && iClose(Symbol(),ATRperiod,1)>movingLow)
        {
         //manageBasket(true);
         //sendOrder=manageOrderSideToBasket();
         //GANNChannelSendOrders?sendOrder=sendOrder:sendOrder=0;
        }
      else if(iClose(Symbol(),ATRperiod,1)<movingHigh && iClose(Symbol(),ATRperiod,1)<movingLow)
        {
         sendOrder=-1;
         if(useGANNChannelAutoClose)
           {
            closeAll(1);
           }
        }
      else if(iClose(Symbol(),ATRperiod,1)>movingHigh && iClose(Symbol(),ATRperiod,1)>movingLow)
        {
         sendOrder=1;
         if(useGANNChannelAutoClose)
           {
            closeAll(-1);
           }
        }
     }

   if(StrategyTesterDateFrom!="" && StrategyTesterDateTo!="")
     {
      if(IsTesting())
        {
         if(Time[0]<=StrToTime(StrategyTesterDateFrom) || Time[0]>=StrToTime(StrategyTesterDateTo))
           {
            sendOrder=0;
            closeAll(-1);
            closeAll(1);
           }
        }
     }

   if(HAChangeColourBE)
     {
      double haOpen=iCustom(NULL,ATRperiod,"HeikenAshi_DM",2,1); //0 atualcadle , 1 last candle
      double haClose=iCustom(NULL,ATRperiod,"HeikenAshi_DM",3,1); //0 atualcadle , 1 last candle

      if(sendOrder==-1 && haOpen<haClose)
        {
         sendOrder=0;

        }
      if(sendOrder==1 && haOpen>haClose)
        {
         sendOrder=0;
        }

      for(int i=0; i<OrdersTotal(); i++)
         //+------------------------------------------------------------------+
         //|                                                                  |
         //+------------------------------------------------------------------+
        {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {

            if(OrderType()==OP_SELL && haOpen<haClose)
              {
               manageBasket(true);
               //sendOrder=0;
               break;
              }
            if(OrderType()==OP_BUY && haOpen>haClose)
              {
               manageBasket(true);
               //sendOrder=0;
               break;
              }
           }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(BreakEvenMode)
     {
      if(OrdersTotal()==0) //BreakEvenMode doesn't send orders if there is no order open
        {
         return(0);
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      else
        {
         manageBasket(true);
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   switch(sendOrder)
     {
      case 1: doStuff(1,"MA Cross Up",1);break;
      case -1:  doStuff(1,"MA Cross Down",-1);break;
      case 2:
         doStuff(1,"MA Cross Up",1);
         doStuff(1,"MA Cross Down",-1);
         break;
     }
// for(i2=limit; i2>=0; i2--)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//{


/*if(positionSignal!=EMPTY_VALUE)
        {
         printf("buySignal = "+buySignal);
         printf("sellSignal = "+sellSignal);
         printf("positionSignal = "+positionSignal);
         printf("orderTypes = "+orderTypes);
        }*/
//  }

//--------------------------------------------------------------- 6 --

//--------------------------------------------------------------- 9 --
   return(0);                                      // Exit start()
  }
//-------------------------------------------------------------- 10 --
int Fun_Error(int Error) // Function of processing errors
  {
////Printf(Error);
   switch(Error)
     {                                          // Not crucial errors            

      case  4: Alert("Trade server is busy. Trying once again..");
      Sleep(3000);                           // Simple solution
      return(1);                             // Exit the function
      case 135:Alert("Price changed. Trying once again..");
      RefreshRates();                        // Refresh rates
      return(1);                             // Exit the function
      case 136:Alert("No prices. Waiting for a new tick..");
      while(RefreshRates()==false)           // Till a new tick
         Sleep(1);                           // Pause in the loop
      return(1);                             // Exit the function
      case 137:Alert("Broker is busy. Trying once again..");
      Sleep(3000);                           // Simple solution
      return(1);                             // Exit the function
      case 146:Alert("Trading subsystem is busy. Trying once again..");
      Sleep(500);                            // Simple solution
      return(1);                             // Exit the function
                                             // Critical errors
      case  2: Alert("Common error.");
      return(0);                             // Exit the function
      case  5: Alert("Old terminal version.");

      return(0);                             // Exit the function
      case 64: Alert("Account blocked.");

      return(0);                             // Exit the function
      case 133:Alert("Trading forbidden.");
      return(0);                             // Exit the function
      case 134:Alert("Not enough money to execute operation.");
      return(0);                             // Exit the function
      default: Alert("Error occurred: ",Error);  // Other variants   
      return(0);                             // Exit the function
     }
  }
//-------------------------------------------------------------- 12 --

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doStuff(int forBar,string doWhat,int sides)
  {
//--------------------------------------------------------------- 8 --

   static string   previousAlert="Nothing";
   static datetime previousTime;
   bool send=SendOrders;
   bool orderSent=false;
   string message;
   double riskcapital;
   MathSrand(TimeLocal());
   int magicNumber=MathRand();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(true) //previousAlert!=doWhat || previousTime!=Time[forBar]
     {

      previousAlert  = doWhat;
      previousTime   = Time[forBar];

      message=StringConcatenate(Symbol()," "+doWhat);
      if(useMinimalDistance)
        {
         if(sides==-1)
           {
            send=calcMinimalDistance(Bid,sides);
           }
         else if(sides==1)
           {
            send=calcMinimalDistance(Ask,sides);
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
/**START GANN**/
      if(useGANN)
        {
         if(useGANNHTF)
           {
            double gannMXHTF1=iCustom(NULL,gannHTFPeriod01,"GannHiLo-Histo",gannMXperiod,2,1); //0 atualcadle , 1 last candle
            double gannMXHTF2=iCustom(NULL,gannHTFPeriod02,"GannHiLo-Histo",gannMXperiod,2,1); //0 atualcadle , 1 last candle
            double gannMXHTF3=iCustom(NULL,gannHTFPeriod03,"GannHiLo-Histo",gannMXperiod,2,1); //0 atualcadle , 1 last candle
            if((gannMXHTF1==1 || gannMXHTF2==1 || gannMXHTF3==1) && sides==-1)
              { //BUY
               send=false;
              }
            else if((gannMXHTF1==-1 || gannMXHTF2==-1 || gannMXHTF3==-1) && sides==1)
              {
               send=false;
              }
           }

         double gannD1=iCustom(NULL,1440,"GannHiLo-Histo",GANNperiod,2,1); //0 atualcadle , 1 last candle

         if(gannD1==1 && sides==-1)
           { //BUY
            send=false;
           }
         else if(gannD1==-1 && sides==1)
           {
            send=false;
           }
         if(useGANNAutoClose)
           {
            for(int i=0; i<OrdersTotal(); i++)
              {
               OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
               if(OrderSymbol()==Symbol())
                 {
                  RefreshRates();
                  if(OrderType()==OP_BUY && gannD1==-1)
                    { // && gannW1==1  && gannW1==-1
                     OrderClose(OrderTicket(),OrderLots(),Bid,5,Blue);
                    }
                  if(OrderType()==OP_SELL && gannD1==1)
                    {
                     OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
                    }
                 }
              }
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      //TODO FIX!
      if(useTDICross)
        {

         string             TDI_Settings="————————————————————————————————————";/* TDI Settings */
         int                TDI_RSIPeriod= 13;             /* TDI: RSI Period */
         ENUM_APPLIED_PRICE TDI_RSIPrice = PRICE_CLOSE;     /* TDI: RSI Price Type */
         int                TDI_VolatilityBand=34;        /* TDI: Volatility Band */
         int                TDI_RSIPriceLine = 2;           /* TDI: RSI Price Line */
         ENUM_MA_METHOD     TDI_RSIPriceType = 0;           /* TDI: RSI Price Type */
         int                TDI_TradeSignalLine = 7;        /* TDI: TradeSignalLine */
         ENUM_MA_METHOD     TDI_TradeSignalType = MODE_SMA; /* TDI: TradeSignalType */
         double dRSIPriceLine1,dRSIPriceLine2,dRSIPriceLine3;
         double dTradeSignalLine1,dTradeSignalLine2,dTradeSignalLine3;

         dRSIPriceLine1=iCustom(NULL,TDICrossHTFPeriod01,"TDI-RT-Clone",13,PRICE_CLOSE,34,2,
                                0,TDI_TradeSignalLine,TDI_TradeSignalType,4,1);     // Green line

         dTradeSignalLine1=iCustom(NULL,TDICrossHTFPeriod01,"TDI-RT-Clone",13,PRICE_CLOSE,34,2,
                                   0,TDI_TradeSignalLine,TDI_TradeSignalType,3,1);  // Red line

         dRSIPriceLine2=iCustom(NULL,TDICrossHTFPeriod02,"TDI-RT-Clone",13,PRICE_CLOSE,34,2,
                                0,TDI_TradeSignalLine,TDI_TradeSignalType,4,1);     // Green line

         dTradeSignalLine2=iCustom(NULL,TDICrossHTFPeriod02,"TDI-RT-Clone",13,PRICE_CLOSE,34,2,
                                   0,TDI_TradeSignalLine,TDI_TradeSignalType,3,1);  // Red line

         dRSIPriceLine3=iCustom(NULL,TDICrossHTFPeriod03,"TDI-RT-Clone",13,PRICE_CLOSE,34,2,
                                0,TDI_TradeSignalLine,TDI_TradeSignalType,4,1);     // Green line

         dTradeSignalLine3=iCustom(NULL,TDICrossHTFPeriod03,"TDI-RT-Clone",13,PRICE_CLOSE,34,2,
                                   0,TDI_TradeSignalLine,TDI_TradeSignalType,3,1);  // Red line

         if(sides==1 && (dTradeSignalLine1>dRSIPriceLine1))
           {
            if(useTDICrossHTF)
              {
               if(sides==1 && ((dTradeSignalLine2>dRSIPriceLine2) || (dTradeSignalLine3>dRSIPriceLine3)))
                 {
                  closeAll(-1);
                  send=false;
                 }
              }
            else
              {
               closeAll(-1);
               send=false;
              }
            if(sides==-1 && (dRSIPriceLine1>dTradeSignalLine1))
              {
               if(useTDICrossHTF)
                 {
                  if(sides==-1 && ((dRSIPriceLine2>dTradeSignalLine2) || (dRSIPriceLine3>dTradeSignalLine3)))
                    {
                     closeAll(-1);
                     send=false;
                    }
                 }
               else
                 {
                  closeAll(1);
                  send=false;
                 }

              }
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(useLtsPercentSL)
        {
         riskcapital=AccountBalance()*StopLossPercent/100;
         Lts=NormalizeDouble((riskcapital/(ATRPips*ATRStopLossMultiplier))/tickvalue,2);
        }
      if(useIncrementalLot)
        {
         double highestLot=calcIncrementalLot(Lts);
         //Lts=highestLot+(highestLot*incrementalLotMultiplier);
         Lts=highestLot+0.01;
        }

      if(Lts<0.01)
        {
         Lts=0.01;
        }

/**END GANN**/
      if(sides==-1) //SELL
        {
         if(StringFind(AlertSellPairs,Symbol(),0)!=-1)
           {
            if(send)
              {
               RefreshRates();                        // Refresh rates
                                                      //TP=NULL;                                       //SL=Ask+0*Point;     // Calculating SL of opened
               //SL=NULL;
               if(ATRStopLoss)
                 {
                  SL=Bid+(ATRPips*ATRStopLossMultiplier)*pips2dbl;
                  TP=Bid-((ATRPips*ATRTakeProfitMultiplier)*pips2dbl);
                 }
               if(BasketSameStopLoss)
                 {
                  SL=calculateSLBasket(SL,sides);
                  //TODO Lts = NormalizeDouble((riskcapital/(ATRPips*ATRStopLossMultiplier))/tickvalue,2);
                 }

               Ticket=OrderSend(Symbol(),OP_SELL,Lts,Bid,2,SL,TP,NULL,magicNumber);//Opening Sell

               if(Ticket>0) // Success :)
                 {
                  orderSent=true;
                  if(sendNotifications)
                    {
                     SendNotification("Short open "+Symbol());
                    }
                 }
               if(orderSent)
                 {
                  if(manageOrders==1)
                    {
                     manageBasket(false);
                    }
                 }

              }
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(sides==1) //BUY
        {
         if(StringFind(AlertBuyPairs,Symbol(),0)!=-1)
           {
            if(send)
              {
               RefreshRates();                        // Refresh rates
               SL=NULL;
               TP=NULL;
               if(ATRStopLoss)
                 {
                  SL=Ask-(ATRPips*ATRStopLossMultiplier)*pips2dbl;
                  TP=Ask+((ATRPips*ATRTakeProfitMultiplier)*pips2dbl);
                 }
               if(BasketSameStopLoss)
                 {
                  SL=calculateSLBasket(SL,sides);
                 }

               Ticket=OrderSend(Symbol(),OP_BUY,Lts,Ask,2,SL,TP,NULL,magicNumber);//Opening Buy
               if(Ticket>0) // Success :)
                 {
                  orderSent=true;
                  if(sendNotifications)
                    {
                     SendNotification("Long open "+Symbol());
                    }
                 }
               if(orderSent)
                 {
                  if(manageOrders==1)
                    {
                     manageBasket(false);
                    }
                 }
              }
           }
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void manageBasket(bool breakEven)
  {
   bool  manageBasketSell=false;
   bool  manageBasketBuy=false;
   int   nOrders=0;
   int   nOrdersSell=0;
   int   nOrdersBuy=0;
   double dOpenPriceBuy=0.0;
   double dOpenPriceSell=0.0;

   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderSymbol()==Symbol())
        {
         nOrders++;
         if(OrderType()==OP_SELL)
           {
            nOrdersSell++;
            dOpenPriceSell+=OrderOpenPrice();
           }
         if(OrderType()==OP_BUY)
           {
            nOrdersBuy++;
            dOpenPriceBuy+=OrderOpenPrice();
           }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// if(nOrdersSell>=2 || nOrdersBuy>=2)
// {
   bool res=false;

   for(int y=0; y<OrdersTotal(); y++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_SELL) //&& nOrdersSell>=2
           {
            double dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
            if(breakEven)
              {
               TP=dAvgEntryPriceSell-((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);
                 }else{
               TP=dAvgEntryPriceSell-((ATRPips*(ATRBasketTPMultiplier))*pips2dbl);
              }
            res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);

           }
         if(OrderType()==OP_BUY) //&& nOrdersBuy>=2
           {
            double dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
            if(breakEven)
              {
               TP=dAvgEntryPriceBuy+((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2
                 }else{
               TP=dAvgEntryPriceBuy+((ATRPips*(ATRBasketTPMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2
              }
            res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);
           }
        }
     }
//}
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAll(int side)
  {
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderType()==OP_BUY && side==1)
        { // && gannW1==1  && gannW1==-1
         OrderClose(OrderTicket(),OrderLots(),Bid,5,Blue);
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderType()==OP_SELL && side==-1)
        {
         OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool manageOfflineMode()
  {
/*TODO
   for(int i=0; i<OrdersTotal(); i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
            if(OrderComment()!="RUNNER"){
               return false;
            }
        }
     }
     */
   return true;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calcMinimalDistance(double price,int side)
  {
   bool sendOrder=true;
   double differencePips;

   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY && side==1) //BUY
           {
            differencePips=(OrderOpenPrice()-price)/pips2dbl;
            if(differencePips<ATRPips*ATRMinDistanceMultiplier)
              {
               sendOrder=false;
               break;
              }
           }

         if(OrderType()==OP_SELL && side==-1)
           {
            differencePips=(price-OrderOpenPrice())/pips2dbl;
            if(differencePips<ATRPips*ATRMinDistanceMultiplier) //|| differencePips > -ATRPips*ATRMinDistanceMultiplier??
              {
               sendOrder=false;
               break;
              }
           }
        }
     }
   return sendOrder;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcIncrementalLot(double lts)
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if(OrderLots()>lts)
           {
            lts=OrderLots();
           }
        }
     }
   return lts;
  }
//+------------------------------------------------------------------+

int manageOrderSideToBasket()
  {
   bool sendBuy=false;
   bool sendSell=false;
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {

      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY) //BUY
           {
            sendBuy=true;
           }
         else if(OrderType()==OP_SELL)
           {
            sendSell=true;
           } //SELL
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(sendBuy && sendSell)
     {
      return 2;
        }else if(sendBuy && !sendSell){
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      return 1;
        }else if(sendSell && !sendBuy){
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      return -1;
        }else {
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      return 0;
     }
  }
//+------------------------------------------------------------------+
double calculateSLBasket(double SL,int side)
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY && side==1) //BUY
           {
            SL=OrderStopLoss();
           }
         else if(OrderType()==OP_SELL && side==-1)
           {
            SL=OrderStopLoss();
           } //SELL
        }
     }
   return SL;
  }
//+------------------------------------------------------------------+
