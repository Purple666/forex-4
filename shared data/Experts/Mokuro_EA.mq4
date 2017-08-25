//+------------------------------------------------------------------+
//|   Mokuro89 Expert                                                |
//|                                                                  |
//|   Copyright © 2016 / mokuro89@gmail.com                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "2016-2017, Mokuro89."
#property link        "mokuro89@gmail.com"


bool    scaleInFirstTP=true;

string  sideLegend="=======| 1 BUY | -1 SELL |=======";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum sideEnum
  {
   OFF=0,  //OFF
   BUY=1,  //BUY
   SELL=-1  //SELL
  };
extern sideEnum TradeType=OFF;
extern double  riskPips=0;
double riskDivisor=1;
int     SIDE=0;
ENUM_TIMEFRAMES ATRperiod=PERIOD_D1;
int     MaxOrdersBasket=0;
int     MinMinutesBetweenOrders=5;

string  distanceLegend="=======ORDERS DISTANCE=======";
double  DistancePips=5;
extern double  ATRMinDistanceMultiplier=0.25;

string  takeProfitLegend="=======TAKE PROFFIT=======";
double  TakeProfit=0;
double  ATRTakeProfitMultiplier=5;
double  ATRBasketTakeProfitMultiplier=ATRTakeProfitMultiplier;
double  BasketExtraMultiplier=0;
extern double  DDProffitFactor=0.9;

string  stopLossLegend="=======STOP LOSS=======";
double  StopLoss=0;
double  ATRStopLossMultiplier=0;
bool    BasketSameStopLoss=true;

string  lotsLegend="=======LOTS=======";
double  Lots=0.01;
double  IncrementalLots=0;
double  IncrementalLotsMultiplier=1.1;
double  MaximalLotPosition=0.00;
double  IncrementalSkippedDistanceMultiplier=1;

string  triggersLegend="=======TRIGGERS=======";
bool    ChannelHighLow=true;
ENUM_TIMEFRAMES ChannelHighLowTimeFrame=PERIOD_M5;
double  ChannelHighLowPeriod=5;

string  modesLegend="=======MODES=======";
extern bool    BreakEvenMode=false;
double  BreakEvenPips=5;
double  ATRBasketBreakEvenMultiplier=0.1;
bool    scaleIn=false;

string  startStopLlvlLegends="***Start/Stop trading at Level***";
extern bool    LastTPMode=false;
double  LevelStopTrading=0;

double  LevelStartTradingLimit=0;
double  LevelStartTradingStop=0;

string  timeLegends="***Trading Time in 24HOURS FORMAT***";
int StartTime=0;          // Time to allow trading to start ( hours of 24 hr clock ) 0 for both disables
int FinishTime=0;

int currentTime=0;
string  strategyTesterLegend="DATEFORMAT EXAMPLE: 2017.03.01 09:00";
string  strategyTesterDateFrom="";
string  strategyTesterDateTo="";

bool    useGANN=false;
extern bool    useGANN02=false;
ENUM_TIMEFRAMES  GANNTimeFrame=PERIOD_D1;
extern ENUM_TIMEFRAMES  GANN02TimeFrame=PERIOD_D1;
double GANNperiod=5;

bool    useGANNMTF=false;
ENUM_TIMEFRAMES     gannMTFPeriod01=60;
ENUM_TIMEFRAMES     gannMTFPeriod02=30;
ENUM_TIMEFRAMES     gannMTFPeriod03=30;
bool    SendNotifications=true;
bool    SendOrders=true;

bool    useGANNAutoClose=false;

double Drawdown,WorstDrawdown;

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
bool osb;
int gann02LastValue=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
//Print(MarketInfo(Symbol(),MODE_LOTSIZE));
//Print(MarketInfo(Symbol(),MODE_MINLOT));
//Print(MarketInfo(Symbol(),MODE_LOTSTEP));
//Print(MarketInfo(Symbol(),MODE_MAXLOT));
   if(SIDE==0)SIDE=TradeType;
   if(sendOrder==0)sendOrder=TradeType;
   if(gann02LastValue==0)gann02LastValue=TradeType;
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

   if(ATRPips==0)
     {
      printf("ATRPips is null!!");
      return;
     }
   if(Time[0]>=StrToTime("2018.01.01 00:00"))
     {
      return;
     }

   bool haveOrdersThisPair=false;
   double nrOrdersThisPair=0;

   if(riskPips<=0)
     {
      printf("riskPips must be greater than 0!!");
      return;
     }

