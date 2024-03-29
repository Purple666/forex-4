//|   Mokuro89 Expert                                                |
//|   Copyright © 2016 / mokuro89@gmail.com                          |

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
extern bool useConfig=false;
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
extern double  DDProffitFactor=0.9;
extern double  riskMoney=0;
extern double  riskPercentage=0;

string  stopLossLegend="=======STOP LOSS=======";
double  StopLoss=0;
double  ATRStopLossMultiplier=0;
bool    BasketSameStopLoss=true;

string  lotsLegend="=======LOTS=======";
double  Lots=0.01;
double  MaximalLotPosition=0.00;
extern double  IncrementalSkippedDistanceMultiplier=1;

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

extern bool    useGANN=false;
extern ENUM_TIMEFRAMES  GANNTimeFrame=PERIOD_D1;

bool    SendNotifications=true;
bool    SendOrders=true;

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
int minuteRead=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
//Print(MarketInfo(Symbol(),MODE_LOTSIZE));
//Print(MarketInfo(Symbol(),MODE_MINLOT));
//Print(MarketInfo(Symbol(),MODE_LOTSTEP));
//Print(MarketInfo(Symbol(),MODE_MAXLOT));
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

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   SIDE=TradeType;
   if(sendOrder==0)sendOrder=TradeType;
   if(gann02LastValue==0)gann02LastValue=TradeType;

   if(!AllowTradesByTime()) return;

   if(ATRPips==0)
     {
      printf("ATRPips is null! Update your chart history.");
      return;
     }
   if(Time[0]>=StrToTime("2018.01.01 00:00"))
     {
      return;
     }

   bool haveOrdersThisPair=false;
   double nrOrdersThisPair=0;

   if(minuteRead!=TimeMinute(TimeCurrent()))
     {
      minuteRead=TimeMinute(TimeCurrent());
      if(!IsTesting() && useConfig)
        {
         int Handle;                          // Style of vertical line
         string File_Name="Mokuro_EA_config.csv";        // Name of the file
         string text;
         //AlertSellPairs=NULL;
         //AlertBuyPairs=NULL;
         Handle=FileOpen(File_Name,FILE_CSV|FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE,";");// File opening
         if(Handle<0) // File opening fails
           {
            if(GetLastError()==4103) // If the file does not exist,..
               Alert("No file named ",File_Name);//.. inform trader
            else                             // If any other error occurs..
            Alert("Error while opening file ",File_Name);//..this message
            //PlaySound("Bzrrr.wav");          // Sound accompaniment
            return;                          // Exit start()      
           }

         while(FileIsEnding(Handle)==false)  // While the file pointer..
           {                                 // ..is not at the end of the file

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
               if(k>0)
                 {
                  if(result[1]=="BEARS")
                    {
                     //AlertSellPairs=Symbol();
                     TradeType=-1;
                    }
                  else if(result[1]=="BULLS")
                    {
                     //AlertBuyPairs=Symbol();
                     TradeType=1;
                    }
                  riskPips=result[2];
                  BreakEvenMode=result[3];
                  LastTPMode=result[4];
                  //Comment(StringFormat("Show prices\nAsk = %G\nBid = %G\nSpread = %d",Ask,Bid,Spread)); 
                 }
              }
           }
         FileClose(Handle);                // Close file
        }
     }
   
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

      if(riskMoney>0)
        {
         if(Drawdown*-1>=riskMoney)
           {
            closeAll(-1);
            closeAll(1);
           }
        }
      if(riskPercentage>0)
        {
         if(Drawdown*-1>=((AccountBalance()+AccountCredit())*riskPercentage)/100)
           {
            closeAll(-1);
            closeAll(1);
           }
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

   if(useGANN)
     {
      if(Ask>iMA(Symbol(),GANNTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_HIGH,1))
         gann02LastValue=1;
      else if(Bid<iMA(Symbol(),GANNTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_LOW,1))
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
      if(riskMoney>0)
        {
         riskcapital=riskMoney;
        }
      if(riskPercentage>0)
        {
         riskcapital=((AccountBalance()+AccountCredit())*riskPercentage)/100;
        }
      double totalLoss=0;
      double partialDistance=0;

      for(int x=0; x<=riskPips; x++)
        {
         if(partialDistance>riskPips)break;

         totalLoss+=(riskPips-(ATRPips*ATRMinDistanceMultiplier));
         partialDistance+=(ATRPips*ATRMinDistanceMultiplier);
        }
      sendlots=riskcapital/totalLoss/tickvalue;
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

   if(useGANN)
     {
      if((sides==-1 && gann02LastValue==1) || (sides==1 && gann02LastValue==-1))
        {
         return;
        }
      if(Bid<=iMA(Symbol(),GANNTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_LOW,1) && sides==1 && gann02LastValue==1)
        {
         return;
        }
      else if(Bid>=iMA(Symbol(),GANNTimeFrame,ChannelHighLowPeriod,0,MODE_SMA,PRICE_HIGH,1) && sides==-1 && gann02LastValue==-1)
        {
         return;
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
void closeAll(int sides)
  {
   int total= OrdersTotal();
   for(int i=total-1;i>=0;i--)
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
int manageOpenOrderSide()
  {
   bool sendBuy=false;
   bool sendSell=false;
   for(int i=0; i<OrdersTotal(); i++)

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
   if(sendBuy && sendSell)
     {
      return 2;
        }else if(sendBuy && !sendSell){
      return 1;
        }else if(sendSell && !sendBuy){
      return -1;
        }else {
      return 0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateSLBasket(double stoploss,int sides)
  {
   for(int i=0; i<OrdersTotal(); i++)
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
void CommentLab(string CommentText)
   {
   string CommentLabel;
   int CommentIndex = 0;
   
   if (CommentText == "")
      {
      //  delete all Comment texts
      while(ObjectFind(StringConcatenate("CommentLabel", CommentIndex )) >= 0)
         {
         ObjectDelete(StringConcatenate("CommentLabel", CommentIndex ));
         CommentIndex++;
         }
      return;
      }
   
   while(ObjectFind(StringConcatenate("CommentLabel", CommentIndex )) >= 0)
      {
      CommentIndex++;
      }
      
   CommentLabel = StringConcatenate("CommentLabel", CommentIndex);  
   ObjectCreate(CommentLabel, OBJ_LABEL, 0, 0, 0 );
   ObjectSet(CommentLabel, OBJPROP_CORNER, 0);
   ObjectSet(CommentLabel, OBJPROP_XDISTANCE, 5);
   ObjectSet(CommentLabel, OBJPROP_YDISTANCE, 15 + (CommentIndex * 15) );
   ObjectSetText(CommentLabel, CommentText, 10, "Tahoma", clrRed );   
   
   }