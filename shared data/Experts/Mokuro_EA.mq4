//+------------------------------------------------------------------+
//|   Mokuro89 Expert                                                |
//|                                                                  |
//|   Copyright © 2016 / mokuro89@gmail.com                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "2016-2017, Mokuro89."
#property link        "mokuro89@gmail.com"

//to use with ATRPeriods
extern bool    useMinimalDistance=true;
extern bool    sendNotifications=true;
extern double  ATRperiod=1440;
extern bool    ATRStopLoss=true;
extern double  ATRMinDistanceMultiplier=1;
extern double  ATRTakeProfitMultiplier=0.5;
extern double  ATRStopLossMultiplier=2.1;
extern double  ATRBasketTPMultiplier=0.3;
extern bool    usePercentAsSL=true;
extern bool    useZigZag=true;
extern double  ZigZagDepth=55;
//GANN
extern bool    useGANN=false;
extern double  GANNperiod=5;
extern bool    useGANNAutoSide=false;
extern bool    useGANNAutoClose=false;
//QUANTUM
//extern bool    useQuantum=false;
//extern int     quantumDepth=55;

extern int     Length      = 2;
extern int     Smooth1     = 3;
extern int     Smooth2     = 3;
extern int     Signal      = 3;
extern int     Price       = PRICE_CLOSE;
extern double  OverBought1 =  60;
extern double  OverSold1   = -60;


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
Lot,                             // Amount of lots in a selected order
Lts,                             // Amount of lots in an opened order
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
               manageOrders=result[3];

               //Only send orders if RSI cross 50lvl
               //useM30RSI=result[4];
               //useM30RSI=0;

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
   int i2,limit;

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

   double buySignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,0,1);
   double sellSignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,1,1);
   double positionSignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,10,1);
   double orderTypes=iCustom(NULL,0,"Mokuro89_Alert","",0,true,Length,Smooth1,Smooth2,Signal,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",ZigZagDepth,5,3,11,1);

   if(orderTypes==1) doStuff(1,"MA Cross Up",1);//&& positionSignal == i2
   if(orderTypes==-1) doStuff(1,"MA Cross Down",-1);

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
   double differencePips;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(previousAlert!=doWhat || previousTime!=Time[forBar])
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
/**START GANN**/
      if(useGANN)
        {
         double gannD1=iCustom(NULL,1440,"GannHiLo-Histo",GANNperiod,2,1); //0 atualcadle , 1 last candle
         
         if(gannD1==1 && sides==-1)
           { //BUY
            send=false;
           }
         if(gannD1==-1 && sides==1)
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
/**END GANN**/
      if(sides==-1) //SELL
        {
         if(StringFind(AlertSellPairs,Symbol(),0)!=-1)
           {
            if(send)
              {
               RefreshRates();                        // Refresh rates
                                                      //SL=Ask+0*Point;     // Calculating SL of opened
               SL=NULL;
               if(ATRStopLoss)
                 {
                  SL=Bid+(ATRPips*ATRStopLossMultiplier)*pips2dbl;
                  TP=Bid-((ATRPips*ATRTakeProfitMultiplier)*pips2dbl);
                 }
               if(usePercentAsSL)
                 {
                  riskcapital=AccountBalance()*StopLossPercent/100;
                  Lts=NormalizeDouble((riskcapital/(ATRPips*ATRStopLossMultiplier))/tickvalue,2);
                  if(Lts<0.01)
                    {
                     Lts=0.01;
                    }
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
                     manageBasket();
                    }
                 }

              }
           }
        }
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
               if(usePercentAsSL)
                 {
                  riskcapital=AccountBalance()*StopLossPercent/100;
                  Lts=NormalizeDouble((riskcapital/(ATRPips*ATRStopLossMultiplier))/tickvalue,2);
                  if(Lts<0.01)
                    {
                     Lts=0.01;
                    }
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
                     manageBasket();
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
void manageBasket()
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
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
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
   if(nOrdersSell>=2 || nOrdersBuy>=2)
     {
      bool res=false;

      for(int y=0; y<OrdersTotal(); y++)
        {
         OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if(OrderType()==OP_SELL && nOrdersSell>=2)
              {
               double dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
               TP=dAvgEntryPriceSell-((ATRPips*(ATRBasketTPMultiplier))*pips2dbl);
               res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);

              }
            if(OrderType()==OP_BUY && nOrdersBuy>=2)
              {
               double dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
               TP=dAvgEntryPriceBuy+((ATRPips*(ATRBasketTPMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2
               res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);
              }
           }
        }
     }
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
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && side==1)
        { // && gannW1==1  && gannW1==-1
         OrderClose(OrderTicket(),OrderLots(),Bid,5,Blue);
        }
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
/*
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
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
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