//CLEAN GLOBAL VARIABLES BLOCK
   for(int ior=0; ior<OrdersTotal(); ior++)
     {
      osb=OrderSelect(ior,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         nrOrdersThisPair++;
        }
     }
   if(nrOrdersThisPair==0)
     {
      GlobalVariablesDeleteAll(Symbol());
     }
//END CLEAN GLOBAL VARIABLES BLOCK

   tickvalue=(MarketInfo(Symbol(),MODE_TICKVALUE));
   if(Digits==5 || Digits==3)
     {
      tickvalue=tickvalue*10;
     }

   if(DDProffitFactor!=0 && OrdersTotal()>=1)
     {
      Drawdown=AccountEquity()-(AccountBalance()+AccountCredit());
      GlobalVariableSet(Symbol()+"Drawdown",Drawdown);
      if(Drawdown<WorstDrawdown) //&& Drawdown<0
        {
         WorstDrawdown=Drawdown;
         GlobalVariableSet(Symbol()+"WorstDD",Drawdown);
        }
      if(GlobalVariableCheck(Symbol()+"WorstDD"))
        {
         WorstDrawdown=GlobalVariableGet(Symbol()+"WorstDD");
        }

      if(WorstDrawdown!=0 && WorstDrawdown!=NULL && WorstDrawdown/DDProffitFactor<0 && Drawdown>0 && Drawdown*-1<=WorstDrawdown/DDProffitFactor) //&& WorstDrawdown*-1 >= (AccountBalance()/1000)
        {
         if(OrdersTotal()==1)
           {
            double close=false;
            osb=OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
            if(OrderType()==OP_SELL)
              {
               if(Ask<OrderOpenPrice()-ATRPips*ATRMinDistanceMultiplier*pips2dbl)
                 {
                  close=true;
                 }
              }
            else if(OrderType()==OP_BUY)
              {
               if(Bid>OrderOpenPrice()+ATRPips*ATRMinDistanceMultiplier*pips2dbl)
                 {
                  close=true;
                 }

              }
            if(close)
              {
               closeAll(1);
               closeAll(-1);
               WorstDrawdown=0;
              }
           }
         else
           {
            closeAll(1);
            closeAll(-1);
            WorstDrawdown=0;
           }
        }
     }

   if(ChannelHighLow)
     {
      if(iClose(Symbol(),ChannelHighLowTimeFrame,1)>iMA(Symbol(),ChannelHighLowTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_HIGH,1))
         sendOrder=1;
      else if(iClose(Symbol(),ChannelHighLowTimeFrame,1)<iMA(Symbol(),ChannelHighLowTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_LOW,1))
         sendOrder=-1;
     }

   if(useGANN02)
     {
      if(Ask>iMA(Symbol(),GANN02TimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_HIGH,1))
         gann02LastValue=1;
      else if(Bid<iMA(Symbol(),GANN02TimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_LOW,1))
         gann02LastValue=-1;
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
         if(AccountEquity()>=(AccountBalance()+AccountCredit()))
           {
            closeAll(-1);
            closeAll(1);
            WorstDrawdown=0;
            return;
           }
        }
     }

   if(LastTPMode)
     {
      int sideToMode=manageOpenOrderSide();
      if(sideToMode==0) //LastTPMode stop trading when there is no open orders
        {
         return;
        }
     }

   if(LevelStopTrading!=0)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doStuff(int sides)
  {
   bool send=SendOrders;
   bool orderSent=false;
   double slpips;
   double tppips;
   MathSrand(TimeLocal());
   int magicNumber=0;

   sendlots=Lots;
   if(sides!=SIDE && SIDE!=2)
     {
      return;
     }
   if(riskPips!=0)
     {
      tickvalue=(MarketInfo(Symbol(),MODE_TICKVALUE));
      if(Digits==5 || Digits==3)
        {
         tickvalue=tickvalue*10;
        }
      double riskcapital=(AccountBalance()+AccountCredit())/riskDivisor;
      double totalLoss=0;
      double partialDistance=0;

      for(int x=0; x<=riskPips; x++)
        {

         if(partialDistance>riskPips)break;

         totalLoss+=(riskPips-(ATRPips*ATRMinDistanceMultiplier));
         partialDistance+=(ATRPips*ATRMinDistanceMultiplier);
        }
      sendlots=riskcapital/totalLoss/tickvalue;
      //sendlots=sendlots*1.3;
     }
   

   if(sides==-1)
     {
      send=calcMinimalDistanceAndTime(Bid,sides);
     }
   else if(sides==1)
     {
      send=calcMinimalDistanceAndTime(Ask,sides);
     }
   if(!send) return;

   if(useGANN02)
     {
      if((sides==-1 && gann02LastValue==1) || (sides==1 && gann02LastValue==-1))
        {
         return;
        }
      if(Bid<=iMA(Symbol(),GANN02TimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_LOW,1) && sides==1 && gann02LastValue==1)
         return;
      else if(Bid>=iMA(Symbol(),GANN02TimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_HIGH,1) && sides==-1 && gann02LastValue==-1)
                   return;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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

      double gannD1=iCustom(NULL,GANNTimeFrame,"GannHiLo-Histo",GANNperiod,2,1); //0 atualcadle , 1 last candle
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
            osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
            if(OrderSymbol()==Symbol())
              {
               RefreshRates();
               if(OrderType()==OP_BUY && gannD1==-1)
                 { // && gannW1==1  && gannW1==-1
                  osb=OrderClose(OrderTicket(),OrderLots(),Bid,5,Blue);
                 }
               if(OrderType()==OP_SELL && gannD1==1)
                 {
                  osb=OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
                 }
              }
           }
        }
     }
