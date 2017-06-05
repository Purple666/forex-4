//+------------------------------------------------------------------+
//|   Mokuro89 Expert                                                |
//|                                                                  |
//|   Copyright © 2016 / mokuro89@gmail.com                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "2016-2017, Mokuro89."
#property link        "mokuro89@gmail.com"

bool    useHalfTrend=false;
extern bool    sendNotifications=true;
extern bool    scaleInFirstTP=false;
bool    martingale=false;
extern bool    scaleIn=false;

extern string  sideLegend="=======| 1 BUY | -1 SELL |=======";
extern int     SIDE=0;
extern ENUM_TIMEFRAMES ATRperiod=PERIOD_D1;
extern int     MaxOrdersBasket=0;

extern string  distanceLegend="=======ORDERS DISTANCE=======";
extern double  DistancePips=20;
extern bool    ATRDistanceOrders=true;
extern double  ATRMinDistanceMultiplier=0.5;

extern string  takeProfitLegend="=======TAKE PROFFIT=======";
extern double  TakeProfit=20;
extern bool    ATRTakeProfit=true;
extern double  ATRTakeProfitMultiplier=1;
extern double  ATRBasketTakeProfitMultiplier=1;

extern string  stopLossLegend="=======STOP LOSS=======";
extern double  StopLoss=0;
extern bool    ATRStopLoss=true;
extern double  ATRStopLossMultiplier=3;
extern bool    BasketSameStopLoss=false;

extern string  lotsLegend="=======LOTS=======";
extern double  Lots=0.01;
extern bool    UseLotsPercentSL=false;
extern double  LotsPercent=1;
extern bool    UseIncrementalLot=false;
extern double  IncrementalLots=0.01;
extern double  MaximalLotPosition=0.00;

extern string  triggersLegend="=======TRIGGERS=======";
extern bool    ChannelHighLow=true;
extern ENUM_TIMEFRAMES ChannelHighLowTimeFrame=PERIOD_M5;
extern double  ChannelHighLowPeriod=5;

extern string  modesLegend="=======MODES=======";
extern bool    BreakEvenMode=false;
extern double  BreakEvenPips=5;
extern bool    ATRBasketBreakEven=true;
extern double  ATRBasketBreakEvenMultiplier=0.1;

extern string  startStopLlvlLegends="***Start/Stop trading at Level***";
extern bool    LastTPMode=false;
extern bool    StopTradingAtLevel=false;
extern double  LevelStopTrading=0;

extern bool    StartTradingAtLevel=false;
extern double  LevelStartTradingLimit=0;
extern double  LevelStartTradingStop=0;

extern string  timeLegends="***Trading Time in 24HOURS FORMAT***";
extern int StartTime=0;          // Time to allow trading to start ( hours of 24 hr clock ) 0 for both disables
extern int FinishTime=0;

int currentTime=0;
extern string  strategyTesterLegend="DATEFORMAT EXAMPLE: 2017.03.01 09:00";
extern string  strategyTesterDateFrom="";
extern string  strategyTesterDateTo="";

extern bool    SendOrders=true;

bool HAChangeColourBE=false;
extern bool    useGANN=false;
extern ENUM_TIMEFRAMES  GANNTimeFrame=PERIOD_D1;
double  GANNperiod=5;
bool    useGANNBE=false;
ENUM_TIMEFRAMES  GANNBETimeFrame=PERIOD_D1;
double  gannBEperiod=5;

extern bool    useGANNMTF=false;
extern ENUM_TIMEFRAMES     gannMTFPeriod01=60;
extern ENUM_TIMEFRAMES     gannMTFPeriod02=30;
extern ENUM_TIMEFRAMES     gannMTFPeriod03=30;

bool    useGANNAutoClose=false;

bool    useTripleTFGannSide=false;
bool    useTDICross=false;
bool    useTDICrossHTF=false;
int     TDICrossHTFPeriod01=240;
int     TDICrossHTFPeriod02=1440;
int     TDICrossHTFPeriod03=10080;


double  incrementalLotMultiplier=0.5;

double sendlots;
int Ticket;
double SL,TP;
double ATRPips;
double tickvalue;

