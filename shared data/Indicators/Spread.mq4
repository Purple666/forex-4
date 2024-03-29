//+------------------------------------------------------------------+
//|   Mokuro89 Spread Monitor                                        |
//|                                                                  |
//|   Copyright © 2016 / mokuro89@gmail.com                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "2016-2017, Mokuro89."
#property link        "mokuro89@gmail.com"

#property indicator_chart_window

extern double percentSL=5;
extern color font_color=MediumVioletRed;
extern int font_size=10;
extern string font_face="Calibri Bold";
extern int corner=1; //0 - for top-left corner, 1 - top-right, 2 - bottom-left, 3 - bottom-right
extern int spread_distance_x = 10;
extern int spread_distance_y = 130;
extern bool normalize=false; //If true then the spread is normalized to traditional pips
extern double stopLoss = 0;
extern double distanceOrders = 0;

double Poin;
int n_digits=0;
double divider=1;
int            TxtSize       = 10;
int            EventSpacer   = 4;

int pipMult;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//Checking for unconvetional Point digits number
   if(Point==0.00001) Poin=0.0001; //5 digits
   else if(Point==0.001) Poin=0.01; //3 digits
   else Poin=Point; //Normal
   int curY = spread_distance_y;

   ObjectCreate("Spread",OBJ_LABEL,0,0,0);
   ObjectSet("Spread",OBJPROP_CORNER,corner);
   ObjectSet("Spread",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("Spread",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("BullLots",OBJ_LABEL,0,0,0);
   ObjectSet("BullLots",OBJPROP_CORNER,corner);
   ObjectSet("BullLots",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("BullLots",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("BearLots",OBJ_LABEL,0,0,0);
   ObjectSet("BearLots",OBJPROP_CORNER,corner);
   ObjectSet("BearLots",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("BearLots",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("TotalOrders",OBJ_LABEL,0,0,0);
   ObjectSet("TotalOrders",OBJPROP_CORNER,corner);
   ObjectSet("TotalOrders",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("TotalOrders",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("Risk",OBJ_LABEL,0,0,0);
   ObjectSet("Risk",OBJPROP_CORNER,corner);
   ObjectSet("Risk",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("Risk",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("H4ATR",OBJ_LABEL,0,0,0);
   ObjectSet("H4ATR",OBJPROP_CORNER,corner);
   ObjectSet("H4ATR",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("H4ATR",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("D1ATR",OBJ_LABEL,0,0,0);
   ObjectSet("D1ATR",OBJPROP_CORNER,corner);
   ObjectSet("D1ATR",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("D1ATR",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("W1ATR",OBJ_LABEL,0,0,0);
   ObjectSet("W1ATR",OBJPROP_CORNER,corner);
   ObjectSet("W1ATR",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("W1ATR",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("MaxLots",OBJ_LABEL,0,0,0);
   ObjectSet("MaxLots",OBJPROP_CORNER,corner);
   ObjectSet("MaxLots",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("MaxLots",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("StopLossPips",OBJ_LABEL,0,0,0);
   ObjectSet("StopLossPips",OBJPROP_CORNER,corner);
   ObjectSet("StopLossPips",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("StopLossPips",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("DistanceOrders",OBJ_LABEL,0,0,0);
   ObjectSet("DistanceOrders",OBJPROP_CORNER,corner);
   ObjectSet("DistanceOrders",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("DistanceOrders",OBJPROP_YDISTANCE,curY);
   curY=curY+TxtSize+EventSpacer;
   ObjectCreate("TotalPipsRisk",OBJ_LABEL,0,0,0);
   ObjectSet("TotalPipsRisk",OBJPROP_CORNER,corner);
   ObjectSet("TotalPipsRisk",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSet("TotalPipsRisk",OBJPROP_YDISTANCE,curY);
   
   
   //SPREAD//
   double spread=MarketInfo(Symbol(),MODE_SPREAD);

   if((Poin>Point) && (normalize))
     {
      divider=10.0;
      n_digits=1;
     }
   pipMult=10000;
   if(StringFind(Symbol(),"JPY",0)!=-1)
     {
      pipMult=100;
     }
   double tickvalue=(MarketInfo(Symbol(),MODE_TICKVALUE));
   if(Digits==5 || Digits==3)
     {
      tickvalue=tickvalue*10;
     }
   
   double atrD1Value = MathCeil(pipMult * (iATR(NULL,1440,54,0)));
   double atrH4Value = MathCeil(pipMult * (iATR(NULL,240,54,0)));

   double riskcapital=AccountBalance()*percentSL/100;
   double riskLots=(riskcapital/(atrH4Value*2.5))/tickvalue;
   double riskLots2=(riskcapital/(atrD1Value*2.5))/tickvalue;
   
   

   //ADR (Load only once)
   ObjectSetText("H4ATR","H4 ATR(100): "+atrH4Value,font_size,font_face,font_color);
   ObjectSetText("D1ATR","D1 ATR(100): "+atrD1Value,font_size,font_face,font_color);
   ObjectSetText("W1ATR","W1 ATR(54): "+MathCeil(pipMult *(iATR(NULL,10080,54,0))),font_size,font_face,font_color);
   ObjectSetText("MaxLots",percentSL+"% Lots H4/D1: "+NormalizeDouble(riskLots,2)+"/"+NormalizeDouble(riskLots2,2),font_size,font_face,font_color);

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectDelete("Spread");
   ObjectDelete("BullLots");
   ObjectDelete("BearLots");
   ObjectDelete("Risk");
   ObjectDelete("TotalOrders");
   ObjectDelete("H4ATR");
   ObjectDelete("D1ATR");
   ObjectDelete("W1ATR");
   ObjectDelete("MaxLots");
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   RefreshRates();

   double spread=(Ask-Bid)/Point;
//LOTS//
   int total=OrdersTotal();
   double bulllots=0;
   double bearlots=0;
   double totalOrders=0;
   double totalStopBulls=0;
   double totalStopBears=0;
   double totalStop=0;

//RISK//
   int     pips2points;    // slippage  3 pips    3=points    30=points
   double  pips2dbl;       // Stoploss 15 pips    0.015      0.0150
   int     pips;    // DoubleToStr(dbl/pips2dbl, Digits.pips)
   if(Digits%2==1)
     {      // DE30=1/JPY=3/EURUSD=5 forum.mql4.com/43064#515262
      pips2dbl=Point*10; pips2points=10;   pips=1;
        } else {    pips2dbl=Point;    pips2points=1;   pips=0;
     }

   for(int i=0; i<total; i++)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         double value2=OrderStopLoss();
         double value1=OrderOpenPrice();
         double differencePoints=(value1-value2)/pips2dbl/10; //REMOVER /10 PARA DIFERENÇA EM PIPS
                                                              
         if(OrderType()==OP_BUY)
           {
            bulllots+=OrderLots();
            totalStopBulls+=((differencePoints*MarketInfo(Symbol(),MODE_TICKVALUE))*OrderLots())*100;

              } else if(OrderType()==OP_SELL){
            bearlots+=OrderLots();
            totalStopBears+=((differencePoints*MarketInfo(Symbol(),MODE_TICKVALUE))*OrderLots())*100;
           }
         totalOrders++;
        }
     }
   if(bearlots>bulllots)
     {
      totalStop=totalStopBears;
        }else {
      totalStop=totalStopBulls;
     }
   
   double totalLoss = 0;
   double partialDistance = 0;
   
   for(int x=0; x<=stopLoss; x++){
      
      if(partialDistance>stopLoss)break;
      
      totalLoss+=(stopLoss-partialDistance);
      partialDistance+=distanceOrders;
      
   }
   
   ObjectSetText("Spread","Spread: "+DoubleToStr(NormalizeDouble(spread/divider,1),n_digits),font_size,font_face,font_color);
   ObjectSetText("BullLots","Bull Lots:  "+bulllots,font_size,font_face,font_color);
   ObjectSetText("BearLots","Bear Lots:  "+bearlots,font_size,font_face,font_color);
   ObjectSetText("TotalOrders","Total Orders: "+totalOrders,font_size,font_face,font_color);
   ObjectSetText("Risk","Risk: "+NormalizeDouble(totalStop,2),font_size,font_face,font_color);
   ObjectSetText("TotalPipsRisk","TotalPipsRisk: "+totalLoss,font_size,font_face,font_color);
   ObjectSetText("StopLossPips","StopLossPips: "+stopLoss,font_size,font_face,font_color);
   ObjectSetText("DistanceOrders","DistanceOrders: "+distanceOrders,font_size,font_face,font_color);
   
   return(0);
  }

//+------------------------------------------------------------------+
