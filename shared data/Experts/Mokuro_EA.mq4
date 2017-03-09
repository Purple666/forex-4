//--------------------------------------------------------------------
// Mokuro_EA.mq4 

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
int manageOrders =0,useM30RSI =0,useRunner =0,offlineMode =0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init(){

   return(0);
}
int start()
  {

// Orders accounting

   Total=0;

   int Handle;                          // Style of vertical line
   string File_Name="Mokuro_EA_config.csv";        // Name of the file
   string text;
   AlertSellPairs=NULL;
   AlertBuyPairs=NULL;

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
      if(StringFind(text,Symbol(),0)!=-1)
        {
         //declare variables used later
         declareVariables();

         string to_split=text;   // A string to split into substrings
         string sep="_";                // A separator as a character
         ushort u_sep;                  // The code of the separator character
         string result[];               // An array to get strings
         //--- Get the separator code
         u_sep=StringGetCharacter(sep,0);
         //--- Split the string to substrings
         int k=StringSplit(to_split,u_sep,result);
         //--- Show a comment 
         //PrintFormat("Strings obtained: %d. Used separator '%s' with the code %d",k,sep,u_sep);
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
      //    printf("AlertSellPairs - "+AlertSellPairs);
      //      printf("AlertBuyPairs - "+AlertBuyPairs);
     }
   FileClose(Handle);                // Close file
                                     //WindowRedraw();                     // Redraw object

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
   if(Digits==5|| Digits==3)
     {
      tickvalue=tickvalue*10;
     }

// if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
//  printf(Bars);
   limit=MathMin(Bars-counted_bars,Bars-1);

   if(ArrayRange(tBuffer,0)!=Bars) ArrayResize(tBuffer,Bars);

   for(i2=limit; i2>=0; i2--)
     {
      double buySignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,2,3,3,3,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",55,5,3,0,i2);
      double sellSignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,2,3,3,3,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",55,5,3,1,i2);
      double positionSignal=iCustom(NULL,0,"Mokuro89_Alert","",0,true,2,3,3,3,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",55,5,3,10,i2);
      double orderTypes=iCustom(NULL,0,"Mokuro89_Alert","",0,true,2,3,3,3,PRICE_CLOSE,OverBought1,OverSold1,TRUE,False,false,True,False,False,True,useZigZag,"",55,5,3,11,i2);

/*if(positionSignal!=EMPTY_VALUE)
        {
         printf("buySignal = "+buySignal);
         printf("sellSignal = "+sellSignal);
         printf("positionSignal = "+positionSignal);
         printf("orderTypes = "+orderTypes);
        }*/
      //int whichBar = 1;

      if(orderTypes==1 && positionSignal == i2) doStuff(1,"MA Cross Up",2);
      if(orderTypes==-1 && positionSignal == i2) doStuff(1,"MA Cross Down",-1);


     }
//--------------------------------------------------------------- 6 --

//--------------------------------------------------------------- 9 --
   return(0);                                      // Exit start()
  }
//-------------------------------------------------------------- 10 --
int Fun_Error(int Error) // Function of processing errors
  {
   printf(Error);
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
   bool send;
   bool orderSent;
   string message;
   double riskcapital;
   MathSrand(TimeLocal());
   int magicNumber = MathRand();
//printf("previousAlert"+previousAlert);
//printf("previousTime"+previousTime);




//////REMOVER

int i100= MathCeil(pipMult *(iATR(NULL,ATRperiod,100,0)));
   //int i10 = MathCeil(pipMult *(iATR(NULL,1440,10,0)));
//period 100 as default
   ATRPips=i100;
   bool sendOrder=true;
   double differencePips;

////


   if(previousAlert!=doWhat || previousTime!=Time[forBar])
     {

      previousAlert  = doWhat;
      previousTime   = Time[forBar];

      //message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," ",Symbol()," ",Period()," SMI ",doWhat);
      message=StringConcatenate(Symbol()," "+doWhat);

      if(sides==-1) //SELL
        {
         if(StringFind(AlertSellPairs,Symbol(),0)!=-1)
           {

            if(SendOrders)
              {
               send=true;
               orderSent=false;
               RefreshRates();
               if(useMinimalDistance)
                 {
                  send=calcMinimalDistance(Bid);
                  //Print("send calcMinimalDistance result: "+send);
                 }
               /*if(useM30RSI)
                 {
                  printf("useM30RSI: "+useM30RSI);
                  if(iRSI(NULL,30,13,PRICE_CLOSE,0)<50)
                    {
                     printf("RSI < 50 ,send order = false!");
                     send=false;
                    }
                 }*/
               if(send)
                 {
                  RefreshRates();                        // Refresh rates
                                                         //SL=Ask+0*Point;     // Calculating SL of opened
                  SL=NULL;
                  if(ATRStopLoss)
                    {
                     Print("ATRPips: "+ATRPips);

                     //SL=ATRPips;
                     printf("SL*pips2dbl : "+SL*pips2dbl);
                     SL=Bid+(ATRPips*ATRStopLossMultiplier)*pips2dbl;
                     TP=Bid-((ATRPips*ATRTakeProfitMultiplier)*pips2dbl);
                    }
                  if(usePercentAsSL)
                    {
                     riskcapital=AccountBalance()*StopLossPercent/100;
                     Print("riskcapital: "+riskcapital);
                     Print("SL: "+SL);
                     Print("tickvalue: "+tickvalue);
                     Lts=NormalizeDouble((riskcapital/(ATRPips*ATRStopLossMultiplier))/tickvalue,2);
                     Print("Lts: "+Lts);
                     if(Lts>0.15) //TODO REMOVER 
                       {
                        printf("Lots > 0.40 , ajusting to 0.01, please check");
                        //Lts=0.01;
                       }
                     if(Lts<0.01)
                       {
                        printf("Lots < 0.01, ajusting to 0.01");
                        Lts=0.01;
                       }
                    }
                  //TP=Ask-0*Point;   // Calculating TP of opened
                  Print("Attempt to open Sell. Waiting for response..");

                  Ticket=OrderSend(Symbol(),OP_SELL,Lts,Bid,2,SL,TP,NULL,magicNumber);//Opening Sell

                  if(Ticket>0) // Success :)
                    {
                     orderSent=true;
                     // Sleep(120000); //2 MINUTES BETWEEN EACH ORDER
                     if(sendNotifications)
                       {

                        SendNotification("Short open "+Symbol());
                       }
                     // Exit start()
                    }
                  ////SECOND ORDER - RUNNER
                  /*if(useRunner==1)
                    {
                     Ticket=OrderSend(Symbol(),OP_SELL,Lts,Bid,2,SL,NULL,"RUNNER",magicNumber);//Opening Sell
                     if(Ticket>0) // Success :)
                       {
                        orderSent=true;
                        if(sendNotifications)
                          {
                           SendNotification("Short Runner open "+Symbol());
                          }
                       }
                    }*/
                  if(orderSent)
                    {
                     if(manageOrders==1)
                       {
                        manageBasket();
                       }
                    }
                  //  if(Fun_Error(GetLastError())==1) // Processing errors
                  //     return;                           // Retrying
                  // Exit start()
                 }
              }
           }
        }
      // criterion for opening Sell

      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(sides==2) //BUY
        {
         if(StringFind(AlertBuyPairs,Symbol(),0)!=-1)
           {

            if(SendOrders)
              {
               send=true;
               orderSent=false;
               RefreshRates();
               if(useMinimalDistance)
                 {
                  send=calcMinimalDistance(Ask);
                  //Print("send calcMinimalDistance result: "+send);
                 }
               /*if(useM30RSI)
                 {
                  printf("useM30RSI: "+useM30RSI);
                  if(iRSI(NULL,30,13,PRICE_CLOSE,0)>50)
                    {
                     printf("RSI > 50 ,send order = false!");
                     send=false;
                    }
                 }*/
               if(send)
                 {
                  RefreshRates();                        // Refresh rates
                                                         //SL=Bid-0*Point;     // Calculating SL of opened
                  SL=NULL;
                  TP=NULL;
                  if(ATRStopLoss)
                    {
                     Print("ATRPips: "+ATRPips);
                     //SL=ATRPips;
                     printf("SL*pips2dbl : "+SL*pips2dbl);
                     SL=Ask-(ATRPips*ATRStopLossMultiplier)*pips2dbl;
                     TP=Ask+((ATRPips*ATRTakeProfitMultiplier)*pips2dbl);
                    }
                  if(usePercentAsSL)
                    {
                     riskcapital=AccountBalance()*StopLossPercent/100;
                     Print("riskcapital: "+riskcapital);
                     Print("SL: "+SL);
                     Print("tickvalue: "+tickvalue);
                     Lts=NormalizeDouble((riskcapital/(ATRPips*ATRStopLossMultiplier))/tickvalue,2);
                     Print("Lts: "+Lts);
                     if(Lts>0.5) //TODO REMOVE THIS IF LATER , ONLY PROTECTING AGAINST WRONG FUCKING 1.00 VOL ORDERS
                       {
                        printf("Lots > 0.15 , ajusting to 0.01, please check");
                        Lts=0.01;
                       }
                     if(Lts<0.01)
                       {
                        printf("Lots < 0.01, ajusting to 0.01");
                        Lts=0.01;
                       }
                    }
                  //TP=Bid+0*Point;   // Calculating TP of opened
                  Print("Attempt to open Buy. Waiting for response..");

                  Ticket=OrderSend(Symbol(),OP_BUY,Lts,Ask,2,SL,TP,NULL,magicNumber);//Opening Buy
                  if(Ticket>0) // Success :)
                    {
                     orderSent=true;
                     // Sleep(120000); //2 MINUTES BETWEEN EACH ORDER
                     if(sendNotifications)
                       {

                        SendNotification("Long open "+Symbol());
                       }
                     // Exit start()
                    }
                  //SECOND ORDER - RUNNER
                  /*if(useRunner==1)
                    {
                     Ticket=OrderSend(Symbol(),OP_BUY,Lts,Ask,2,SL,NULL,"RUNNER",magicNumber);//Opening Buy  
                     if(Ticket>0) // Success :)
                       {
                        orderSent=true;
                        if(sendNotifications)
                          {
                           SendNotification("Long Runner open "+Symbol());
                          }
                       }
                    }*/
                  if(orderSent)
                    {
                     if(manageOrders==1)
                       {
                        manageBasket();
                       }
                    }
                  //if(Fun_Error(GetLastError())==1) // Processing errors
                  //     return;                           // Retrying
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
   printf("enter Managing Basket");
   bool  manageBasket=false;
   int   nOrders=0;
   double dOpenPrice=0.0;
   
   for(int i=0; i<OrdersTotal(); i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         nOrders++;
         dOpenPrice+=OrderOpenPrice();
         if(nOrders>1) //TODO FIX 
           {
            manageBasket=true;
           }
        }
     }
   if(manageBasket)

     {
      printf("Managing Basket of "+nOrders+" orders");
      bool res=false;
      double dAvgEntryPrice=dOpenPrice/nOrders;

      for(int y=0; y<OrdersTotal(); y++)
        {
         OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            //2 orders -> TP of 1 order
            if(nOrders==2)
              {
               if(OrderType()==OP_SELL)
                 {
                  TP=dAvgEntryPrice-((ATRPips*(ATRBasketTPMultiplier))*pips2dbl);
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);

                 }
               if(OrderType()==OP_BUY)
                 {
                  TP=dAvgEntryPrice+((ATRPips*(ATRBasketTPMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);

                 }
               if(!res)
                  Print("Error in OrderModify. Error code=",GetLastError());
               else
                  Print("Order modified successfully TO 1x TP.");
              }
            //3 or more orders -> leave at BE
            if(nOrders>2)
              {
               if(OrderType()==OP_SELL)
                 {
                  TP=dAvgEntryPrice-((ATRPips*ATRBasketTPMultiplier)*pips2dbl); //5 PIPS
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);
                 }
               if(OrderType()==OP_BUY)
                 {
                  TP=dAvgEntryPrice+((ATRPips*ATRBasketTPMultiplier)*pips2dbl); //5 PIPS
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TP,0,Blue);
                 }
               if(!res)
                  Print("Error in OrderModify. Error code=",GetLastError());
               else
                  Print("Orders modified successfully TO BE.");
              }
           }

        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void declareVariables()
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
  }
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
bool calcMinimalDistance(double price)
  {
int i100= MathCeil(pipMult *(iATR(NULL,ATRperiod,100,0)));
   //int i10 = MathCeil(pipMult *(iATR(NULL,1440,10,0)));
//period 100 as default
   ATRPips=i100;
   bool sendOrder=true;
   double differencePips;

//printf("Symbol():"+Symbol());
   
   //printf("ATR: "+ATRPips);
//if atr(10) > atr(100), use atr(10)
   /*if(i10>i100)
     {
      ATRPips=i10;
     }
*/
   bool mostDistantOrder=true;

//first iteraction
   for(int i=0; i<OrdersTotal(); i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         printf("OrderComment() : "+OrderComment());
         if(OrderComment()=="RUNNER")
           { //IGNORE RUNNERS WHEN CALCULATING MINIMAL ORDERS DISTANCE (to keep trading the trend when there is only runners 
            printf("RUNNER detected on calcMinimalDistance, ignoring it");
            continue;
           }
         if(OrderType()==OP_BUY)
           {
            // if(price<OrderOpenPrice())
            // {
            mostDistantOrder=false;
            differencePips=(OrderOpenPrice()-price)/pips2dbl;
            // printf("diffferencePoints last order: "+differencePips);
            // printf("ATRPips/5: "+ATRPips/5);
            if(differencePips<ATRPips*ATRMinDistanceMultiplier )
              {
               sendOrder=false;
               break;
              }
            //}
           }

         if(OrderType()==OP_SELL)
           {

            //  if(price>OrderOpenPrice())
            //  {
            mostDistantOrder=false;
            differencePips=(price-OrderOpenPrice())/pips2dbl;
            printf("differencePips: "+differencePips);
            printf("ATRPips*ATRMinDistanceMultiplier: "+ATRPips*ATRMinDistanceMultiplier);
            if(differencePips<ATRPips*ATRMinDistanceMultiplier ) //|| differencePips > -ATRPips*ATRMinDistanceMultiplier??
              {
               sendOrder=false;
               break;
              }
            //}
           }
        }
     }
/*
//second iteraction
   for(int y=0; y<OrdersTotal(); y++)
     {
      OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         //totalots+=OrderLots(); //this gives the total no of lots opened in current ordes
         if(OrderType()==OP_BUY && price>OrderOpenPrice())
           {
            differencePips=(price-OrderOpenPrice())/pips2dbl;
            if(mostDistantOrder)
              {
               if(differencePips<ATRPips/5)
                 {
                  sendOrder=false;
                  break;
                 }
                 }else {
               if(differencePips<ATRPips/5)
                 {
                  sendOrder=false;
                  break;
                 }
              }
           }

         if(OrderType()==OP_SELL && OrderOpenPrice()>price)
           {
            differencePips=(OrderOpenPrice()-price)/pips2dbl;
            if(mostDistantOrder)
              {
               if(differencePips<2)
                 {
                  sendOrder=false;
                  break;
                 }
                 }else {
               if(differencePips<ATRPips/5)
                 {
                  sendOrder=false;
                  break;
                 }
              }
           }
        }
     }*/
   return sendOrder;
  }