int     pips2points;    // slippage  3 pips    3=points    30=points
double  pips2dbl;       // Stoploss 15 pips    0.015      0.0150
int     pips;    // DoubleToStr(dbl/pips2dbl, Digits.pips)
int pipMult=10000;
int offlineMode=0;
int sendOrder=0;
int Count=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
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
//sendOrder=SIDE;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   int z=1;
   while(z<=8)
     {
      string ChartText=DoubleToStr(z,0); // delete function to remove text when ea is removed from the chart 
      ObjectDelete(ChartText);
      z++;

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   if(!AllowTradesByTime()) return;
   if(Time[0]>=StrToTime("2018.01.01 00:00"))
     {
      return;
     }
   if(SIDE==0)return;
   bool haveOrdersThisPair=false;
//CLEAN GLOBAL VARIABLES
   for(int ior=0; ior<OrdersTotal(); ior++)
     {
      OrderSelect(ior,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         haveOrdersThisPair=true;
         break;
        }
     }
   if(!haveOrdersThisPair)
     {
      GlobalVariablesDeleteAll(Symbol());
     }

   tickvalue=(MarketInfo(Symbol(),MODE_TICKVALUE));
   if(Digits==5 || Digits==3)
     {
      tickvalue=tickvalue*10;
     }

   if(ChannelHighLow)
     {
      if(iClose(Symbol(),ChannelHighLowTimeFrame,1)>iMA(Symbol(),ChannelHighLowTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_HIGH,2))
         sendOrder=1;
      else if(iClose(Symbol(),ChannelHighLowTimeFrame,1)<iMA(Symbol(),ChannelHighLowTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_LOW,2))
         sendOrder=-1;
     }

   if(strategyTesterDateFrom!="" && strategyTesterDateTo!="")
     {
      if(IsTesting())
        {
         if(Time[0]<=StrToTime(strategyTesterDateFrom) || Time[0]>=StrToTime(strategyTesterDateTo))
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

        {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {

            if(OrderType()==OP_SELL && haOpen<haClose)
              {
               manageBasket(true,-1);
               //sendOrder=0;
               break;
              }
            if(OrderType()==OP_BUY && haOpen>haClose)
              {
               manageBasket(true,1);
               //sendOrder=0;
               break;
              }
           }
        }
     }

   if(MaxOrdersBasket!=0)
     {
      if(calculateNumberOrdersThisPair()>=MaxOrdersBasket)return;
     }

   if(BreakEvenMode)
     {
      int sideToBE=manageOpenOrderSide();
      if(sideToBE==0) //BreakEvenMode doesn't send orders if there is no order open
        {
         return;
        }
      else
        {
         manageBasket(true,sideToBE);
        }
        }else{
      manageBasket(false,0);
     }

   if(LastTPMode)
     {
      int sideToMode=manageOpenOrderSide();
      if(sideToMode==0) //LastTPMode stop trading when there is no open orders
        {
         return;
        }
     }

   if(martingale)
     {
      int martin=manageMartingale();
      if(martin==1) return;
     }

   if(StopTradingAtLevel)
     {
      int sideToStopLevel=manageOpenOrderSide();
      if(sideToStopLevel==-1 && Bid<LevelStopTrading)
        {
         SendOrders=false;
        }
      else if(sideToStopLevel==1 && Ask>LevelStopTrading)
        {
         SendOrders=false;
        }
     }

   if(StartTradingAtLevel)
     {
      if(LevelStartTradingStop!=0)
        {
         if(SIDE==-1 && Bid<=LevelStartTradingStop)
           {
            SendOrders=true;
           }
         if(SIDE==1 && Ask>=LevelStartTradingStop)
           {
            SendOrders=true;
           }
        }

      if(LevelStartTradingLimit!=0)
        {
         if(SIDE==-1 && Bid>=LevelStartTradingLimit)
           {
            SendOrders=true;
           }
         if(SIDE==1 && Ask<=LevelStartTradingLimit)
           {
            SendOrders=true;
           }
        }
     }

   switch(sendOrder)
     {
      case 1: doStuff(1);break;
      case -1:  doStuff(-1);break;
      case 2:
         doStuff(1);
         doStuff(-1);
         break;
     }
   return;                                      // Exit start()
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doStuff(int sides)
  {
   bool send=SendOrders;
   bool orderSent=false;
   double riskcapital;
   double slpips;
   double tppips;
   MathSrand(TimeLocal());
   sendlots=Lots;
   int magicNumber=0;

   if(sides!=SIDE)
     {
      return;
     }

   if(sides==-1)
     {
      send=calcMinimalDistance(Bid,sides);
     }
   else if(sides==1)
     {
      send=calcMinimalDistance(Ask,sides);
     }
   if(!send) return;

   if(useHalfTrend)
     {
      double halfSignalUp=iCustom(NULL,PERIOD_D1,"HalfTrend-1.02_limit",2,10,true,true,false,false,false,false,false,0,1);     // Green line
      double halfSignalDown=iCustom(NULL,PERIOD_D1,"HalfTrend-1.02_limit",2,10,true,true,false,false,false,false,false,1,1);     // Green line

      printf("halfSignalUp:"+halfSignalUp);
      printf("halfSignalDown:"+halfSignalDown);
      if(halfSignalUp!=0)
        {
         closeAll(1);
        }
      if(halfSignalDown!=0)
        {
         closeAll(-1);
        }

     }

/**START GANN**/
   if(useGANN)
     {
      if(useGANNMTF)
        {
         double gannMXHTF1=iCustom(NULL,gannMTFPeriod01,"GannHiLo-Histo",ChannelHighLowPeriod,2,1); //0 atualcadle , 1 last candle
         double gannMXHTF2=iCustom(NULL,gannMTFPeriod02,"GannHiLo-Histo",ChannelHighLowPeriod,2,1); //0 atualcadle , 1 last candle
         double gannMXHTF3=iCustom(NULL,gannMTFPeriod03,"GannHiLo-Histo",ChannelHighLowPeriod,2,1); //0 atualcadle , 1 last candle
         if((gannMXHTF1==1 || gannMXHTF2==1 || gannMXHTF3==1) && sides==-1)
           { //BUY
            send=false;
           }
         else if((gannMXHTF1==-1 || gannMXHTF2==-1 || gannMXHTF3==-1) && sides==1)
           {
            send=false;
           }
        }

      if(useGANNBE)
        {
         double gannBE=iCustom(NULL,GANNBETimeFrame,"GannHiLo-Histo",gannBEperiod,2,1); //0 atualcadle , 1 last candle
         int sideOpenOrders=manageOpenOrderSide();

         if(gannBE==1 && sides==-1 && (sideOpenOrders==-1 || sideOpenOrders==2))
           { //BUY
            send=false;
            manageBasket(true,-1);
           }
         else if(gannBE==-1 && sides==1 && (sideOpenOrders==1 || sideOpenOrders==2))
           {
            send=false;
            manageBasket(true,1);
           }

/*if((sideOpenOrders==1 || sideOpenOrders==2) && gannBE==-1)
           {
            manageBasket(true,1);
            manageBasket(false,-1);
           }
         else if((sideOpenOrders==-1 || sideOpenOrders==2) && gannBE==1)
           {
            manageBasket(true,-1);
            manageBasket(false,1);
           }*/

        }
      else
        {
         double gannD1=iCustom(NULL,GANNTimeFrame,"GannHiLo-Histo",GANNperiod,2,1); //0 atualcadle , 1 last candle
         if(gannD1==1 && sides==-1)
           { //BUY
            send=false;
           }
         else if(gannD1==-1 && sides==1)
           {
            send=false;
           }
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

   if(UseIncrementalLot)
     {
      double highestLot=calcIncrementalLot(sendlots);
      printf("highestLot "+highestLot);
      //Lots=highestLot+(highestLot*incrementalLotMultiplier);
      if(highestLot!=0)
        {
         sendlots=highestLot+IncrementalLots;
        }
     }

   if(sendlots<0.01)
     {
      sendlots=0.01;
     }
   if(sendlots>MaximalLotPosition && MaximalLotPosition!=0)
     {
      sendlots=MaximalLotPosition;
     }

/**END GANN**/

   if(send)
     {
      printf("sendlots:"+sendlots);
      //BASKET MAGIC NUMBER//
      if(!GlobalVariableCheck(Symbol()+"MAGIC"))
        {
         magicNumber=MathRand();
         GlobalVariableSet(Symbol()+"MAGIC",OrderMagicNumber());
        }
      else
        {
         magicNumber=GlobalVariableGet(Symbol()+"MAGIC");
        }

      if(sides==-1) //SELL
        {
         RefreshRates();                        // Refresh rates
         TP=NULL;                                       //SL=Ask+0*Point;     // Calculating SL of opened
         SL=NULL;
         if(ATRStopLoss)
           {
            slpips=ATRPips*ATRStopLossMultiplier;
           }
         else
           {
            slpips=StopLoss;
           }
         SL=Ask+slpips*pips2dbl;
         if(slpips==0)SL=NULL;
         //slpips==0?SL=NULL:SL=SL;

         if(ATRTakeProfit)
           {
            tppips=ATRPips*ATRTakeProfitMultiplier;
           }
         else
           {
            tppips=TakeProfit;
           }
         TP=Bid-tppips*pips2dbl;
         if(tppips==0)TP=NULL;
         //tppips==0?TP=NULL:TP=TP;

         if(BasketSameStopLoss && SL!=NULL)
           {
            SL=calculateSLBasket(SL,sides);
           }
         if(UseLotsPercentSL)
           {
            riskcapital=AccountBalance()*LotsPercent/100;
            if(slpips!=0 && slpips!=NULL)
              {
               sendlots=NormalizeDouble((riskcapital/slpips)/tickvalue,2);
              }
           }
         if(martingale)
           {
            if(!GlobalVariableCheck(Symbol()+"STOP_LEVEL_BEARS"))
              {
               GlobalVariableSet(Symbol()+"STOP_LEVEL_BEARS",SL);
              }
            SL=NULL;
           }
         Ticket=OrderSend(Symbol(),OP_SELL,sendlots,Bid,2,SL,TP,NULL,magicNumber);//Opening Sell

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
            manageBasket(false,-1);
           }
        }

      if(sides==1) //BUY
        {
         RefreshRates();                        // Refresh rates
         SL=NULL;
         TP=NULL;
         if(ATRStopLoss)
           {
            slpips=ATRPips*ATRStopLossMultiplier;
           }
         else
           {
            slpips=StopLoss;
           }
         SL=Bid-slpips*pips2dbl;
         if(slpips==0)SL=NULL;
         //slpips==0?SL=NULL:SL=SL;

         if(ATRTakeProfit)
           {
            tppips=ATRPips*ATRTakeProfitMultiplier;
           }
         else
           {
            tppips=TakeProfit;
           }
         if(tppips==0)TP=NULL;
         TP=Ask+tppips*pips2dbl;
         //tppips==0?TP=NULL:TP=TP;

         if(BasketSameStopLoss && SL!=NULL)
           {
            SL=calculateSLBasket(SL,sides);
           }
         if(UseLotsPercentSL)
           {
            riskcapital=AccountBalance()*LotsPercent/100;
            if(slpips!=0 && slpips!=NULL)
              {
               sendlots=NormalizeDouble((riskcapital/slpips)/tickvalue,2);
              }

           }

         if(martingale)
           {
            if(!GlobalVariableCheck(Symbol()+"STOP_LEVEL_BULLS"))
              {
               GlobalVariableSet(Symbol()+"STOP_LEVEL_BULLS",SL);
              }
            SL=NULL;
           }
         Ticket=OrderSend(Symbol(),OP_BUY,sendlots,Ask,2,SL,TP,NULL,magicNumber);//Opening Buy
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
            manageBasket(false,1);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void manageBasket(bool breakEven,int sidesBasket)
  {
   int   nOrders=0;
   int   nOrdersSell=0;
   int   nOrdersBuy=0;
   double dOpenPriceBuy=0.0;
   double dOpenPriceSell=0.0;
   int colour;
   double TPBuy=NULL;
   double TPSell=NULL;
   double ticketMostDistantSell= 0;
   double priceMostDistantSell = 0;
   double ticketMostRecentSell=0;
   double ticketFirstSell=0;
   double priceFirstSell=0;
   double TPFirstSell=0;
   double TPMostDistantSell=0;
   double ticketMostDistantBuy=0;
   double priceMostDistantBuy=0;
   double priceFirstBuy=0;
   double TPMostDistantBuy=0;
   double ticketMostRecentBuy=0;
   double ticketFirstBuy=0;
   double TPFirstBuy=0;
   double TPLastOrder=0;
   double BELastOrder=0;
   bool   retraceOrder=false;
   bool   scaleInOrder=false;
   int ordersTotal=OrdersTotal();

   RefreshRates();
   for(int i=0; i<ordersTotal; i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         nOrders++;
         if(OrderType()==OP_SELL)
           {
            nOrdersSell++;
            dOpenPriceSell+=OrderOpenPrice();
            if(priceMostDistantSell==0 || OrderOpenPrice()>priceMostDistantSell)
              {
               ticketMostDistantSell=OrderTicket();
               priceMostDistantSell=OrderOpenPrice();
               TPMostDistantSell=OrderTakeProfit();
              }
            if(priceFirstSell==0 || OrderOpenPrice()<priceFirstSell)
              {
               TPFirstSell=OrderTakeProfit();
               priceFirstSell=OrderOpenPrice();
               ticketFirstSell=OrderTicket();
              }
            if(ticketMostRecentSell==0 || OrderTicket()>ticketMostRecentSell)
              {
               ticketMostRecentSell=OrderTicket();
              }
           }
         if(OrderType()==OP_BUY)
           {
            nOrdersBuy++;
            dOpenPriceBuy+=OrderOpenPrice();
            if(priceMostDistantBuy==0 || OrderOpenPrice()<priceMostDistantBuy)
              {
               ticketMostDistantBuy=OrderTicket();
               priceMostDistantBuy=OrderOpenPrice();
               TPMostDistantBuy=OrderTakeProfit();
              }
            if(priceFirstBuy==0 || OrderOpenPrice()>priceFirstBuy)
              {
               TPFirstBuy=OrderTakeProfit();
               priceFirstBuy=OrderOpenPrice();
               ticketFirstBuy=OrderTicket();
              }
            if(ticketMostRecentBuy==0 || OrderTicket()>ticketMostRecentBuy)
              {
               ticketMostRecentBuy=OrderTicket();
              }
           }
        }
     }
   if(sidesBasket==1)
     {
      if(ticketFirstBuy==ticketMostRecentBuy) scaleInOrder=true;
      if(ticketMostDistantBuy==ticketMostRecentBuy) retraceOrder=true;
     }
   else if(sidesBasket==-1)
     {
      if(ticketFirstSell==ticketMostRecentSell) scaleInOrder=true;
      if(ticketMostDistantSell==ticketMostRecentSell) retraceOrder=true;
     }

   double dAvgEntryPriceSell=0;
   double dAvgEntryPriceBuy=0;

   if(nOrdersSell>0)
     {
      dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
     }
   if(nOrdersBuy>0)
     {
      dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
     }

   if(breakEven)
     {
      colour=clrGold;
      if(ATRBasketBreakEven)
        {
         TPSell=dAvgEntryPriceSell-((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);
         TPBuy=dAvgEntryPriceBuy+((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2
        }
      else
        {
         TPSell=dAvgEntryPriceSell-BreakEvenPips*pips2dbl;
         TPBuy=dAvgEntryPriceBuy+BreakEvenPips*pips2dbl;//ATRTakeProfitMultiplier/2
        }
     }
   else
     {
      colour=clrLime;
      if(ATRTakeProfit)
        {
         TPSell=dAvgEntryPriceSell-((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);
         TPBuy=dAvgEntryPriceBuy+((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2TP=dAvgEntryPriceSell-((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);
        }
      else
        {
         TPSell=dAvgEntryPriceSell-TakeProfit*pips2dbl; //-((ATRPips*0.01)*pips2dbl)
         TPBuy=dAvgEntryPriceBuy+TakeProfit*pips2dbl; //+((ATRPips*0.01)*pips2dbl)
        }
     }

   for(int y=0; y<ordersTotal; y++)
     {
      OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_SELL && sidesBasket==-1) //&& nOrdersSell>=2
           {
            if(retraceOrder)
              {
               if(TPSell!=OrderTakeProfit())
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TPSell,0,colour);
                 }
              }
            else if(scaleIn && scaleInOrder && scaleInFirstTP)
              {
               if(TPFirstSell!=OrderTakeProfit())
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TPMostDistantSell,0,colour);
                 }
              }
           }
         if(OrderType()==OP_BUY && sidesBasket==1) //&& nOrdersBuy>=2
           {

            if(retraceOrder)
              {
               if(TPBuy!=OrderTakeProfit())
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TPBuy,0,colour);
                 }
              }
            else if(scaleIn && scaleInOrder && scaleInFirstTP)
              {
               if(TPMostDistantBuy!=OrderTakeProfit())
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),TPMostDistantBuy,0,colour);
                 }
              }
           }

        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int manageMartingale()
  {
   int   nOrders=0;
   int   nOrdersSell=0;
   int   nOrdersBuy=0;
   double lotsSell=0;
   double lotsBuy=0;
   double dOpenPriceBuy=0.0;
   double dOpenPriceSell=0.0;
   double TPBuy=NULL;
   double TPSell=NULL;
   double TPLastOrder=0;
   double BELastOrder=0;
   int retorno=0;
   int sendFirstSide=0;

   int ordersTotal=OrdersTotal();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(!GlobalVariableCheck(Symbol()+"MARTINGALE_ONN"))
     {
      RefreshRates();
      if(GlobalVariableCheck(Symbol()+"STOP_LEVEL_BEARS"))
        {
         if(Ask>=GlobalVariableGet(Symbol()+"STOP_LEVEL_BEARS"))
           {
            sendFirstSide=1; // OPEN BUY
            GlobalVariableSet(Symbol()+"MARTINGALE_ONN",-1);
           }
        }
      if(GlobalVariableCheck(Symbol()+"STOP_LEVEL_BULLS"))
        {
         if(Bid<=GlobalVariableGet(Symbol()+"STOP_LEVEL_BULLS"))
           {
            sendFirstSide=-1; // OPEN SELL
            GlobalVariableSet(Symbol()+"MARTINGALE_ONN",1);
           }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(GlobalVariableCheck(Symbol()+"MARTINGALE_ONN"))
     {
      retorno=1;
      if(sendFirstSide==0)
        {
         if(manageOpenOrderSide()==0)
           {
            int deleted= DeleteAllPending(Symbol());
            if(deleted!=0)
              {
               printf("sideChanged to "+deleted);
               SIDE=deleted;
               printf("sideChanged "+SIDE);
              }

           }
         if(GlobalVariableCheck(Symbol()+"TICKET_PENDING"))
           {
            if(OrderSelect(GlobalVariableGet(Symbol()+"TICKET_PENDING"),SELECT_BY_TICKET,MODE_TRADES)==true)
              {
               if(OrderType()==OP_BUY)
                 { //PENDING ACTIVATED NEED MARTINGALE
                  clearALLTPSL();
                  setALLTPSLToLVL(GlobalVariableGet(Symbol()+"AVG_TP_BUY"));
                  Ticket=OrderSend(Symbol(),OP_SELLSTOP,OrderLots()*2,GlobalVariableGet(Symbol()+"AVG_ENTRY_SELL"),2,NULL,GlobalVariableGet(Symbol()+"AVG_TP_SELL"),NULL,GlobalVariableGet(Symbol()+"MAGIC"));
                  if(Ticket>0) // Success :)
                    {
                     GlobalVariableSet(Symbol()+"TICKET_PENDING",Ticket);
                     Ticket=0;
                    }
                 }
               else if(OrderType()==OP_SELL)
                 {
                  clearALLTPSL();
                  setALLTPSLToLVL(GlobalVariableGet(Symbol()+"AVG_TP_SELL"));
                  Ticket=OrderSend(Symbol(),OP_BUYSTOP,OrderLots()*2,GlobalVariableGet(Symbol()+"AVG_ENTRY_BUY"),2,NULL,GlobalVariableGet(Symbol()+"AVG_TP_BUY"),NULL,GlobalVariableGet(Symbol()+"MAGIC"));
                  if(Ticket>0) // Success :)
                    {
                     GlobalVariableSet(Symbol()+"TICKET_PENDING",Ticket);
                     Ticket=0;
                    }
                 }
              }
           }
        }

      else //SEND FIRST ORDER AND CONFIGURE PARAMETERS
        {
         printf("sendFirstSide "+sendFirstSide);
         for(int i=0; i<ordersTotal; i++)
           {
            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderSymbol()==Symbol())
              {
               nOrders++;
               if(OrderType()==OP_SELL)
                 {
                  nOrdersSell++;
                  dOpenPriceSell+=OrderOpenPrice();
                  lotsSell+=OrderLots();
                 }
               if(OrderType()==OP_BUY)
                 {
                  nOrdersBuy++;
                  dOpenPriceBuy+=OrderOpenPrice();
                  lotsBuy+=OrderLots();
                 }
              }
           }

         double dAvgEntryPriceSell=0;
         double dAvgEntryPriceBuy=0;
         if(nOrdersSell>0)
           {
            dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
           }
         if(nOrdersBuy>0)
           {
            dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
           }

         double rangePrice = 0;
         double priceTPBuy = 0;
         double priceTPSell=0;

         //////////////BUY
         if(sendFirstSide==1)
           {
            rangePrice=Bid-dAvgEntryPriceSell;
            GlobalVariableSet(Symbol()+"rangePrice",rangePrice);

            dAvgEntryPriceBuy=dAvgEntryPriceSell+rangePrice;

            if(ATRBasketBreakEven)
              {
               priceTPSell=dAvgEntryPriceBuy-rangePrice*2-(rangePrice*ATRBasketBreakEvenMultiplier);
               priceTPBuy=dAvgEntryPriceBuy+rangePrice+(rangePrice*ATRBasketBreakEvenMultiplier);
              }
            else
              {
               priceTPSell=dAvgEntryPriceBuy-rangePrice*2-(BreakEvenPips*pips2dbl);
               priceTPBuy=dAvgEntryPriceBuy+rangePrice+(BreakEvenPips*pips2dbl);
              }

            GlobalVariableSet(Symbol()+"AVG_ENTRY_BUY",NormalizeDouble(dAvgEntryPriceBuy,Digits));
            GlobalVariableSet(Symbol()+"AVG_TP_BUY",NormalizeDouble(priceTPBuy,Digits));
            GlobalVariableSet(Symbol()+"AVG_ENTRY_SELL",NormalizeDouble(dAvgEntryPriceSell,Digits));
            GlobalVariableSet(Symbol()+"AVG_TP_SELL",NormalizeDouble(priceTPSell,Digits));

            clearALLTPSL();
            setALLTPSLToLVL(priceTPBuy);
            Ticket=OrderSend(Symbol(),OP_BUY,lotsSell*2,Ask,2,NULL,NormalizeDouble(priceTPBuy,Digits),NULL,GlobalVariableGet(Symbol()+"MAGIC"));//Opening Buy
            if(Ticket>0) // Success :)
              {
               Ticket=0;
              }
            Ticket=OrderSend(Symbol(),OP_SELLSTOP,lotsSell*4,NormalizeDouble(dAvgEntryPriceSell,Digits),2,NULL,NormalizeDouble(priceTPSell,Digits),NULL,GlobalVariableGet(Symbol()+"MAGIC"));//Opening Buy
            if(Ticket>0) // Success :)
              {
               GlobalVariableSet(Symbol()+"TICKET_PENDING",Ticket);
               Ticket=0;
              }
           }
         //////////////SELL
         else if(sendFirstSide==-1)
           {
            rangePrice=dAvgEntryPriceBuy-Ask;
            GlobalVariableSet(Symbol()+"rangePrice",rangePrice);
            dAvgEntryPriceSell=dAvgEntryPriceBuy-rangePrice;
            if(ATRBasketBreakEven)
              {
               priceTPSell=dAvgEntryPriceSell-rangePrice-(rangePrice*ATRBasketBreakEvenMultiplier);
               priceTPBuy=dAvgEntryPriceSell+rangePrice*2+(rangePrice*ATRBasketBreakEvenMultiplier);
              }
            else
              {
               priceTPSell=dAvgEntryPriceSell-rangePrice-(BreakEvenPips*pips2dbl);
               priceTPBuy=dAvgEntryPriceSell+rangePrice*2+(BreakEvenPips*pips2dbl);
              }

            GlobalVariableSet(Symbol()+"AVG_ENTRY_BUY",NormalizeDouble(dAvgEntryPriceBuy,Digits));
            GlobalVariableSet(Symbol()+"AVG_TP_BUY",NormalizeDouble(priceTPBuy,Digits));
            GlobalVariableSet(Symbol()+"AVG_ENTRY_SELL",NormalizeDouble(dAvgEntryPriceSell,Digits));
            GlobalVariableSet(Symbol()+"AVG_TP_SELL",NormalizeDouble(priceTPSell,Digits));

            clearALLTPSL();
            setALLTPSLToLVL(priceTPSell);
            Ticket=OrderSend(Symbol(),OP_SELL,lotsBuy*2,Bid,2,NULL,NormalizeDouble(priceTPSell,Digits),NULL,GlobalVariableGet(Symbol()+"MAGIC"));//Opening Buy
            if(Ticket>0) // Success :)
              {
               Ticket=0;
              }
            Ticket=OrderSend(Symbol(),OP_BUYSTOP,lotsBuy*4,NormalizeDouble(dAvgEntryPriceBuy,Digits),2,NULL,NormalizeDouble(priceTPBuy,Digits),NULL,GlobalVariableGet(Symbol()+"MAGIC"));//Opening Buy
            if(Ticket>0) // Success :)
              {
               GlobalVariableSet(Symbol()+"TICKET_PENDING",Ticket);
               Ticket=0;
              }
           }
        }
     }
   return retorno;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearALLTPSL()
  {
   for(int y=0; y<OrdersTotal(); y++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         OrderModify(OrderTicket(),OrderOpenPrice(),NULL,NULL,0);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int DeleteAllPending(string strSymbol)
  {
   bool order_select;
   int type;
   int deletedType=0;
   for(int i=0;i<OrdersTotal();i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      order_select=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(!order_select) continue;
      if(OrderSymbol()!=strSymbol) continue;

      type=OrderType();
      if(type==OP_SELLSTOP || type==OP_BUYSTOP)
        {
         if(type==OP_SELLSTOP) deletedType=1;
         if(type==OP_BUYSTOP) deletedType=-1;
         bool bOrderDelete=OrderDelete(OrderTicket(),CLR_NONE);
        }
     }
   return deletedType;
  }//end delPending
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void setALLTPSLToLVL(double lvl)
  {
   for(int y=0; y<OrdersTotal(); y++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(y,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY && Ask<=lvl && OrderTakeProfit()!=lvl)
           {
            OrderModify(OrderTicket(),OrderOpenPrice(),NULL,lvl,0);
           }
         if(OrderType()==OP_SELL && Ask<=lvl && OrderStopLoss()!=lvl)
           {
            OrderModify(OrderTicket(),OrderOpenPrice(),lvl,NULL,0);
           }
         if(OrderType()==OP_BUY && Ask>=lvl && OrderStopLoss()!=lvl)
           {
            OrderModify(OrderTicket(),OrderOpenPrice(),lvl,NULL,0);
           }
         if(OrderType()==OP_SELL && Ask>=lvl && OrderTakeProfit()!=lvl)
           {
            OrderModify(OrderTicket(),OrderOpenPrice(),NULL,lvl,0);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


void closeAll(int sides)
  {
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

      if(OrderType()==OP_BUY && sides==1)
        { // && gannW1==1  && gannW1==-1
         OrderClose(OrderTicket(),OrderLots(),Bid,5,Blue);
        }
      if(OrderType()==OP_SELL && sides==-1)
        {
         OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calcMinimalDistance(double price,int sides)
  {
   bool sendOrders=false;
   double differencePips;
   
   int   nOrders=0;
   int   nOrdersSell=0;
   int   nOrdersBuy=0;
   double dOpenPriceBuy=0.0;
   double dOpenPriceSell=0.0;
   int colour;
   double TPBuy=NULL;
   double TPSell=NULL;
   double ticketMostDistantSell= 0;
   double priceMostDistantSell = 0;
   double ticketMostRecentSell=0;
   double ticketFirstSell=0;
   double priceFirstSell=0;
   double TPFirstSell=0;
   double TPMostDistantSell=0;
   double ticketMostDistantBuy=0;
   double priceMostDistantBuy=0;
   double priceFirstBuy=0;
   double TPMostDistantBuy=0;
   double ticketMostRecentBuy=0;
   double ticketFirstBuy=0;
   double TPFirstBuy=0;
   double TPLastOrder=0;
   double BELastOrder=0;
   bool   retraceOrder=false;
   bool   scaleInOrder=false;
   int ordersTotal=OrdersTotal();
   
   if(ordersTotal==0) return true;

   RefreshRates();
   for(int i2=0; i2<ordersTotal; i2++)
     {
      OrderSelect(i2,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         nOrders++;
         if(OrderType()==OP_SELL)
           {
            nOrdersSell++;
            dOpenPriceSell+=OrderOpenPrice();
            if(priceMostDistantSell==0 || OrderOpenPrice()>priceMostDistantSell)
              {
               ticketMostDistantSell=OrderTicket();
               priceMostDistantSell=OrderOpenPrice();
               TPMostDistantSell=OrderTakeProfit();
              }
            if(priceFirstSell==0 || OrderOpenPrice()<priceFirstSell)
              {
               TPFirstSell=OrderTakeProfit();
               priceFirstSell=OrderOpenPrice();
               ticketFirstSell=OrderTicket();
              }
            if(ticketMostRecentSell==0 || OrderTicket()>ticketMostRecentSell)
              {
               ticketMostRecentSell=OrderTicket();
              }
           }
         if(OrderType()==OP_BUY)
           {
            nOrdersBuy++;
            dOpenPriceBuy+=OrderOpenPrice();
            if(priceMostDistantBuy==0 || OrderOpenPrice()<priceMostDistantBuy)
              {
               ticketMostDistantBuy=OrderTicket();
               priceMostDistantBuy=OrderOpenPrice();
               TPMostDistantBuy=OrderTakeProfit();
              }
            if(priceFirstBuy==0 || OrderOpenPrice()>priceFirstBuy)
              {
               TPFirstBuy=OrderTakeProfit();
               priceFirstBuy=OrderOpenPrice();
               ticketFirstBuy=OrderTicket();
              }
            if(ticketMostRecentBuy==0 || OrderTicket()>ticketMostRecentBuy)
              {
               ticketMostRecentBuy=OrderTicket();
              }
           }
        }
     }
//---
//---
   double dAvgEntryPriceSell=0;
   double dAvgEntryPriceBuy=0;

   if(nOrdersSell>0)
     {
      dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
     }
   if(nOrdersBuy>0)
     {
      dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
     }

   if(sides==1 && (price>priceFirstBuy || price<priceMostDistantBuy))
     {
      if(price>priceFirstBuy && scaleIn)differencePips=(price-priceFirstBuy)/pips2dbl;
      if(price<priceMostDistantBuy)differencePips=(priceMostDistantBuy-price)/pips2dbl;

      if(ATRDistanceOrders)
        {
         if(differencePips>=ATRPips*ATRMinDistanceMultiplier)
           {
            sendOrders=true;
           }
        }

      else
        {
         if(differencePips>=DistancePips)
           {
            sendOrders=true;
           }
        }
     }
     
   if(sides==-1 && (price<priceFirstSell || price>priceMostDistantSell))
     {
      
      if(price<priceFirstSell && scaleIn)differencePips=(priceFirstSell-price)/pips2dbl;
      if(price>priceMostDistantSell)differencePips=(price-priceMostDistantSell)/pips2dbl;
      
      if(ATRDistanceOrders)
        {
         if(differencePips>=ATRPips*ATRMinDistanceMultiplier) //|| differencePips > -ATRPips*ATRMinDistanceMultiplier??
           {
            sendOrders=true;
           }
        }
      else
        {
         if(differencePips>=DistancePips) //|| differencePips > -ATRPips*ATRMinDistanceMultiplier??
           {
            sendOrders=true;
           }
        }
     }
   return sendOrders;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcIncrementalLot(double lts)
  {
   lts=0;
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
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
//|                                                                  |
//+------------------------------------------------------------------+
int manageOpenOrderSide()
  {
   bool sendBuy=false;
   bool sendSell=false;
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
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
double calculateSLBasket(double stoploss,int sides)
  {
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY && sides==1) //BUY
           {
            stoploss=OrderStopLoss();
           }
         else if(OrderType()==OP_SELL && sides==-1)
           {
            stoploss=OrderStopLoss();
           } //SELL
         if(stoploss!=NULL && stoploss!=0)
           {
            break;
            return stoploss;
           }
        }
     }
   return stoploss;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateNumberOrdersThisPair()
  {
   int numbOpn=0;
   for(int i=0; i<OrdersTotal(); i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         numbOpn++;
        }
     }
   return numbOpn;
  }
//+------------------------------------------------------------------+

void commentsONchart()
  {

   string textcomment[8]; // 8 refers to the number of lines of text
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   switch(SIDE)
     {
      case 0: textcomment[1]="Side: Buy";break;
      case 1:  textcomment[1]="Side: Sell";break;
      case -1: textcomment[1]="Side: OFF";break;
     }
   textcomment[2]="---------------------------------------";
   textcomment[3]="Magic Number = 12345";
   textcomment[4]="Lot size sequence = "+DoubleToStr(OrderLots(),2);
   string signal;
   if(Close[0]>Open[1])signal="UP";
   if(Close[0]<Open[1])signal="DOWN";
   textcomment[5]="Trading Signal = "+signal;
   textcomment[6]="Price = "+DoubleToStr(Close[0],Digits);
   textcomment[7]="Profit = "+DoubleToStr(OrderProfit(),2);
   textcomment[8]="*************************";

   Count++;

   int z=1;
   int k=25; // Shifts the whole block of text up or down
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   while(z<=8) //z must be equal to or larger than the textcomment[8] in this case 8 for 8 lines of test
     {
      if(StringLen(textcomment[z])<1)
        {
         z++;

           }else{
         color textcol;
         textcol=Gray; //Basic color for all lines unless specified otherwise in lines of code below

         string font;
         font="Tahoma";//Basic font for all lines unless specified otherwise in lines of code below

         int size;
         size=8; //Default text size if not specified otherwise in lines of code 

         if(z==1){textcol=Gray;size=12;font="Arial Bold";}  // z = 1 is color/size/font controls for line 1
         if(z==2){textcol=Silver;}  // z = 2 is control of line 2 and so on down through the lines           
                                    // z = 3 is missing here so the default color size etc takes control of the 3rd line of text in this case font=Tahoma textcolor=Gray  
         if(z==4){textcol=Gold;}

         color sig;
         if(Close[0]>=Open[1])sig=Lime;
         if(Close[0]<Open[1])sig=Red;
         if(z==5){textcol=sig;size=9;font="Times";}

         if(z==6 || z==7){size=9;}

         color ColorPrice;
         double ma1=iMA(NULL,1,1,0,0,0,1);
         if(Close[0]<ma1){ColorPrice= DarkOrange;}
         if(Close[0]>ma1){ColorPrice=ForestGreen;}
         if(Close[0]==ma1){ColorPrice=Gray;}
         ma1=Close[0];

         if(z==6){textcol=ColorPrice;}

         if(z==8){textcol=CadetBlue;size=8;}

         string ChartText=DoubleToStr(z,0);
         ObjectCreate(ChartText,OBJ_LABEL,0,0,0);
         ObjectSetText(ChartText,textcomment[z],size,font,textcol);
         ObjectSet(ChartText, OBJPROP_CORNER, 1);   // controls the corner the text is put into 0=top left 1=topright 2=bottom left 3=bottom right
         ObjectSet(ChartText, OBJPROP_XDISTANCE, 8);//controls distance text block is from margin  
         ObjectSet(ChartText,OBJPROP_YDISTANCE,k);
         z++;
         k=k+15;// bigger the number the larger the gap between the lines of text
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AllowTradesByTime()
  {
   currentTime=TimeHour(TimeCurrent());
   if(StartTime==0) StartTime=24; if(FinishTime==0) FinishTime=24; if(currentTime==0) currentTime=24;

   if(StartTime<FinishTime)
      if( (currentTime < StartTime) || (currentTime >= FinishTime) ) return(false);

   if(StartTime>FinishTime)
      if( (currentTime < StartTime) && (currentTime >= FinishTime) ) return(false);

   return(true);
  }
//+------------------------------------------------------------------+
/*
void DisplayUserFeedback()
  {
   if(IsTesting()==true && IsVisualMode()==false) return;

   ScreenMessage="";

//SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=12&t=3224"+NL);
   SM("Feeling generous? Help keep the SHF going with a small Paypal donation to stevehopwoodforex@gmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);

   SM("Echo Symbol="+Symbol()+NL);
   SM("Digits="+DoubleToStr(Digits,0)+NL);
   SM("Multiplier="+DoubleToStr(point2Pip,0)+NL);

   SM("Count Historical Trades="+DoubleToStr(CountHisto(Symbol()),0)+NL);
   SM("Trade Allowed Margin="+BoolToString(CheckTradeAllowedMargin())+NL);
   if(AverageSpread==0)
     {
      GetAverageSpread();
      int left=TicksToCount-CountedTicks;
      SM("Calculating the average spread. "+DoubleToStr(left,0)+" left to count."+NL);

     }//
   else SM("Allowed Spread (in points) is = "+DoubleToStr((AverageSpread*AllowedSpreadMultiplier),0)+" Actual Spread(in points) is= "+DoubleToStr((spread),0)+NL);

   if(useAutomatedLossRecovery)
     {
      if(ALR_ActiveTrades>=1 && ALR_Active)
        {
         string ALRStatus;
         SM("Automated Loss Recovery Active"+NL);
         SM("#------ALR Progressions------#"+NL);
         for(int j=0; j<=ALR_MaxAllowedTrades; j++)
           {
            if(j<ALR_ActiveTrades)
               ALRStatus="#Closed";
            else if(j==ALR_ActiveTrades)
               ALRStatus="#Active";
            else if(j==ALR_ActiveTrades+1)
               ALRStatus="#Pending";
            else
               ALRStatus=" ";

            SM(StringConcatenate("Order #",j,"lot size: ",ALR_Lots[j],"  ",ALRStatus,NL));
           }
        }
     }//when useALR option is enabled

   Comment(ScreenMessage);

  }
*/

//////////////BKP CODE//////////////////////

//RUNNER CODE 
/*

extern bool    useRunners=true;

//START()
if(useRunners)
     {
      manageBasket(false,0);
     }
//FIM START


//DOSTUFF
if(!useRunners)
           {
            TP=Bid-tppips*pips2dbl;
           }
 
 if(!useRunners)
           {
            TP=Ask+tppips*pips2dbl;
           }          
//FIM DOSTUFF

//CALC MIN DISTANCE
if(differencePips<0)//&& useRunners
              {
               differencePips=differencePips*-1;
              }
//FIM CALC MIN DISTANCE              

//MANAGEBASKET
if(useRunners && !breakEven)
     {

      if(Ask<=TPSell && nOrdersSell>0)
        {
         //close all BUT the most distant (keep half of it open with BE)
         for(int irun4=0; irun4<OrdersTotal(); irun4++)
           {
            OrderSelect(irun4,SELECT_BY_POS,MODE_TRADES);
            if(OrderSymbol()==Symbol())
              {
               if(OrderType()==OP_SELL && OrderTicket()!=ticketMostDistantSell)
                 {
                  if(!GlobalVariableCheck(Symbol()+OrderMagicNumber()))
                    {
                     OrderClose(OrderTicket(),OrderLots(),Ask,50,Red);
                    }
                 }
               if(OrderTicket()==ticketMostDistantSell)
                 {
                  TPLastOrder = OrderOpenPrice()-((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);
                  OrderModify(OrderTicket(),OrderOpenPrice(),TPLastOrder,OrderTakeProfit(),0,colour);
                  OrderClose(OrderTicket(),NormalizeDouble(OrderLots()/2,2),Ask,50,Red);
                  GlobalVariableSet(Symbol()+OrderMagicNumber(),OrderMagicNumber());
                 }
              }
           }
        }
        
        if(Bid>=TPBuy && nOrdersBuy>0)
        {
         //close all BUT the most distant (keep half of it open with BE)
         for(int irun2=0; irun2<OrdersTotal(); irun2++)
           {
            OrderSelect(irun2,SELECT_BY_POS,MODE_TRADES);
            if(OrderSymbol()==Symbol())
              {
               if(OrderType()==OP_BUY && OrderTicket()!=ticketMostDistantBuy)
                 {
                  if(!GlobalVariableCheck(Symbol()+OrderMagicNumber()))
                    {
                     OrderClose(OrderTicket(),OrderLots(),Ask,50,Red);
                    }
                 }
               if(OrderTicket()==ticketMostDistantBuy)
                 {
                  //printf("Modificando Ticket:  +"+OrderTicket()+" Magic: "+OrderMagicNumber());
                  TPLastOrder = OrderOpenPrice()+((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);
                  OrderModify(OrderTicket(),OrderOpenPrice(),TPLastOrder,OrderTakeProfit(),0,colour);
                  OrderClose(OrderTicket(),NormalizeDouble(OrderLots()/2,2),Ask,50,Red);
                  GlobalVariableSet(Symbol()+OrderMagicNumber(),OrderMagicNumber());
                 }
              }
           }
        }
     }
//FIM MANAGEBASKET
*/
//+------------------------------------------------------------------+
///////////////////////////////DOUBLE TP LAST ORDER*************

/*
else if(test25)
     {
      //SELL
      if(Ask<=TPSell && nOrdersSell>0)
        {
         if(ATRBasketBreakEven)
           {
            BELastOrder=dAvgEntryPriceSell-((ATRPips*(ATRBasketBreakEvenMultiplier))*pips2dbl);
           }
         else
           {
            BELastOrder=dAvgEntryPriceSell-BreakEvenPips*pips2dbl;
           }
         if(ATRTakeProfit)
           {
            TPLastOrder=dAvgEntryPriceSell-((ATRPips*(ATRBasketTakeProfitMultiplier*2))*pips2dbl);
           }
         else
           {
            TPLastOrder=dAvgEntryPriceSell-(TakeProfit*2)*pips2dbl;
           }
         double orderTickets[100];
         int numberTotalOrders=0;
         //close all BUT the most distant (keep half of it open with BE)
         for(int irun4=0; irun4<ordersTotal; irun4++)
           {
            orderTickets[irun4]=OrderTicket();
           }
         for(int irun51=0; irun51<ordersTotal; irun51++)
           {
            OrderSelect(orderTickets[irun51],SELECT_BY_TICKET,MODE_TRADES);
            if(OrderSymbol()==Symbol())
              {
               if(OrderType()==OP_SELL && OrderTicket()!=ticketMostDistantSell)
                 {
                  if(!GlobalVariableCheck(Symbol()+OrderMagicNumber()))
                    {
                     OrderClose(OrderTicket(),OrderLots(),Ask,50,Red);
                    }
                 }
               if(OrderTicket()==ticketMostDistantSell)
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),BELastOrder,TPLastOrder,0,colour);
                  OrderClose(OrderTicket(),NormalizeDouble(OrderLots()/2,2),Ask,50,Red);
                  GlobalVariableSet(Symbol()+OrderMagicNumber(),OrderMagicNumber());
                 }
              }
           }
        }
     }
     
     
     */
//+------------------------------------------------------------------+
//TDI BKP///

////