/**END GANN**/

   if(IncrementalLots!=0)
     {
      double highestLot=calcIncrementalLot(sendlots);
      if(highestLot!=0)
        {
         sendlots=highestLot+IncrementalLots;
         sendlots=NormalizeDouble(sendlots*IncrementalLotsMultiplier,2);
        }
     }
   if(IncrementalSkippedDistanceMultiplier!=0)
     {
      if(sides==-1)
        {
         sendlots=NormalizeDouble(sendlots*calcIncrementalSkippedDistanceMultiplier(Bid,sides)*IncrementalSkippedDistanceMultiplier,2);
        }
      else if(sides==1)
        {
         sendlots=NormalizeDouble(sendlots*calcIncrementalSkippedDistanceMultiplier(Ask,sides)*IncrementalSkippedDistanceMultiplier,2);
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
   if(sendlots>MarketInfo(Symbol(),MODE_MAXLOT))
     {
      sendlots=MarketInfo(Symbol(),MODE_MAXLOT);

     }
////END IncrementalSkippedDistance BLOCK

   if(send)
     {
      //BASKET MAGIC NUMBER//
      if(!GlobalVariableCheck(Symbol()+"MAGIC"))
        {
         magicNumber=MathRand();
         GlobalVariableSet(Symbol()+"MAGIC",magicNumber);
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
         if(ATRStopLossMultiplier!=0)
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

         if(ATRTakeProfitMultiplier!=0)
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
/*if(ObjectFind("TPDOT")!=-1)
           {
            ObjectDelete("TPDOT");
           }*/
         //ObjectCreate("TPDOT",OBJ_TEXT,0,Time[1],TP);
         //ObjectSetText("TPDOT",CharToStr(159),14,"Wingdings",Red);
         Ticket=OrderSend(Symbol(),OP_SELL,sendlots,Bid,2,SL,NULL,NULL,magicNumber);//Opening Sell

         if(Ticket>0) // Success :)
           {
            orderSent=true;
            if(SendNotifications)
              {
               SendNotification("Short open "+Symbol());
              }
           }
         if(orderSent)
           {
            //manageBasket(false,-1);
           }
        }

      if(sides==1) //BUY
        {
         RefreshRates();                        // Refresh rates
         SL=NULL;
         TP=NULL;
         if(ATRStopLossMultiplier!=0)
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

         if(ATRTakeProfitMultiplier!=0)
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
/*if(ObjectFind("TPDOT")!=-1)
           {
            ObjectDelete("TPDOT");
           }*/
         //ObjectCreate("TPDOT",OBJ_TEXT,0,Time[1],TP);
         //ObjectSetText("TPDOT",CharToStr(159),14,"Wingdings",Red);
         Ticket=OrderSend(Symbol(),OP_BUY,sendlots,Ask,2,SL,NULL,NULL,magicNumber);//Opening Buy
         if(Ticket>0) // Success :)
           {
            orderSent=true;
            if(SendNotifications)
              {
               SendNotification("Long open "+Symbol());
              }
           }
         if(orderSent)
           {
            //manageBasket(false,1);
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
   bool resultOrder=false;

   RefreshRates();
   for(int i=0; i<ordersTotal; i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())//StringFind(GlobalVariableGet(Symbol()+"TicketsRunning"),OrderTicket(),0)==-1) && OrderTakeProfit()!=NULL
         //&& OrderMagicNumber()==GlobalVariableGet(Symbol()+"MAGIC")
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

               if(TPMostDistantSell==NULL)
                 {
                  TPMostDistantSell=GlobalVariableGet(Symbol()+"TPMostDistantSell");
                    } else {
                  GlobalVariableSet(Symbol()+"TPMostDistantSell",TPMostDistantSell);
                 }

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

               if(TPMostDistantBuy==NULL)
                 {
                  TPMostDistantBuy=GlobalVariableGet(Symbol()+"TPMostDistantBuy");
                    } else {
                  GlobalVariableSet(Symbol()+"TPMostDistantBuy",TPMostDistantBuy);
                 }

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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(sidesBasket==1)
     {
      if(ticketFirstBuy==ticketMostRecentBuy)
        {
         scaleInOrder=true;
        }
      else if(ticketMostDistantBuy==ticketMostRecentBuy)
        {
         retraceOrder=true;
        }
      //if(ticketMostDistantBuy==ticketMostRecentBuy) retraceOrder=true;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else if(sidesBasket==-1)
     {
      if(ticketFirstSell==ticketMostRecentSell)
        {
         scaleInOrder=true;
        }
      else if(ticketMostDistantSell==ticketMostRecentSell)
        {
         retraceOrder=true;
        }
      //if(ticketMostDistantSell==ticketMostRecentSell) retraceOrder=true;
     }

   double dAvgEntryPriceSell=0;
   double dAvgEntryPriceBuy=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(nOrdersSell>0)
     {
      dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(nOrdersBuy>0)
     {
      dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(breakEven)
     {
      colour=clrGold;
      if(ATRBasketBreakEvenMultiplier!=0)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else
     {
      colour=clrLime;
      if(ATRTakeProfitMultiplier!=0)
        {
         TPSell=dAvgEntryPriceSell-((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);
         TPBuy=dAvgEntryPriceBuy+((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);//ATRTakeProfitMultiplier/2TP=dAvgEntryPriceSell-((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);
         TPMostDistantSell=priceMostDistantSell-((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);
         TPMostDistantBuy=priceMostDistantBuy+((ATRPips*(ATRBasketTakeProfitMultiplier))*pips2dbl);
         if(BasketExtraMultiplier!=0)
           {
            TPSell=TPSell-BasketExtraMultiplier*ATRPips*ATRBasketTakeProfitMultiplier*pips2dbl*nOrdersSell;
            TPBuy=TPBuy+BasketExtraMultiplier*ATRPips*ATRBasketTakeProfitMultiplier*pips2dbl*nOrdersBuy;
            TPMostDistantSell=TPMostDistantSell-BasketExtraMultiplier*ATRPips*ATRBasketTakeProfitMultiplier*pips2dbl*nOrdersSell;
            TPMostDistantBuy=TPMostDistantBuy+BasketExtraMultiplier*ATRPips*ATRBasketTakeProfitMultiplier*pips2dbl*nOrdersBuy;
           }
         if(ATRBasketTakeProfitMultiplier==0)
           {
            TPBuy=NULL;TPSell=NULL;TPMostDistantBuy=NULL;TPMostDistantSell=NULL;
           }
        }
      else
        {
         TPSell=dAvgEntryPriceSell-TakeProfit*pips2dbl; //-((ATRPips*0.01)*pips2dbl)
         TPBuy=dAvgEntryPriceBuy+TakeProfit*pips2dbl; //+((ATRPips*0.01)*pips2dbl)
         TPMostDistantSell=priceMostDistantSell-TakeProfit*pips2dbl; //-((ATRPips*0.01)*pips2dbl)
         TPMostDistantBuy=priceMostDistantBuy+TakeProfit*pips2dbl; //+((ATRPips*0.01)*pips2dbl)
         if(BasketExtraMultiplier!=0)
           {
            TPSell=TPSell-BasketExtraMultiplier*TakeProfit*pips2dbl*nOrdersSell;
            TPBuy=TPBuy+BasketExtraMultiplier*TakeProfit*pips2dbl*nOrdersBuy;
            TPMostDistantSell=TPMostDistantSell-BasketExtraMultiplier*TakeProfit*pips2dbl*nOrdersSell;
            TPMostDistantBuy=TPMostDistantBuy+BasketExtraMultiplier*TakeProfit*pips2dbl*nOrdersBuy;
           }

         if(TakeProfit==0)
           {
            TPBuy=NULL;TPSell=NULL;TPMostDistantBuy=NULL;TPMostDistantSell=NULL;
           }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectFind("TPDOT")!=-1)
     {
      ObjectDelete("TPDOT");
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(retraceOrder)
     {
      if(sidesBasket==-1)
        {
         ObjectCreate("TPDOT",OBJ_TEXT,0,Time[1],TPSell);
        }
      else if(sidesBasket==1)
        {
         ObjectCreate("TPDOT",OBJ_TEXT,0,Time[1],TPBuy);
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else if(scaleInOrder)
     {
      if(sidesBasket==-1)
        {
         ObjectCreate("TPDOT",OBJ_TEXT,0,Time[1],TPMostDistantSell);
        }
      else if(sidesBasket==1)
        {
         ObjectCreate("TPDOT",OBJ_TEXT,0,Time[1],TPMostDistantBuy);
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(ObjectFind("TPDOT")==0)
     {
      ObjectSetText("TPDOT",CharToStr(159),14,"Wingdings",Green);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


void closeAll(int sides)
  {
   int total= OrdersTotal();
   for(int i=total-1;i>=0;i--)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

      if(OrderType()==OP_BUY && sides==1)
        { // && gannW1==1  && gannW1==-1
         osb=OrderClose(OrderTicket(),OrderLots(),Bid,50,Blue);
        }
      if(OrderType()==OP_SELL && sides==-1)
        {
         osb=OrderClose(OrderTicket(),OrderLots(),Ask,50,Red);
        }
     }
   GlobalVariablesDeleteAll(Symbol());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calcMinimalDistanceAndTime(double price,int sides)
  {
   bool sendOrders=false;
   double differencePips;

   int   nOrders=0;
   int   nOrdersSell=0;
   int   nOrdersBuy=0;
   double dOpenPriceBuy=0.0;
   double dOpenPriceSell=0.0;
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
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      osb=OrderSelect(i2,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())//&& StringFind(GlobalVariableGet(Symbol()+"TicketsRunning"),OrderTicket(),0)==-1)
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
         if(MinMinutesBetweenOrders!=0)
           {
            if((TimeCurrent()-OrderOpenTime())/60<MinMinutesBetweenOrders) return false;
           }
        }
     }
//---
//---
   double dAvgEntryPriceSell=0;
   double dAvgEntryPriceBuy=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(nOrdersSell>0)
     {
      dAvgEntryPriceSell=dOpenPriceSell/nOrdersSell;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(nOrdersBuy>0)
     {
      dAvgEntryPriceBuy=dOpenPriceBuy/nOrdersBuy;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(sides==1 && (price>priceFirstBuy || price<priceMostDistantBuy))
     {
      if(price>priceFirstBuy && scaleIn)differencePips=(price-priceFirstBuy)/pips2dbl;
      if(price<priceMostDistantBuy)differencePips=(priceMostDistantBuy-price)/pips2dbl;

      if(ATRMinDistanceMultiplier!=0)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(sides==-1 && (price<priceFirstSell || price>priceMostDistantSell))
     {

      if(price<priceFirstSell && scaleIn)differencePips=(priceFirstSell-price)/pips2dbl;
      if(price>priceMostDistantSell)differencePips=(price-priceMostDistantSell)/pips2dbl;

      if(ATRMinDistanceMultiplier!=0)
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
double calcIncrementalSkippedDistanceMultiplier(double price,int sides)
  {
   bool sendOrders=false;
   int   nOrders=0;
   int   nOrdersSell=0;
   int   nOrdersBuy=0;
   double dOpenPriceBuy=0.0;
   double dOpenPriceSell=0.0;
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
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      osb=OrderSelect(i2,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())//&& StringFind(GlobalVariableGet(Symbol()+"TicketsRunning"),OrderTicket(),0)==-1)
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
           }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(sides==1 && price<priceMostDistantBuy)
     {
      if(ATRMinDistanceMultiplier!=0)
        {
         return ((priceMostDistantBuy-price)/pips2dbl)/(ATRPips*ATRMinDistanceMultiplier);
        }
      else
        {
         return ((priceMostDistantBuy-price)/pips2dbl)/DistancePips;
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(sides==-1 && price>priceMostDistantSell)
     {

      if(ATRMinDistanceMultiplier!=0)
        {
         return ((price-priceMostDistantSell)/pips2dbl)/(ATRPips*ATRMinDistanceMultiplier);
        }
      else
        {
         return ((price-priceMostDistantSell)/pips2dbl)/DistancePips;
        }
     }
   return 1;
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
      osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
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
      osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
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
      osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==GlobalVariableGet(Symbol()+"MAGIC"))
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
      osb=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
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
