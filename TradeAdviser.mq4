//+------------------------------------------------------------------+
//|                                          Strategy: TradeAdviser.mq4 |
//|                                       Created by Noel Martial Nguemechieu |
//|                                       https://www.eabuilder.com    |
//+------------------------------------------------------------------
#property script_show_inputs // request input parameters
#property copyright "@2020, Noel Martial nguemechieu "
#property link      "https://github.com/Bigbossmanger/TradeAdviser"
#property version   "1.00"
#property  strict 
#property description "This bot will trade base on 2 custom made profitable indicators .The strategy used is determine base on market conditions"
#property tester_indicator "TrendsFollowers"
#property tester_indicator "CMA[1]"
#property description "RISK DISCLAIMER:Investing involves risks. Any decision to invest in either real estate or stock markets is" 
"a personal decision that should be made after thorough research, including an assessment of your personal risk tolerance and your personal financial condition and goals. Results are based on market conditions and on each personal and the action they take and the time and effort they put in"





#include <createObjects.mqh>    // Functions for creating objects
#include <pipValue.mqh>         // Functions for pip values

//--- Inputs
input color cRPTFontClr = C'255,166,36';  // Font color

#include <stdlib.mqh>
#include <stderror.mqh>
#include <Controls/Button.mqh>
#include <Controls/RadioButton.mqh>
#include <Controls/Dialog.mqh>
#include <Controls/ListView.mqh>
#include <Controls/Picture.mqh>
#include <Controls/Rect.mqh>
#include <Telegram.mqh>

#include <Object.mqh>
#include <Controls/Button.mqh>
#include <Controls/Panel.mqh>
#include <TerminalInfo.mqh>
#include <Controls/Dialog.mqh>
//--- includes
#include <DoEasy\Engine.mqh>
#ifdef __MQL5__
#include <Trade\Trade.mqh>
#endif 

enum EA_Setting {Manual, RSI_MTF};
// enum Trade_Volume {Fixed_Lot, Fixed_P

enum CLOSE_PENDING_TYPE
{
   CLOSE_BUY_LIMIT,
   CLOSE_SELL_LIMIT,
   CLOSE_BUY_STOP,
   CLOSE_SELL_STOP,
   CLOSE_ALL_PENDING
};


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

sinput string RecoverySettings; // ** ZONE RECOVERY SETTINGS **
extern int RecoveryZoneSize = 200; // Recovery Zone Size (points)
extern int TakeProfit = 200; // Take Profit (points)
input int MaxTrades = 0; // Max Trades (0 for unlimited)
input bool SetMaxLoss = false; // Max Loss after Max Trades reached?
input double MaxLoss = 0; // Max Loss after Max Trades (0 for unlimted) in deposit currency.
input bool UseRecoveryTakeProfit = true; // Use a Recovery Take Profit
input int RecoveryTakeProfit = 50; // Recovery Take Profit (points).
extern double PendingPrice = 0; // Price for pending orders

sinput string ATRHeader; // ** ATR Dynamic Zone Sizing **
input bool UseATR = false; // Use ATR?
input int ATRPeriod = 14; // ATR Period
input double ATRZoneFraction = 0.2; // Fraction of ATR to use as Recovery Zone
input double ATRTPFraction = 0.3; // Fraction or ATR to use for TP sizes
input double ATRRecoveryZone = 0.15; // Fraction of ATR to use for recovery TP.

sinput string MoneyManagement;  	// ** MONEY MANAGEMENT SETTINGS **
input double RiskPercent = 0; // Account % Initial Lot Size  (set to 0 if not used) 
input double InitialLotSize = 0.1; // Initial Lot Size (if % not used)
input double LotMultiplier = 2; // Multiplier for Lots
input double LotAdditions = 0;
sinput string CustomLotSizing; // ** CUSTOM LOT SIZES **
input double CustomLotSize1 = 0;
input double CustomLotSize2 = 0;
input double CustomLotSize3 = 0;
input double CustomLotSize4 = 0;
input double CustomLotSize5 = 0;
input double CustomLotSize6 = 0;
input double CustomLotSize7 = 0;
input double CustomLotSize8 = 0;
input double CustomLotSize9 = 0;
input double CustomLotSize10 = 0;


sinput string TimerSettings;			// **  TIMER SETTINGS **
input bool UseTimer = false; // Use a Trade Timer?
input int StartHour = 0; // Start Hour
input int StartMinute = 0; // Start Minute
input int EndHour = 0; // End Hour
input int EndMinute = 0; // End Minute
input bool UseLocalTime = false; // Use local time?

sinput string TradeSettings;    	// ** EA SETTINGS **
input EA_Setting EA_Mode= Manual;
input int RSIPeriod = 14; // RSI Period
input double OverboughtLevel = 70; //Over-bought level
input double OversoldLevel = 30; // Over-sold level
input bool UseM1Timeframe = true; // Use M1 Timeframe?
input bool UseM5Timeframe = false; // Use M5 Timeframe?
input bool UseM15Timeframe = false; // Use M15 Timeframe?
input bool UseM30Timeframe = false; // Use M30 Timeframe?
input bool UseH1Timeframe = false; // Use H1 Timeframe?
input bool UseH4Timeframe = false; // Use H4 Timeframe?
input bool UseDailyTimeframe = false; // Use Daily Timeframe?
input bool UseWeeklyTimeframe = false; // Use Weekly Timeframe?
input bool UseMonthlyTimeframe = false; // Use Monthly Timeframe?

sinput string Visuals; // ** VISUALS **
input color profitLineColor = clrLightSeaGreen;
input int Panel_X = 40; // Panel X coordinate.
input int Panel_Y = 40; // Panel Y coordinate.
input color Panel_Color = clrBlack; // Panel background colour.
input color Panel_Lable_Color = clrWhite; // Panel lable text color.

sinput string BacktestingSettings; // ** OTHER SETTINGS **
input int MagicNumber = 141020; // Magic Number
input int Slippage = 100; // Slippage Max (Points).
input bool TradeOnBarOpen = true; // Trade on New Bar?
input int speed = 500; // Back tester speed
input double TestCommission = 7; // Back tester simulated commission


//+------------------------------------------------------------------+
//| Global variable and indicators                                   |
//+------------------------------------------------------------------+

#define EA_NAME "RRS Zone Recovery Hedge"
#define SELL_BUTTON "Sell Button"
#define BUY_BUTTON "Buy Button"
#define PENDING_EDIT "Pending Edit"
#define CLOSE_ALL_BUTTON "Close All Button"
#define TP_EDIT "TP Edit"
#define ZONE_EDIT "Zone Edit"
string gTradingPanelObjects[100];
#define PROFIT_LINE "Profit Line"

datetime gLastTime;
int gInitialTicket;
double gBuyOpenPrice;
double gSellOpenPrice;
double gBuyTakeProfit;
double gSellTakeProfit;
double gLotSize;
double gInitialLotSize;
double gInitialProfitTarget;
bool gRecoveryInitiated;
int gBuyStopTicket = 0;
int gSellStopTicket = 0;
int gBuyTicket = 0;
int gSellTicket = 0;
double gCustomLotSizes[10]; 

double UsePip;
double UseSlippage;
double gCurrentDirection;





//--- enums
enum ENUM_BUTTONS
  {
   BUTT_BUY,
   BUTT_BUY_LIMIT,
   BUTT_BUY_STOP,
   BUTT_BUY_STOP_LIMIT,
   BUTT_CLOSE_BUY,
   BUTT_CLOSE_BUY2,
   BUTT_CLOSE_BUY_BY_SELL,
   BUTT_SELL,
   BUTT_SELL_LIMIT,
   BUTT_SELL_STOP,
   BUTT_SELL_STOP_LIMIT,
   BUTT_CLOSE_SELL,
   BUTT_CLOSE_SELL2,
   BUTT_CLOSE_SELL_BY_BUY,
   BUTT_DELETE_PENDING,
   BUTT_CLOSE_ALL,
   BUTT_PROFIT_WITHDRAWAL,
   BUTT_SET_STOP_LOSS,
   BUTT_SET_TAKE_PROFIT,
   BUTT_TRAILING_ALL
  };
#define TOTAL_BUTT   (20)
//--- structures
struct SDataButt
  {
   string      name;
   string      text;
  };
  
  
//--- input variables
input ulong             InpMagic             =  123;  // Magic number
input double            InpLots              =  0.1;  // Lots
input uint              InpStopLoss          =  50;   // StopLoss in points
input uint              InpTakeProfit        =  50;   // TakeProfit in points
input uint              InpDistance          =  50;   // Pending orders distance (points)
input uint              InpDistanceSL        =  50;   // StopLimit orders distance (points)
input uint              InpSlippage          =  0;    // Slippage in points
input double            InpWithdrawal        =  10;   // Withdrawal funds (in tester)
input uint              InpButtShiftX        =  40;   // Buttons X shift 
input uint              InpButtShiftY        =  10;   // Buttons Y shift 
input uint              InpTrailingStop      =  50;   // Trailing Stop (points)
input uint              InpTrailingStep      =  20;   // Trailing Step (points)
input uint              InpTrailingStart     =  0;    // Trailing Start (points)
input uint              InpStopLossModify    =  20;   // StopLoss for modification (points)
input uint              InpTakeProfitModify  =  60;   // TakeProfit for modification (points)
input ENUM_SYMBOLS_MODE InpModeUsedSymbols   =  SYMBOLS_MODE_CURRENT;   // Mode of used symbols list
input string            InpUsedSymbols       =  "EURUSD,AUDUSD,EURAUD,EURCAD,EURGBP,EURJPY,EURUSD,GBPUSD,NZDUSD,USDCAD,USDJPY";  // List of used symbols (comma - separator)

//--- global variables
CEngine        engine;
#ifdef __MQL5__
CTrade         trade;
#endif 
SDataButt      butt_data[TOTAL_BUTT];
string         prefix;
double         lot;
double          price;
double         withdrawal=(InpWithdrawal<0.1 ? 0.1 : InpWithdrawal);
ulong          magic_number;
uint           stoploss;
uint           takeprofit;
uint           distance_pending;
uint           distance_stoplimit;
uint           slippage;
bool           trailing_on;
double         trailing_stop;
double         trailing_step;
uint           trailing_start;
uint           stoploss_to_modify;
uint           takeprofit_to_modify;
int            used_symbols_mode;
string         used_symbols;
string         array_used_symbols[];
extern string telegramToken="1934022436:AAEz0x1CqwtZ3eD9Ci6sssKBQZU24rUfSp0"; 
extern string ChannelName="GoldMiner"; 
CButton Button1,Button2,Button3;
CTerminalInfo terminalInfo;
datetime allowed_until = D'2021.12.11 00:00';                        
int password_status = -1;

extern double SL_Points = 50;
extern double TP_Points = 50;
extern double Step = 0.02;
extern double Maximum = 0.2;
extern string LicenceKey = "license key";

int LotDigits; //initialized in OnInit



extern    double         inTargetProfitMoney     = 10;       //Target Profit ($)
extern    double         inCutLossMoney          = 0.0;      //Cut Loss ($)
  int            inMagicNumber           = MagicNumber;        //Magic Number

int NextOpenTradeAfterHours = 2; //next open trade after time
extern int TOD_From_Hour = 09; //time of the day (from hour)
extern int TOD_From_Min = 45; //time of the day (from min)
extern int TOD_To_Hour = 16; //time of the day (to hour)
extern int TOD_To_Min = 15; //time of the day (to min)
int MaxTradeDurationBars = 120; //maximum trade duration
extern int PendingOrderExpirationHours = 20; //pending order expiration
extern double DeleteOrderAtDistance = 2000; //delete order when too far from current price
extern int MinTradeDurationSeconds = 150; //minimum trade duration
extern double MM_Percent = 1;
extern double MaxSpread = 100;
extern int MaxSlippage = 3; //adjusted in OnInit
extern bool TradeMonday = true;
extern bool TradeTuesday = true;
extern bool TradeWednesday = true;
extern bool TradeThursday = true;
extern bool TradeFriday = true;
bool TradeSaturday = false;
extern bool TradeSunday = true;
extern double MaxSL = 200;
extern double MinSL = 100;
extern double MaxTP = 200;
extern double MinTP = 100;
extern double CloseAtPL = 100;
extern double PriceTooClose = 5;
bool crossed[2]; //initialized to true, used in function Cross
bool Send_Email = true;
extern bool Audible_Alerts = true;
bool Push_Notifications = true;
extern int MaxOpenTrades = 5000;
extern int MaxLongTrades = 1500;
extern int MaxShortTrades = 1000;
extern int MaxPendingOrders = 200;
extern int MaxLongPendingOrders = 1000;
extern int MaxShortPendingOrders = 500;

extern bool Hedging = true;
int OrderRetry = 5; //# of retries if sending order returns error
int OrderWait = 60; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit

double  dropPencent=(price-OrderOpenPrice())*10;
  datetime now = TimeCurrent();
//--- get time
   datetime time[1];

 
bool  firsts             = true;
bool     Now_IsConnected   = false;
bool     Pre_IsConnected   = true;
datetime Connect_Start = 0, Connect_Stop = 0;


CRadioButton radio1;

 
CCustomBot bot;



string status="Offline";




int macd_handle;
datetime time_signal=0;



int OnnInit()
{
   gRecoveryInitiated = false;
   gCurrentDirection = 0;
   // Set magic number
   UsePip = PipPoint(Symbol());
   UseSlippage = GetSlippage(Symbol(), Slippage);
   gLastTime = 0;
   gCustomLotSizes[0] = CustomLotSize1;
   gCustomLotSizes[1] = CustomLotSize2;
   gCustomLotSizes[2] = CustomLotSize3;
   gCustomLotSizes[3] = CustomLotSize4;
   gCustomLotSizes[4] = CustomLotSize5;
   gCustomLotSizes[5] = CustomLotSize6;
   gCustomLotSizes[6] = CustomLotSize7;
   gCustomLotSizes[7] = CustomLotSize8;
   gCustomLotSizes[8] = CustomLotSize9;
   gCustomLotSizes[9] = CustomLotSize10;
 
   CreateTradingPanel();
   Print("INIT SUCCESFUL, Recovery Initiated: ", gRecoveryInitiated, " Current Dirn: ", gCurrentDirection, " Magic No: ", MagicNumber, " Slippage: ", Slippage);
   
   if(OrdersTotal() > 0) FindOpenOrders();
       
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Shutdown function                                             |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
 if(reason==REASON_PARAMETERS ||
         reason==REASON_RECOMPILE ||
         reason==REASON_ACCOUNT)
   {
      bool checked=false;
      
   }
//--- Remove EA graphical objects by an object name prefix
   ObjectsDeleteAll(0,prefix);
   Comment(reason);
   switch(reason)
   {
      case 0:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, removed by EA");
         break;
      }
      case 1:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, removed by user");
         break;
      }
      case 2:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, EA recompiled");
         break;
      }
      case 3:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, Symbol changed");
         break;
      }   
      case 4:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, chart closed by user.");
         break;
      }
      case 5:
      {
         Print("EA De-Initialised, input parameters changed.");
         break;
      }
      case 6:
      {
         Print("EA De-Initialised, account changed");
         break;
      }
      case 7:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, A new template has been applied.");
         break;
      }
      case 8:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, EA failed to initialize.");
         break;
      }
      case 9:
      {
         DeleteTradePanel();
         Print("EA De-Initialised, Terminal closed by user.");
         break;
      }  
   }
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnnTick()
{
   if(IsVisualMode() == true)
   {
      int Waitloop = 0;
      while(Waitloop < speed)
      {
         Waitloop++;
      }
   }
   // Check timer
   bool tradeEnabled = true;
   if(UseTimer == true)
   {
      tradeEnabled = CheckDailyTimer();
   }
   
   // Check for bar open
   bool newBar = true;
   int barShift = 0;
   
   // check if a new bar has been opened
   if(TradeOnBarOpen == true)
   {
      newBar = false;
      datetime time[];
      bool firstRun = false;
      
      CopyTime(_Symbol,PERIOD_CURRENT,0,2,time);
      
      if(gLastTime == 0) firstRun = true;
	
	   if(time[0] > gLastTime)
	   {
		   if(firstRun == false) newBar = true;
		   gLastTime = time[0];
	   }
      barShift = 1;
   }
   
   // Money management
   
   // set lot size to initial lot size for doubling later
   gInitialLotSize = CheckVolume(_Symbol, InitialLotSize); // check the input value for lot initial lot size and set to initial
   
   if(RiskPercent != 0)
   {
      int StopLoss = TakeProfit;
      if(UseATR == true)
      {
         double atr = iATR(_Symbol, PERIOD_D1, ATRPeriod, 1);
         StopLoss = round((atr*ATRTPFraction)/_Point); // set the stop loss a fraction of atr in points
      }
      gInitialLotSize = GetTradeSize(_Symbol,InitialLotSize,RiskPercent,StopLoss);
   }

   // Check entries on new bar
   if(newBar == true && tradeEnabled == true) // check for new bar and whether timer allows to open
   {
      
      switch(EA_Mode)
      {
         case RSI_MTF:
         {
            int direction = Is_RSI_OBOS_on_MTF(barShift + 1);
            int nowFalse = Is_RSI_OBOS_on_MTF(barShift);
            if(direction == 1 && nowFalse == 0)
            {
               Print("Buy signal generated.");
               if(gCurrentDirection == 0)
               {
                  TakeTrade(direction);
                  Print("Buy signal generated.");
               } else {
                  Print("Buy signal not used as EA in trade on ", _Symbol);
               }
            }
            else if(direction == -1 && nowFalse == 0)
            {
               if(gCurrentDirection == 0) 
               {
                  TakeTrade(direction);
                  Print("Sell signal generated.");
               } else {
                  Print("Sell signal not used as EA in trade on ", _Symbol);
               }
            }
         }              
      }
   }   
   
   

   if(gCurrentDirection != 0)
   {
      // on every tick work out the average price
      // count the number of buy and sell orders
      int positions = 0;
      double averagePrice = 0;
      double currentProfit = 0;
      double positionSize = 0;
      double netLotSize = 0;
      double totalCommision = 0;
      double totalSpreadCosts = 0;
      double point_value = _Point*MarketInfo(_Symbol, MODE_TICKVALUE)/MarketInfo(_Symbol, MODE_TICKSIZE);
   
      for(int counter = 0; counter <= OrdersTotal() - 1; counter++)
      {
         if(OrderSelect(counter, SELECT_BY_POS))
         {
            if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
            {
               positions += 1;
               currentProfit += OrderProfit();
               
               if(OrderType() == OP_BUY)
               {
                  positionSize += (OrderOpenPrice()*OrderLots());
                  netLotSize += OrderLots();
                  totalSpreadCosts += (OrderLots()*MarketInfo(_Symbol, MODE_SPREAD)*point_value);
                  totalCommision += OrderCommission();
               }
               else if(OrderType() == OP_SELL)
               {
                  positionSize -= (OrderOpenPrice()*OrderLots());
                  netLotSize -= OrderLots();
                  totalSpreadCosts += (OrderLots()*MarketInfo(_Symbol, MODE_SPREAD)*point_value);
                  totalCommision += OrderCommission();
               }
            }
         }
      }

      // if the current profits are greater than the desired recovery profit and costs close the trades
      double volume;
      if(CustomLotSize1 != 0) volume = CustomLotSize1;
      else volume = gInitialLotSize;
      double profitTarget = RecoveryTakeProfit*point_value*volume;
      if(UseATR == true) 
      {
         double atr = iATR(_Symbol, PERIOD_D1, ATRPeriod, 1);
         profitTarget = (ATRRecoveryZone*atr*point_value*volume)/_Point;
      }
      
      // simulate commission for backtesting
      double tradeCosts = 0;
      if(IsTesting())
      {
         tradeCosts = totalSpreadCosts+(MathAbs(netLotSize)*TestCommission);
      } else {
         tradeCosts = totalSpreadCosts+totalCommision; // spread and commision
      }
     
      double tp = RecoveryTakeProfit;
      if(UseRecoveryTakeProfit == false || gRecoveryInitiated == false)
      {
         profitTarget = TakeProfit*point_value*volume; // initial profit is equal to planned rz over tp, in $$
      }
      
      if(currentProfit >= (profitTarget +tradeCosts))
      {
         CloseOrdersAndReset();
         Print("Orders closed, profit target of: ", DoubleToStr(profitTarget, 2), "$ exceeded at: ", DoubleToStr(currentProfit, 2), "$, Costs(", DoubleToStr(tradeCosts, 2), "$)");        
      }
      if(netLotSize != 0)
      {
         averagePrice = NormalizeDouble(positionSize/netLotSize, _Digits);
         Comment(StringConcatenate("Average Price: ", DoubleToStr(averagePrice, _Digits), ", Profit Target: $", DoubleToStr(profitTarget, 2), " + Trade Costs: $", DoubleToStr(tradeCosts, 2), ", Running Profit:  $", DoubleToStr(currentProfit, 2)));
      }
      
      if(positions >= MaxTrades && MaxTrades != 0 && currentProfit < -MaxLoss && SetMaxLoss == true)
      {
         CloseOrdersAndReset();
         Print("Orders closed, max trades reached and max loss of: -$", MaxLoss, " by $", currentProfit);
      }   
   
      // set the take profit line price
      if(gCurrentDirection == 1 && netLotSize != 0)
      {
         tp = (profitTarget + tradeCosts - currentProfit)*_Point/(point_value*netLotSize);
         double   profitPrice = NormalizeDouble(Bid + tp, _Digits);
         if(!ObjectSetDouble(0, PROFIT_LINE, OBJPROP_PRICE, profitPrice)) Print("Could not set line");
      } else if(gCurrentDirection == -1 && netLotSize != 0) {
         tp = (profitTarget + tradeCosts - currentProfit)*_Point/(point_value*netLotSize);   
         double   profitPrice = NormalizeDouble(Ask + tp, _Digits);
         if(!ObjectSetDouble(0, PROFIT_LINE, OBJPROP_PRICE, profitPrice)) Print("Could not set line");   
      } 
      

   
   // check if the current direction is buy and the bid price (sell stop has opened) is below the recovery line
      if(gCurrentDirection == 1)
      {
         double price = MarketInfo(Symbol(), MODE_ASK);
         if(OrderSelect(gSellStopTicket, SELECT_BY_TICKET))
         {
            if(OrderType() == OP_SELL) // if the sell stop has opened
            {
               Print("Recovery Sell Stop has been opened, initiating recovery...");
               gSellTicket = gSellStopTicket; // make the stop a sell ticket
               gSellStopTicket = 0; // reset the sell stop ticket
               
               // increase the lot size 
               gLotSize = GetTradeVolume(positions+1);

               if(MaxTrades == 0 || positions < MaxTrades) // check we've not exceeded the max trades
               {
                 // open a buy stop order at double the running lot size
                 gBuyStopTicket = OpenPendingOrder(Symbol(), OP_BUYSTOP, gLotSize, gBuyOpenPrice, 0, 0, StringConcatenate("Recovery Buy Stop opened."), 0, clrTurquoise); // create an opposite buy stop
                 gRecoveryInitiated = true; // signal that we are in recovery mode
               }
               // change the current direction to sell
               gCurrentDirection = -1;            
            }
         } else {
            string message = "Warning - EA could not find the recovery Sell Stop";
            Alert(message);
            Print(message);
         }
      }
   // check if the current direction is sell and the ask price (sell stop has opened) is below the recovery line
      if(gCurrentDirection == -1)
      {
         double price = MarketInfo(Symbol(), MODE_BID);   
         if(OrderSelect(gBuyStopTicket, SELECT_BY_TICKET))
         {
            if(OrderType() == OP_BUY) // if the buy stop has opened
            {
               Print("Recovery Buy Stop has been opene, initiating recovery...");
               gBuyTicket = gBuyStopTicket; // set the buy ticket to the stop
               gBuyStopTicket = 0; // reset the buy ticket
               
               // increase the lot size
               gLotSize = GetTradeVolume(positions+1);               
               
               if(MaxTrades == 0 || positions < MaxTrades) // check we've not exceeded the max trades
               {
                  // open a sell stop order at double the running lot size
                  gSellStopTicket = OpenPendingOrder(Symbol(), OP_SELLSTOP, gLotSize, gSellOpenPrice, 0, 0, StringConcatenate("Recovery Sell Stop opened."), 0, clrPink); // create an opposite sell stop
                  gRecoveryInitiated = true; // signal we're in recovery mode
               }
               // change the current direction to sell
               gCurrentDirection = 1;
            }
         } else {
            string message = "Warning - EA could not find the recovery Buy Stop";
            Alert(message);
            Print(message);
         }
      }
   } else {
      Comment("No OGT Zone Recovery Trades Active");
   }
}

// Initial trade taking algorithm

void TakeTrade(int direction)
{

    double tp = 0;
    double rz = 0;
    // if the user has selected to use the ATR to size zones
    if(UseATR == true)
    {
      double atr = iATR(_Symbol, PERIOD_D1, ATRPeriod, 1);
      tp = atr*ATRTPFraction;
      rz = atr*ATRZoneFraction;
      //TakeProfit = tp;
      //RecoveryZoneSize = rz;
    } else if(UseATR == false)
    {
      tp = TakeProfit*_Point; // tp as price units
      rz = RecoveryZoneSize*_Point; // rz as price
    }
    if(CustomLotSize1 != 0) gLotSize = CustomLotSize1;
    else gLotSize = gInitialLotSize;

    double price = 0;
    
   if(direction == 1)
   {
   
       gBuyTicket = OpenMarketOrder(Symbol(), OP_BUY, gLotSize, "Initial Buy Order", clrGreen);
       if(OrderSelect(gBuyTicket, SELECT_BY_TICKET))
       {                 
          gBuyOpenPrice = OrderOpenPrice();       
          gSellOpenPrice = NormalizeDouble((gBuyOpenPrice - rz), _Digits);
          gBuyTakeProfit = NormalizeDouble((gBuyOpenPrice + tp), _Digits);
          gSellTakeProfit = NormalizeDouble((gBuyOpenPrice - (tp + rz)), _Digits);
          
          // ModifyStopsByPrice(gBuyTicket, gSellTakeProfit, gBuyTakeProfit);  
      
          //open a recovery stop order in the opposite direction
          gLotSize = GetTradeVolume(2);
          gSellStopTicket = OpenPendingOrder(Symbol(), OP_SELLSTOP, gLotSize, gSellOpenPrice, 0, 0, "Initial Recovery Sell Stop)", 0, clrPink);
          gCurrentDirection = direction;
          price = gBuyOpenPrice;
       }
   }
   // Sell Trade
   else if(direction == -1)
   {
       gSellTicket = OpenMarketOrder(Symbol(), OP_SELL, gLotSize, "Initial Sell Order", clrRed);
       if(OrderSelect(gSellTicket, SELECT_BY_TICKET))
       {
          gSellOpenPrice = OrderOpenPrice(); 
          gBuyOpenPrice = NormalizeDouble((gSellOpenPrice + rz), _Digits);
          gSellTakeProfit = NormalizeDouble((gSellOpenPrice - tp), _Digits);
          gBuyTakeProfit = NormalizeDouble((gSellOpenPrice + (tp + rz)), _Digits);
          
          // ModifyStopsByPrice(gSellTicket, gBuyTakeProfit, gSellTakeProfit);       
          
          //open a recovery stop order in the opposite direction
          gLotSize = GetTradeVolume(2);
          gBuyStopTicket = OpenPendingOrder(Symbol(), OP_BUYSTOP, gLotSize, gBuyOpenPrice, 0, 0, "Initial Recovery Buy Stop)", 0, clrTurquoise);
          gCurrentDirection = direction;
          price = gSellOpenPrice;
       }
   }
   CreateProfitLine(direction, price, tp); 
}

void PlaceTrade(int pType)
{
    double tp = 0;
    double rz = 0;
    // if the user has selected to use the ATR to size zones
    if(UseATR == true)
    {
      double atr = iATR(_Symbol, PERIOD_D1, ATRPeriod, 1);
      tp = atr*ATRTPFraction;
      rz = atr*ATRZoneFraction;
      //TakeProfit = tp;
      //RecoveryZoneSize = rz;
    } else if(UseATR == false)
    {
      tp = TakeProfit*_Point;  // tp as price
      rz = RecoveryZoneSize*_Point; // rz  as price
    }
    if(CustomLotSize1 != 0) gLotSize = CustomLotSize1;
    else gLotSize = gInitialLotSize;
    
    if(pType == OP_BUYLIMIT)
    {
      gBuyStopTicket = OpenPendingOrder(_Symbol, OP_BUYLIMIT, gLotSize, PendingPrice, 0, 0, "Buy Limit Order", 0, 0);
      gBuyOpenPrice = PendingPrice;       
      gSellOpenPrice = NormalizeDouble((gBuyOpenPrice - rz), _Digits);
      gCurrentDirection = -1;
    
    } else if(pType == OP_BUYSTOP)
    {
      gBuyStopTicket = OpenPendingOrder(_Symbol, OP_BUYSTOP, gLotSize, PendingPrice, 0, 0, "Buy Stop Order", 0, 0);
      gBuyOpenPrice = PendingPrice;       
      gSellOpenPrice = NormalizeDouble((gBuyOpenPrice - rz), _Digits);
      gCurrentDirection = -1;
    
    } else if(pType == OP_SELLLIMIT)
    {
      gSellOpenPrice = PendingPrice; 
      gBuyOpenPrice = NormalizeDouble((gSellOpenPrice + rz), _Digits);
      gSellStopTicket = OpenPendingOrder(_Symbol, OP_SELLLIMIT, gLotSize, PendingPrice, 0, 0,  "Sell Limit Order", 0, 0);
      gCurrentDirection = 1;
    } else if(pType == OP_SELLSTOP)
    {
      gSellOpenPrice = PendingPrice; 
      gBuyOpenPrice = NormalizeDouble((gSellOpenPrice + rz), _Digits);
      gSellStopTicket = OpenPendingOrder(_Symbol, OP_SELLSTOP, gLotSize, PendingPrice, 0, 0,  "Sell Stop Order", 0, 0);
      gCurrentDirection = 1;
    }
    CreateProfitLine(gCurrentDirection, PendingPrice, 0);
}

// RSI Entry Function

int Is_RSI_OBOS_on_MTF(int shift)
{
   int direction = 0;
   
   // check if the MTF is showing oversold, buy signal
   double rsi = iRSI(_Symbol, PERIOD_M1, RSIPeriod, PRICE_CLOSE, shift);
   if((UseM1Timeframe == false) || (rsi < OversoldLevel))
   {
      rsi = iRSI(_Symbol, PERIOD_M5, RSIPeriod, PRICE_CLOSE, shift);
      if(UseM5Timeframe == false || (rsi < OversoldLevel))
      {
         rsi = iRSI(_Symbol, PERIOD_M15, RSIPeriod, PRICE_CLOSE, shift);
         if((UseM15Timeframe == false) || (rsi < OversoldLevel))
         {
            rsi = iRSI(_Symbol, PERIOD_M30, RSIPeriod, PRICE_CLOSE, shift);
            if((UseM30Timeframe == false) || (rsi < OversoldLevel))
            {
               rsi = iRSI(_Symbol, PERIOD_H1, RSIPeriod, PRICE_CLOSE, shift);
               if((UseH1Timeframe == false) || (rsi < OversoldLevel))
               {
                  rsi = iRSI(_Symbol, PERIOD_H4, RSIPeriod, PRICE_CLOSE, shift);
                  if((UseH4Timeframe == false) || (rsi < OversoldLevel))
                  {
                     rsi = iRSI(_Symbol, PERIOD_D1, RSIPeriod, PRICE_CLOSE, shift);
                     if((UseDailyTimeframe == false) || (rsi < OversoldLevel))
                     {
                        rsi = iRSI(_Symbol, PERIOD_W1, RSIPeriod, PRICE_CLOSE, shift);
                        if((UseWeeklyTimeframe == false) || (rsi < OversoldLevel))
                        {
                           rsi = iRSI(_Symbol, PERIOD_MN1, RSIPeriod, PRICE_CLOSE, shift);
                           if((UseMonthlyTimeframe == false) || (rsi < OversoldLevel))
                           {
                              direction = 1;
                              return direction;
                           }
                        }
                     }                     
                  }
               }
            }
         }
      }
   }
   
   // check if the MTF is showing overbought, sell signal   
   rsi = iRSI(_Symbol, PERIOD_M1, RSIPeriod, PRICE_CLOSE, shift);
   if((UseM1Timeframe == false) || (rsi > OverboughtLevel))
   {
      rsi = iRSI(_Symbol, PERIOD_M5, RSIPeriod, PRICE_CLOSE, shift);
      if(UseM5Timeframe == false || (rsi > OverboughtLevel))
      {
         rsi = iRSI(_Symbol, PERIOD_M15, RSIPeriod, PRICE_CLOSE, shift);
         if((UseM15Timeframe == false) || (rsi > OverboughtLevel))
         {
            rsi = iRSI(_Symbol, PERIOD_M30, RSIPeriod, PRICE_CLOSE, shift);
            if((UseM30Timeframe == false) || (rsi > OverboughtLevel))
            {
               rsi = iRSI(_Symbol, PERIOD_H1, RSIPeriod, PRICE_CLOSE, shift);
               if((UseH1Timeframe == false) || (rsi > OverboughtLevel))
               {
                  rsi = iRSI(_Symbol, PERIOD_H4, RSIPeriod, PRICE_CLOSE, shift);
                  if((UseH4Timeframe == false) || (rsi > OverboughtLevel))
                  {
                     rsi = iRSI(_Symbol, PERIOD_D1, RSIPeriod, PRICE_CLOSE, shift);
                     if((UseDailyTimeframe == false) || (rsi > OverboughtLevel))
                     {
                        rsi = iRSI(_Symbol, PERIOD_W1, RSIPeriod, PRICE_CLOSE, shift);
                        if((UseWeeklyTimeframe == false) || (rsi > OverboughtLevel))
                        {
                           rsi = iRSI(_Symbol, PERIOD_MN1, RSIPeriod, PRICE_CLOSE, shift);
                           if((UseMonthlyTimeframe == false) || (rsi > OverboughtLevel))
                           {
                              direction = -1;
                              return direction;
                           }
                        }
                     }                     
                  }
               }
            }
         }
      } 
   }
   return direction;      
}

void CloseOrdersAndReset()
{
   CloseAllMarketOrders();
   DeletePendingOrders(CLOSE_ALL_PENDING);
   gLotSize = gInitialLotSize;
   gCurrentDirection = 0;
   gBuyStopTicket = 0;
   gSellStopTicket = 0;
   gBuyTicket = 0;
   gSellTicket = 0;
   gRecoveryInitiated = false;
   DeleteProfitLine();
}

void CreateProfitLine(double pDirection, double pPrice, double pPoints)
{
   double price = 0;
   if(pDirection == 1)
   {
      price = NormalizeDouble(pPrice + pPoints, _Digits);
   } else if(pDirection == -1) {
      price = NormalizeDouble(pPrice - pPoints, _Digits);
   }
   ObjectCreate(0, PROFIT_LINE, OBJ_HLINE, 0,0,price);
   ObjectSetInteger(0, PROFIT_LINE, OBJPROP_COLOR, profitLineColor);
   ObjectSetInteger(0, PROFIT_LINE, OBJPROP_STYLE, STYLE_DASH);
}

void DeleteProfitLine()
{
   ObjectDelete(0, PROFIT_LINE);
}

void CreateTradingPanel()
{
   // create the button to start the trade off

   long buttonWidth = 50;
   long buttonHeight = 25;
   long panelX = Panel_X;
   long panelY = Panel_Y;
   long boxMargin = 10;
   long lableX = panelX+boxMargin+5;
   long lableY = panelY+boxMargin+10;
   long lableHeight = 40;
   long buttonX = panelX+boxMargin+20;
   long buttonY = panelY+lableHeight+boxMargin;
   long panelWidth = boxMargin+buttonWidth+boxMargin+buttonWidth+boxMargin +40;
   long panelHeight = boxMargin+lableHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin;
   double pending = NormalizeDouble(PendingPrice, _Digits);
   

   string buttonBox = "ButtonBox";   
   ObjectCreate(0, buttonBox, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0,buttonBox,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0, buttonBox, OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, buttonBox, OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, buttonBox, OBJPROP_XDISTANCE, panelX);
   ObjectSetInteger(0, buttonBox, OBJPROP_YDISTANCE, panelY);
   ObjectSetInteger(0, buttonBox, OBJPROP_BGCOLOR, Panel_Color);
   ObjectSetInteger(0,buttonBox,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   ObjectSetInteger(0,buttonBox,OBJPROP_COLOR,clrGray);
   ObjectSetInteger(0,buttonBox,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,buttonBox,OBJPROP_HIDDEN,false);
   ObjectSetInteger(0,buttonBox,OBJPROP_ZORDER,0);
   gTradingPanelObjects[0] = buttonBox;
   
   string panelLabel = "Trading Panel Label";
   ObjectCreate(0, panelLabel, OBJ_LABEL, 0,0,0);
   ObjectSetString(0, panelLabel, OBJPROP_TEXT, EA_NAME);
   ObjectSetInteger(0, panelLabel, OBJPROP_XDISTANCE, lableX);
   ObjectSetInteger(0, panelLabel, OBJPROP_YDISTANCE, lableY);
   ObjectSetInteger(0, panelLabel, OBJPROP_COLOR, Panel_Lable_Color);
   ObjectSetInteger(0, panelLabel, OBJPROP_FONTSIZE, 9);
   gTradingPanelObjects[1] = panelLabel;
   
   string sellButtonName = SELL_BUTTON;  
   ObjectCreate(0, sellButtonName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, sellButtonName, OBJPROP_XSIZE, buttonWidth);
   ObjectSetInteger(0, sellButtonName, OBJPROP_YSIZE, buttonHeight);
   ObjectSetInteger(0, sellButtonName, OBJPROP_XDISTANCE, buttonX);
   ObjectSetInteger(0, sellButtonName, OBJPROP_YDISTANCE, buttonY);
   ObjectSetInteger(0, sellButtonName, OBJPROP_COLOR, Panel_Lable_Color);
   ObjectSetInteger(0, sellButtonName, OBJPROP_BGCOLOR, clrRed);
   ObjectSetString(0, sellButtonName, OBJPROP_TEXT, "Sell");
   gTradingPanelObjects[2] = SELL_BUTTON;
     
   string buyButtonName = BUY_BUTTON;
   ObjectCreate(0, buyButtonName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, buyButtonName, OBJPROP_XSIZE, buttonWidth);
   ObjectSetInteger(0, buyButtonName, OBJPROP_YSIZE, buttonHeight);
   ObjectSetInteger(0, buyButtonName, OBJPROP_XDISTANCE, (buttonX+buttonWidth+boxMargin));
   ObjectSetInteger(0, buyButtonName, OBJPROP_YDISTANCE, buttonY);
   ObjectSetInteger(0, buyButtonName, OBJPROP_COLOR, Panel_Lable_Color);
   ObjectSetInteger(0, buyButtonName, OBJPROP_BGCOLOR, clrGreen);
   ObjectSetString(0, buyButtonName, OBJPROP_TEXT, "Buy");
   gTradingPanelObjects[3] = BUY_BUTTON; 
   
   ObjectCreate(0, CLOSE_ALL_BUTTON, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, CLOSE_ALL_BUTTON, OBJPROP_XSIZE, buttonWidth+boxMargin+buttonWidth);
   ObjectSetInteger(0, CLOSE_ALL_BUTTON, OBJPROP_YSIZE, buttonHeight);
   ObjectSetInteger(0, CLOSE_ALL_BUTTON, OBJPROP_XDISTANCE, (buttonX));
   ObjectSetInteger(0, CLOSE_ALL_BUTTON, OBJPROP_YDISTANCE, buttonY+buttonHeight+boxMargin);
   ObjectSetInteger(0, CLOSE_ALL_BUTTON, OBJPROP_COLOR, Panel_Lable_Color);
   ObjectSetInteger(0, CLOSE_ALL_BUTTON, OBJPROP_BGCOLOR, clrGray);
   ObjectSetString(0, CLOSE_ALL_BUTTON, OBJPROP_TEXT, "Close All Orders");
   gTradingPanelObjects[4] = CLOSE_ALL_BUTTON;
   
   string TPLabel = "TP Label";
   ObjectCreate(0, TPLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, TPLabel, OBJPROP_TEXT, "TP: ");
   ObjectSetInteger(0, TPLabel, OBJPROP_XDISTANCE, buttonX);
   ObjectSetInteger(0, TPLabel, OBJPROP_YDISTANCE, 5+buttonY+buttonHeight+boxMargin+buttonHeight+boxMargin);
   ObjectSetInteger(0, TPLabel, OBJPROP_COLOR, Panel_Lable_Color);
   gTradingPanelObjects[5] = TPLabel;
   
   string zoneLable = "Zone Lable";
   ObjectCreate(0, zoneLable, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, zoneLable, OBJPROP_TEXT, "Zone: ");
   ObjectSetInteger(0, zoneLable, OBJPROP_XDISTANCE, buttonX);
   ObjectSetInteger(0, zoneLable, OBJPROP_YDISTANCE, 5+ buttonY+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin);
   ObjectSetInteger(0, zoneLable, OBJPROP_COLOR, Panel_Lable_Color);
   gTradingPanelObjects[6] = zoneLable;
   
   ObjectCreate(0, TP_EDIT, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, TP_EDIT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, TP_EDIT, OBJPROP_XDISTANCE, buttonX+buttonWidth+boxMargin);
   ObjectSetInteger(0, TP_EDIT, OBJPROP_YDISTANCE, buttonY+buttonHeight+boxMargin+buttonHeight+boxMargin);
   ObjectSetInteger(0, TP_EDIT, OBJPROP_XSIZE, buttonWidth);
   ObjectSetInteger(0, TP_EDIT, OBJPROP_YSIZE, buttonHeight);   
   ObjectSetInteger(0, TP_EDIT, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, TP_EDIT, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetString(0, TP_EDIT, OBJPROP_TEXT, IntegerToString(TakeProfit));
   ObjectSetInteger(0,TP_EDIT,OBJPROP_ALIGN,ALIGN_CENTER);
   gTradingPanelObjects[7] = TP_EDIT;
   
   ObjectCreate(0, ZONE_EDIT, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_XDISTANCE, buttonX+buttonWidth+boxMargin);
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_YDISTANCE, buttonY+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin);   
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_XSIZE, buttonWidth);
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_YSIZE, buttonHeight);
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, ZONE_EDIT, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetString(0, ZONE_EDIT, OBJPROP_TEXT, IntegerToString(RecoveryZoneSize));
   ObjectSetInteger(0,ZONE_EDIT,OBJPROP_ALIGN,ALIGN_CENTER);
   gTradingPanelObjects[8] = ZONE_EDIT;
   
   ObjectCreate(0, PENDING_EDIT, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_XDISTANCE, buttonX+buttonWidth+boxMargin);
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_YDISTANCE, buttonY+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin);   
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_XSIZE, buttonWidth);
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_YSIZE, buttonHeight);
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, PENDING_EDIT, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetString(0, PENDING_EDIT, OBJPROP_TEXT, IntegerToString(pending));
   ObjectSetInteger(0,PENDING_EDIT,OBJPROP_ALIGN,ALIGN_CENTER);
   gTradingPanelObjects[9] = PENDING_EDIT;
      
   string pendingLabel = "Pending Label";
   ObjectCreate(0, pendingLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, pendingLabel, OBJPROP_TEXT, "Price: ");
   ObjectSetInteger(0, pendingLabel, OBJPROP_XDISTANCE, buttonX);
   ObjectSetInteger(0, pendingLabel, OBJPROP_YDISTANCE, 5+ buttonY+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin+buttonHeight+boxMargin);
   ObjectSetInteger(0, pendingLabel, OBJPROP_COLOR, Panel_Lable_Color);
   gTradingPanelObjects[10] = pendingLabel;  
   
}

// Panel action buttons
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{


   if(sparam == SELL_BUTTON && gCurrentDirection == 0)
   {
      if(gCurrentDirection == 0 && PendingPrice == 0) TakeTrade((int)-1);
      else if(PendingPrice > Bid) PlaceTrade(OP_SELLLIMIT);
      else if(PendingPrice < Bid) PlaceTrade(OP_SELLSTOP);
   }
   else if(sparam == BUY_BUTTON && gCurrentDirection == 0)
   {
      if(gCurrentDirection == 0 && PendingPrice == 0) TakeTrade((int)1);
      else if(PendingPrice > Ask) PlaceTrade(OP_BUYSTOP);
      else if(PendingPrice < Ask) PlaceTrade(OP_BUYLIMIT);
   }
   else if(sparam == CLOSE_ALL_BUTTON)
   {
      CloseOrdersAndReset();
      Print("Close all pressed.");
   }
   
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == TP_EDIT)
   {
      string takeProfitString = ObjectGetString(0, TP_EDIT, OBJPROP_TEXT);
      TakeProfit = StringToPips(takeProfitString);
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == ZONE_EDIT)
   {
      string zoneString = ObjectGetString(0, ZONE_EDIT, OBJPROP_TEXT);
      RecoveryZoneSize = StringToPips(zoneString);
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == PENDING_EDIT)
   {
      string pendingString = ObjectGetString(0, PENDING_EDIT, OBJPROP_TEXT);
      PendingPrice = NormalizeDouble(StringToDouble(pendingString), _Digits);
   }

   if(id==CHARTEVENT_KEYDOWN &&
         lparam=='Q'){
         
         
         
         }
         
         //--- If working in the tester, exit
   if(MQLInfoInteger(MQL_TESTER))
      return;
//--- Handling pressing the buttons in the panel
   if(id==CHARTEVENT_OBJECT_CLICK && StringFind(sparam,"BUTT_")>0)
     {
      PressButtonEvents(sparam);
     }
//--- Handling DoEasy library events
   if(id>CHARTEVENT_CUSTOM-1)
     {
      OnDoEasyEvent(id,lparam,dparam,sparam);
     } 


   if(sparam == SELL_BUTTON && gCurrentDirection == 0)
   {
      if(gCurrentDirection == 0 && PendingPrice == 0) TakeTrade((int)-1);
      else if(PendingPrice > Bid) PlaceTrade(OP_SELLLIMIT);
      else if(PendingPrice < Bid) PlaceTrade(OP_SELLSTOP);
   }
   else if(sparam == BUY_BUTTON && gCurrentDirection == 0)
   {
      if(gCurrentDirection == 0 && PendingPrice == 0) TakeTrade((int)1);
      else if(PendingPrice > Ask) PlaceTrade(OP_BUYSTOP);
      else if(PendingPrice < Ask) PlaceTrade(OP_BUYLIMIT);
   }
   else if(sparam == CLOSE_ALL_BUTTON)
   {
      CloseOrdersAndReset();
      Print("Close all pressed.");
   }
   
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == TP_EDIT)
   {
      string takeProfitString = ObjectGetString(0, TP_EDIT, OBJPROP_TEXT);
      TakeProfit = StringToPips(takeProfitString);
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == ZONE_EDIT)
   {
      string zoneString = ObjectGetString(0, ZONE_EDIT, OBJPROP_TEXT);
      RecoveryZoneSize = StringToPips(zoneString);
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == PENDING_EDIT)
   {
      string pendingString = ObjectGetString(0, PENDING_EDIT, OBJPROP_TEXT);
      PendingPrice = NormalizeDouble(StringToDouble(pendingString), _Digits);
   }
   
}


void DeleteTradePanel()
{
   for(int count = 0; count <= ArraySize(gTradingPanelObjects)-1; count++)
   {
      if(ArraySize(gTradingPanelObjects) > 0)
      {
         string objectName = gTradingPanelObjects[count];
         ObjectDelete(0, objectName);
      }
   }
}

// USEFUL FUNCTIONS

// Pip Point Function
double PipPoint(string Currency)
   {
      double CalcPoint = 0; 
      double CalcDigits = MarketInfo(Currency,MODE_DIGITS);
      if(CalcDigits == 2 || CalcDigits == 3) CalcPoint = 0.01;
      else if(CalcDigits == 4 || CalcDigits == 5) CalcPoint = 0.0001;
      else if(CalcDigits == 0) CalcPoint = 0;
      else if(CalcDigits == 1) CalcPoint = 0.1;
      return(CalcPoint);
   }
   
double GetSlippage(string Currency, int SlippagePips) 
   { 
      double CalcSlippage = SlippagePips;
      int CalcDigits = (int)MarketInfo(Currency,MODE_DIGITS); 
      if(CalcDigits == 0 || CalcDigits == 1 || CalcDigits == 2 || CalcDigits == 4) CalcSlippage = SlippagePips; 
      else if(CalcDigits == 3 || CalcDigits == 5) CalcSlippage = SlippagePips; 
      return(CalcSlippage); 
   }
   
int GetPoints(int Pips)
   {
      int CalcPoint = Pips; 
      double CalcDigits = MarketInfo(Symbol(),MODE_DIGITS);
      if(CalcDigits == 0 || CalcDigits == 1 || CalcDigits == 2 || CalcDigits == 4) CalcPoint = Pips;
      return(CalcPoint);
   }
   
int StringToPips(string text)
{
   int pips = StringToInteger(text);
   if(pips <= 0)
   {
      Alert("Invalid pips from string: ", pips);
   }
   return pips;
}



void CloseAllMarketOrders()
{
   int retryCount = 0;
   
   for(int Counter = 0; Counter <= OrdersTotal()-1; Counter++)
   {
      if(OrderSelect(Counter,SELECT_BY_POS))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol && (OrderType() == OP_BUY || OrderType() == OP_SELL))
         {
            // Close Order
            int CloseTicket = OrderTicket();
            double CloseLots = OrderLots();
            while(IsTradeContextBusy()) Sleep(10);
            
            RefreshRates();            
            double ClosePrice = MarketInfo(_Symbol,MODE_BID);
            if(OrderType() == OP_SELL) ClosePrice = MarketInfo(_Symbol, MODE_ASK);

            bool Closed = OrderClose(CloseTicket,CloseLots,ClosePrice,Slippage,Red);
            // Error Handling
            if(Closed == false)
            {
               int ErrorCode = GetLastError();
               string ErrAlert = StringConcatenate("Close All Market Orders - Error ",ErrorCode,".");
               Alert(ErrAlert);
               Print(ErrAlert);
            } else Counter--;
         }
      }  
    }
}

double GetTradeVolume(int pTradeNo)
{
   double lots = 0;
   double volume = 0;
   if(CustomLotSize1 == 0)
   {
      lots = (gLotSize*LotMultiplier)+LotAdditions; //increase the lot size
   } else if(CustomLotSize1 != 0){
      if(pTradeNo > 10) {
         Alert("No of trades exceeds custom lot size inputs (10)");
         return -1;
      } else {
         lots = gCustomLotSizes[pTradeNo-1];
      }
   }
   volume = CheckVolume(_Symbol, lots);
   return volume;
}

// Verify and adjust trade volume
double CheckVolume(string pSymbol,double pVolume)
{
	double minVolume = SymbolInfoDouble(pSymbol,SYMBOL_VOLUME_MIN);
	double maxVolume = SymbolInfoDouble(pSymbol,SYMBOL_VOLUME_MAX);
	double stepVolume = SymbolInfoDouble(pSymbol,SYMBOL_VOLUME_STEP);
	
	double tradeSize;
	if(pVolume < minVolume) 
	{
	   Alert("Sent volume is smaller than the minimum volume for this symbol: ", _Symbol, ", min: ", minVolume, ", sent: ", pVolume);
	   tradeSize = minVolume;
	}
	else if(pVolume > maxVolume)
	{
	   Alert("Sent volume is larger than the maximum volume for this symbol: ", _Symbol, ", max: ", maxVolume, ", sent: ", pVolume);	   
	   tradeSize = maxVolume;
	}   
	else tradeSize = MathRound(pVolume / stepVolume) * stepVolume;
	
	if(stepVolume >= 0.1) tradeSize = NormalizeDouble(tradeSize,1);
	else tradeSize = NormalizeDouble(tradeSize,2);
	
	return(tradeSize);
}

bool DeletePendingOrders(CLOSE_PENDING_TYPE pDeleteType)
{
   bool error = false;
   bool deleteOrder = false;
   
   // Loop through open order pool from oldest to newest
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      // Select order
      bool result = OrderSelect(order,SELECT_BY_POS);
      
      int orderType = OrderType();
      int orderMagicNumber = OrderMagicNumber();
      int orderTicket = OrderTicket();
      double orderVolume = OrderLots();
      
      // Determine if order type matches pCloseType
      if( (pDeleteType == CLOSE_ALL_PENDING && orderType != OP_BUY && orderType != OP_SELL)
         || (pDeleteType == CLOSE_BUY_LIMIT && orderType == OP_BUYLIMIT) 
         || (pDeleteType == CLOSE_SELL_LIMIT && orderType == OP_SELLLIMIT) 
         || (pDeleteType == CLOSE_BUY_STOP && orderType == OP_BUYSTOP)
         || (pDeleteType == CLOSE_SELL_STOP && orderType == OP_SELLSTOP) )
      {
         deleteOrder = true;
      }
      else deleteOrder = false;
      
      // Close order if pCloseType and magic number match currently selected order
      if(deleteOrder == true && orderMagicNumber == MagicNumber && OrderSymbol() == Symbol())
      {
         result = OrderDelete(orderTicket);
         
         if(result == false)
         {
            Print("Delete multiple orders, failed to delete order: ", orderTicket);
            error = true;
         }
         else order--;
      }
   }
   
   return(error);
}

int OpenPendingOrder(string pSymbol,int pType,double pVolume,double pPrice,double pStop,double pProfit,string pComment,datetime pExpiration,color pArrow)
{
   int retryCount = 0;
	int ticket = 0;
	int errorCode = 0;
	int max_attempts = 5;

	string orderType;
	string errDesc;
	
	// Order retry loop
	while(retryCount <= max_attempts)
	{
		while(IsTradeContextBusy()) Sleep(10);
		ticket = OrderSend(pSymbol, pType, pVolume, pPrice, Slippage, pStop, pProfit, pComment, MagicNumber, pExpiration, pArrow);
		
		// Error handling
   	if(ticket == -1)
   	{
   		errorCode = GetLastError();
   		bool checkError = RetryOnError(errorCode);
      	
      	// Unrecoverable error
      	if(checkError == false)  
   		{
     			Alert("Open ",orderType," order: Error ",errorCode,".");
     			Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
   			break;
   		}
   		
   		// Retry on error
   		else
   		{
   			Print("Server error detected, retrying...");
   			Sleep(3000);
   			retryCount++;
   		}
   	}
   	
   	// Order successful
   	else
   	{
   	   Comment(orderType," order #",ticket," opened on ",_Symbol);
   	   Print(orderType," order #",ticket," opened on ",_Symbol);
   	   break;
   	} 
   }
   
   // Failed after retry
	if(retryCount > max_attempts)
	{
		Alert("Open ",orderType," order: Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
	}

	return(ticket);
}

bool RetryOnError(int pErrorCode)
{
	// Retry on these error codes
	switch(pErrorCode)
	{
		case ERR_BROKER_BUSY:
		case ERR_COMMON_ERROR:
		case ERR_NO_ERROR:
		case ERR_NO_CONNECTION:
		case ERR_NO_RESULT:
		case ERR_SERVER_BUSY:
		case ERR_NOT_ENOUGH_RIGHTS:
      case ERR_MALFUNCTIONAL_TRADE:
      case ERR_TRADE_CONTEXT_BUSY:
      case ERR_TRADE_TIMEOUT:
      case ERR_REQUOTE:
      case ERR_TOO_MANY_REQUESTS:
      case ERR_OFF_QUOTES:
      case ERR_PRICE_CHANGED:
      case ERR_TOO_FREQUENT_REQUESTS:
		
		return(true);
	}
	
	return(false);
}

int OpenMarketOrder(string pSymbol, int pType, double pVolume, string pComment, color pArrow)
{
	int retryCount = 0;
	int ticket = 0;
	int errorCode = 0;
	int max_attempts = 5;
	int wait_time = 3000;
	
	double orderPrice = 0;
	
	string orderType;
	string errDesc;
	
	// Order retry loop
	while(retryCount <= max_attempts) 
	{
		while(IsTradeContextBusy()) Sleep(10);
		
		// Get current bid/ask price
		if(pType == OP_BUY) orderPrice = MarketInfo(pSymbol,MODE_ASK);
		else if(pType == OP_SELL) orderPrice = MarketInfo(pSymbol,MODE_BID);

		// Place market order
		ticket = OrderSend(pSymbol,pType,pVolume,orderPrice,Slippage,0,0,pComment,MagicNumber,0,pArrow);
	   
		// Error handling
		if(ticket == -1)
		{
			errorCode = GetLastError();
			bool checkError = RetryOnError(errorCode);
			
			// Unrecoverable error
			if(checkError == false)
			{
				Alert("Open ",orderType," order: Error ",errorCode,".");
				Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
				break;
			}
			
			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(wait_time);
				retryCount++;
			}
		}
		
		// Order successful
		else
		{
		   Comment(orderType," order #",ticket," opened on ",pSymbol);
		   Print(orderType," order #",ticket," opened on ",pSymbol);
		   break;
		} 
   }
   
   // Failed after retry
	if(retryCount > max_attempts)
	{
		Alert("Open ",orderType," order: Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
	}
   
   return(ticket);
} 

// Return trade size based on risk per trade of stop loss in points
double GetTradeSize(string pSymbol, double pFixedVol, double pPercent, int pStopPoints)
{
	double tradeSize;
	
	if(pPercent > 0 && pStopPoints > 0)
	{
		if(pPercent > 10) pPercent = 10;
		
		double margin = AccountInfoDouble(ACCOUNT_BALANCE) * (pPercent / 100);
		double tickSize = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_VALUE);
		
		tradeSize = (margin / pStopPoints) / tickSize;
		tradeSize = CheckVolume(pSymbol,tradeSize);
		
		return(tradeSize);
	}
	else
	{
		tradeSize = pFixedVol;
		tradeSize = CheckVolume(pSymbol,tradeSize);
		
		return(tradeSize);
	}
}

// Create datetime value
datetime CreateDateTime(int pHour = 0, int pMinute = 0) 
{
	MqlDateTime timeStruct;
	TimeToStruct(TimeCurrent(),timeStruct);
	
	timeStruct.hour = pHour;
	timeStruct.min = pMinute;
	
	datetime useTime = StructToTime(timeStruct);
	
	return(useTime);
}

// Check timer
bool CheckDailyTimer()
{
   datetime TimeStart = CreateDateTime(StartHour, StartMinute);
   datetime TimeEnd = CreateDateTime(EndHour, EndMinute);
   
   datetime currentTime;
	if(UseLocalTime == true) currentTime = TimeLocal();
	else currentTime = TimeCurrent();
   
   // check if the timer goes over midnight
	if(TimeEnd <= TimeStart)	
	{
		TimeStart -= 86400;
		
		if(currentTime > TimeEnd)
		{
			TimeStart += 86400;
			TimeEnd += 86400;
		}
	} 
	
	bool timerOn = false;
	if(currentTime >= TimeStart && currentTime < TimeEnd) 
	{
		timerOn = true;
	}
	
	return(timerOn);
}


void FindOpenOrders()
{
   double largest_lots = 0;
   int ticket = -1;
   int open_orders = 0;
   int stopTicket = 0;
   for(int Counter = 0; Counter <= OrdersTotal()-1; Counter++)
   {
      if(OrderSelect(Counter,SELECT_BY_POS))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol && (OrderType() == OP_BUY || OrderType() == OP_SELL))
         {
            open_orders++;
            if(OrderLots() > largest_lots)
            { 
               ticket = OrderTicket();
               largest_lots = OrderLots();
            }
         }
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol && OrderType() == OP_BUYSTOP)
         {
            gBuyStopTicket = OrderTicket();
            stopTicket = gBuyStopTicket;
         } else if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol && OrderType() == OP_SELLSTOP)
         {
            gSellStopTicket = OrderTicket();
            stopTicket = gSellStopTicket;
         }
      }
   }
   
   if(ticket > 0)
   {
      if(OrderSelect(ticket, SELECT_BY_TICKET))
      {
         int type = OrderType();
         if(type == OP_BUY)
         {
            gCurrentDirection = 1;
            gBuyTicket = ticket;
         } else if(type == OP_SELL)
         {
            gCurrentDirection = -1;
            gSellTicket = ticket;
         }   
         if(open_orders > 1) gRecoveryInitiated = true;
      }
      Print("Check for orders complete, resuming recovery direction of trade: ", ticket, " with recovery stop: ", stopTicket, " in place. ", open_orders, " orders already opened.");
   } else {
      Print("Check for orders complete, none currently open.");
   }     
}         













//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+






int OnInit()
  { 
  OnnInit();
  licenseState();
  
  
  
  //--- Name of the company 
   string company=AccountInfoString(ACCOUNT_COMPANY); 
//--- Name of the client 
   string name=AccountInfoString(ACCOUNT_NAME); 
//--- Account number 
   long login=AccountInfoInteger(ACCOUNT_LOGIN); 
//--- Name of the server 
   string server=AccountInfoString(ACCOUNT_SERVER); 
//--- Account currency 
   string currency=AccountInfoString(ACCOUNT_CURRENCY); 
//--- Demo, contest or real account 
   ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
//--- Now transform the value of  the enumeration into an understandable form 
   string trade_mode; 
   switch(account_type) 
     { 
      case  ACCOUNT_TRADE_MODE_DEMO: 
         trade_mode="demo"; 
         break; 
      case  ACCOUNT_TRADE_MODE_CONTEST: 
         trade_mode="contest"; 
         break; 
      default: 
         trade_mode="real"; 
         break; 
     } 
//--- Stop Out is set in percentage or money 
   ENUM_ACCOUNT_STOPOUT_MODE stop_out_mode=(ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE); 
//--- Get the value of the levels when Margin Call and Stop Out occur 
   double margin_call=AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL); 
   double stop_out=AccountInfoDouble(ACCOUNT_MARGIN_SO_SO); 
//--- Show brief account information 
   PrintFormat("The account of the client '%s' #%d %s opened in '%s' on the server '%s'", 
               name,login,trade_mode,company,server+"\nAccount currency - %s, MarginCall and StopOut levels are set in %s", 
               currency,(stop_out_mode==ACCOUNT_STOPOUT_MODE_PERCENT)?"percentage":" money"+"\nMarginCall=%G, StopOut=%G",margin_call,stop_out); 
               
               
  //--- show bot name
   Comment("n\n\n\n\n\n\n\nBot name: "+bot.Name()+"\nLicense State:"+licenseState()+"\n*******************\nEA init Date: " + TimeToString(now, TIME_DATE|TIME_MINUTES)+"\n" +"*******************\nExpiration Date :"+TimeToString(allowed_until, TIME_DATE|TIME_MINUTES)
    +"\nCPU :"+terminalInfo.CPUCores()+"\nTotal Memory :"+terminalInfo.MemoryTotal()+"Memory used: "+ terminalInfo.MemoryUsed()+ "\nDisk space: "+terminalInfo.DiskSpace() +"\n"+server+"\nAccount currency "+ currency+"\nStop out:"+(stop_out_mode==ACCOUNT_STOPOUT_MODE_PERCENT)+"\n margin_call,stop_out:"+margin_call,stop_out+"\n Drop Percentage %:"+dropPencent);
 
  
               
               
              
   ResetLastError(); 
   
	


	while ( !IsStopped() )
	{
		Pre_IsConnected = Now_IsConnected;
		Now_IsConnected = terminalInfo.IsConnected();
		
		if ( firsts ) { Pre_IsConnected = !Now_IsConnected; }
		
		if ( Now_IsConnected != Pre_IsConnected )
		{
			if ( Now_IsConnected )
			{
				Connect_Start = TimeLocal();
				if ( !firsts )
				{
					printf("Offline"); status="Offline";
				}
				if ( IsStopped() ) { break; }
				printf("Online"); status="Online";
				}
			else
			{
				Connect_Stop = TimeLocal();
				if ( !firsts )
				{  printf("Online"); status="Online";
			   }
				if ( IsStopped() ) { break; }
				printf("Offline"); status="Offline";
				}		
		}

		firsts = false;
		Sleep(1000);
	}

	if ( Now_IsConnected )
	{  printf("Expert is Online"); status="Online";
	 status="Online";
	}
	else
	{  printf("Offline"); status="Offline";
		

	}
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   time_signal=0;

//--- set token
   bot.Token(telegramToken);

   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
      MaxSlippage *= 10;
     }
   //initialize LotDigits
   double LotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(NormalizeDouble(LotStep, 3) == round(LotStep))
      LotDigits = 0;
   else if(NormalizeDouble(10*LotStep, 3) == round(10*LotStep))
      LotDigits = 1;
   else if(NormalizeDouble(100*LotStep, 3) == round(100*LotStep))
      LotDigits = 2;
   else LotDigits = 3;
   MaxSL = MaxSL * myPoint;
   MinSL = MinSL * myPoint;
   MaxTP = MaxTP * myPoint;
   MinTP = MinTP * myPoint;
   int i;
   //initialize crossed
   for (i = 0; i < ArraySize(crossed); i++){
      crossed[i] = true;
      

   }
 if(inTargetProfitMoney <= 0)
     {
      Alert("Invalid input");
      return(INIT_PARAMETERS_INCORRECT);
     }

   inCutLossMoney = MathAbs(inCutLossMoney) * -1;
   
   //--- Calling the function displays the list of enumeration constants in the journal 
//--- (the list is set in the strings 22 and 25 of the DELib.mqh file) for checking the constants validity
   //EnumNumbersTest();

//--- Set EA global variables
   prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_";
   for(i=0;i<TOTAL_BUTT;i++)
     {
      butt_data[i].name=prefix+EnumToString((ENUM_BUTTONS)i);
      butt_data[i].text=EnumToButtText((ENUM_BUTTONS)i);
     }
   lot=NormalizeLot(Symbol(),fmax(InpLots,MinimumLots(Symbol())*2.0));
   magic_number=InpMagic;
   stoploss=InpStopLoss;
   takeprofit=InpTakeProfit;
   distance_pending=InpDistance;
   distance_stoplimit=InpDistanceSL;
   slippage=InpSlippage;
   trailing_stop=InpTrailingStop*Point();
   trailing_step=InpTrailingStep*Point();
   trailing_start=InpTrailingStart;
   stoploss_to_modify=InpStopLossModify;
   takeprofit_to_modify=InpTakeProfitModify;
   
//--- Check if working with the full list is selected
   used_symbols_mode=InpModeUsedSymbols;
   if((ENUM_SYMBOLS_MODE)used_symbols_mode==SYMBOLS_MODE_ALL)
     {
      int total=SymbolsTotal(false);
      string ru_n="\nКоличество символов на сервере "+(string)total+".\nМаксимальное количество: "+(string)SYMBOLS_COMMON_TOTAL+" символов.";
      string en_n="\nThe number of symbols on server "+(string)total+".\nMaximal number: "+(string)SYMBOLS_COMMON_TOTAL+" symbols.";
      string caption=TextByLanguage("Внимание!","Attention!");
      string ru="Выбран режим работы с полным списком.\nВ этом режиме первичная подготовка списка коллекции символов может занять длительное время."+ru_n+"\nПродолжить?\n\"Нет\" - работа с текущим символом \""+Symbol()+"\"";
      string en="Full list mode selected.\nIn this mode, the initial preparation of the collection symbols list may take a long time."+en_n+"\nContinue?\n\"No\" - working with the current symbol \""+Symbol()+"\"";
      string message=TextByLanguage(ru,en);
      int flags=(MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2);
      int mb_res=MessageBox(message,caption,flags);
      switch(mb_res)
        {
         case IDNO : 
           used_symbols_mode=SYMBOLS_MODE_CURRENT; 
           break;
         default:
           break;
        }
     }
//--- Fill in the array of used symbols
   used_symbols=InpUsedSymbols;
   CreateUsedSymbolsArray((ENUM_SYMBOLS_MODE)used_symbols_mode,used_symbols,array_used_symbols);

//--- Set the type of the used symbol list in the symbol collection
   engine.SetUsedSymbols(array_used_symbols);
//--- Displaying the selected mode of working with the symbol object collection
   Print(engine.ModeSymbolsListDescription(),TextByLanguage(". Количество используемых символов: ",". Number of symbols used: "),engine.GetSymbolsCollectionTotal());

//--- Set controlled values for symbols
   string ru1="",ru2="",ru3="",en1="",en2="",en3="";
   //--- Get the list of all collection symbols
   CArrayObj *list=engine.GetListAllUsedSymbols();
   if(list!=NULL && list.Total()!=0)
     {
      //--- In a loop by the list, set the necessary values for tracked symbol properties
      //--- By default, the LONG_MAX value is set to all properties, which means "Do not track this property" 
      //--- It can be enabled or disabled (by setting the value less than LONG_MAX or vice versa - set the LONG_MAX value) at any time and anywhere in the program
      for(i=0;i<list.Total();i++)
        {
         CSymbol* symbol=list.At(i);
         if(symbol==NULL)
            continue;
         //--- Set control of the symbol price increase by 10 points
         symbol.SetControlBidInc(10*symbol.Point());
         ru1="Контролируем увеличение цены Bid для символа ";
         ru2=" на ";
         ru3=" пунктов";
         en1="Bid price increase control for symbol ";
         en2=" by ";
         en3=" points";
         Print(TextByLanguage(ru1,en1),symbol.Name(),TextByLanguage(ru2,en2),DoubleToString(symbol.GetControlledDoubleValueINC(SYMBOL_PROP_BID),symbol.Digits()));
         
         //--- Set control of the symbol price decrease by 10 points
         symbol.SetControlBidDec(10*symbol.Point());
         ru1="Контролируем уменьшение цены Bid для символа ";
         ru2=" на ";
         ru3=" пунктов";
         en1="Bid price decrease control for symbol ";
         en2=" by ";
         en3=" points";
         Print(TextByLanguage(ru1,en1),symbol.Name(),TextByLanguage(ru2,en2),DoubleToString(symbol.GetControlledDoubleValueINC(SYMBOL_PROP_BID),symbol.Digits()));
         
         //--- Set control of the symbol spread increase by 4 points
         symbol.SetControlSpreadInc(4);
         ru1="Контролируем увеличение спреда для символа ";
         ru2=" на ";
         ru3=" пунктов";
         en1="Spread value increase control for symbol ";
         en2=" by ";
         en3=" points";
         Print(TextByLanguage(ru1,en1),symbol.Name(),TextByLanguage(ru2,en2),(string)symbol.GetControlledLongValueINC(SYMBOL_PROP_SPREAD),TextByLanguage(ru3,en3));
         
         //--- Set control of the symbol spread decrease by 4 points
         symbol.SetControlSpreadDec(4);
         ru1="Контролируем уменьшение спреда для символа ";
         ru2=" на ";
         ru3=" пунктов";
         en1="Spread value decrease control for symbol ";
         en2=" by ";
         en3=" points";
         Print(TextByLanguage(ru1,en1),symbol.Name(),TextByLanguage(ru2,en2),(string)symbol.GetControlledLongValueDEC(SYMBOL_PROP_SPREAD),TextByLanguage(ru3,en3));
         
         //--- Set control of the current spread by the value of 15 points
         symbol.SetControlSpreadLevel(15);
         ru1="Контролируем значение спреда для символа ";
         ru2=" в ";
         ru3=" пунктов";
         en1="Control the spread value for the symbol ";
         en2=" at ";
         en3=" points";
         Print(TextByLanguage(ru1,en1),symbol.Name(),TextByLanguage(ru2,en2),(string)symbol.GetControlledLongValueLEVEL(SYMBOL_PROP_SPREAD),TextByLanguage(ru3,en3));
         Print("------");
         
         //--- Set control of the price crossing the level of 1.10700 for the current symbol
         if(symbol.Name()==Symbol())
           {
            symbol.SetControlBidLevel(1.10300);
            ru1="Контролируемый уровень цены Bid для символа ";
            ru2=" установлен в значение ";
            en1="Controlled level of Bid price for the symbol ";
            en2=" is set to ";
            Print(TextByLanguage(ru1,en1),symbol.Name(),TextByLanguage(ru2,en2),DoubleToString(symbol.GetControlledDoubleValueLEVEL(SYMBOL_PROP_BID),symbol.Digits()));
           }
        }
     }
//--- Set controlled values for the current account
   Print("------");
   CAccount* account=engine.GetAccountCurrent();
   if(account!=NULL)
     {
      //--- Set control of the profit increase
      account.SetControlledValueINC(ACCOUNT_PROP_PROFIT,10.0);
      Print(TextByLanguage("Контролируем увеличение прибыли аккаунта на ","Controlling account profit increase by "),DoubleToString(account.GetControlledDoubleValueINC(ACCOUNT_PROP_PROFIT),(int)account.CurrencyDigits())," ",account.Currency());
      //--- Set control of the funds increase
      account.SetControlledValueINC(ACCOUNT_PROP_EQUITY,15.0);
      Print(TextByLanguage("Контролируем увеличение средств аккаунта на ","Controlling account equity increase by "),DoubleToString(account.GetControlledDoubleValueINC(ACCOUNT_PROP_EQUITY),(int)account.CurrencyDigits())," ",account.Currency());
      //--- Set profit control level
      account.SetControlledValueLEVEL(ACCOUNT_PROP_PROFIT,20.0);
      Print(TextByLanguage("Контролируем уровень прибыли аккаунта в ","Controlling the account profit level of "),DoubleToString(account.GetControlledDoubleValueLEVEL(ACCOUNT_PROP_PROFIT),(int)account.CurrencyDigits())," ",account.Currency());
     }

//--- Check and remove remaining EA graphical objects
   if(IsPresentObects(prefix))
      ObjectsDeleteAll(0,prefix);

//--- Create the button panel
   if(!CreateButtons(InpButtShiftX,InpButtShiftY))
      return INIT_FAILED;
//--- Set trailing activation button status
   ButtonState(butt_data[TOTAL_BUTT-1].name,trailing_on);

//--- Set CTrade trading class parameters
#ifdef __MQL5__
   trade.SetDeviationInPoints(slippage);
   trade.SetExpertMagicNumber(magic_number);
   trade.SetTypeFillingBySymbol(Symbol());
   trade.SetMarginMode();
   trade.LogLevel(LOG_LEVEL_NO);
#endif 
//---

         EventSetTimer(3600);
   OnTimer();
//--- done
   return(INIT_SUCCEEDED);
   
   
}   
   
   
   
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


void OnTick()

{

   if(CopyTime(NULL,0,0,1,time)!=1)
      return;

//--- check the signal on each bar
   if(time_signal!=time[0])
     {
      //--- first calc
      if(time_signal==0)
        {
         time_signal=time[0];
         return;
        }
        
        double macd[2]={0.0};
        double Trendfollowers=macd[2];
      double signal[2]={0.0};

      if(iCustom(macd_handle,0,0,2,Trendfollowers)!=2)
         return;
         

      if(iCustom(macd_handle,0,0,2,Trendfollowers)!=2)
         return;

      time_signal=time[0];

      //--- Send signal BUY
      if(macd[1]>signal[1] && 
         macd[0]<=signal[0])
        {
         string msg=StringFormat("Name: MACD Signal\nSymbol: %s\nTimeframe: %s\nType: Buy\nPrice: %s\nTime: %s",
                                 _Symbol,
                                 StringSubstr(EnumToString( PERIOD_CURRENT),7),
                                 DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits),
                                 TimeToString(time[0]));
         int res=bot.SendMessage(ChannelName,msg);
         if(res!=0)
            Print("Error: ",GetErrorDescription(res));
        }

      //--- Send signal SELL
      if(macd[1]<signal[1] && 
         macd[0]>=signal[0])
        {
         string msg=StringFormat("Name: MACD Signal\nSymbol: %s\nTimeframe: %s\nType: Sell\nPrice: %s\nTime: %s",
                                 _Symbol,
                                 StringSubstr(EnumToString( PERIOD_CURRENT),7),
                                 DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits),
                                 TimeToString(time[0]));
         int res=bot.SendMessage(ChannelName,msg);
         if(res!=0)
            Print("Error: ",GetErrorDescription(res));
        }
     }
//Calling trade function
    
    
    
   double   tFloating = 0.0;
   int tOrder  = OrdersTotal();
   for(int i=tOrder-1; i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber() == inMagicNumber)
           {
            tFloating   += OrderProfit()+OrderCommission() + OrderSwap();
           }
        }
     }

   if(tFloating >= inTargetProfitMoney || (tFloating <= inCutLossMoney && inCutLossMoney < 0))
     {
      fCloseAllOrders();
     }
    
   

//--- Initializing the last events
   static ENUM_TRADE_EVENT last_trade_event=WRONG_VALUE;
//--- If working in the tester
   if(MQLInfoInteger(MQL_TESTER))
     {
      engine.OnTimer();
      PressButtonsControl();
     }
//--- If the last trading event changed
   if(engine.LastTradeEvent()!=last_trade_event)
     {
      last_trade_event=engine.LastTradeEvent();
      Comment("\nLast trade event: ",engine.GetLastTradeEventDescription());
      engine.ResetLastTradeEvent();
     }
//--- If there is an account event
   if(engine.IsAccountsEvent())
     {
      //--- If this is a tester
      if(MQLInfoInteger(MQL_TESTER))
        {
         //--- Get the list of all account events occurred simultaneously
         CArrayObj* list=engine.GetListAccountEvents();
         if(list!=NULL)
           {
            //--- Get the next event in a loop
            int total=list.Total();
            for(int i=0;i<total;i++)
              {
               //--- take an event from the list
               CEventBaseObj *event=list.At(i);
               if(event==NULL)
                  continue;
               //--- Send an event to the event handler
               long lparam=event.LParam();
               double dparam=event.DParam();
               string sparam=event.SParam();
               OnDoEasyEvent(CHARTEVENT_CUSTOM+event.ID(),lparam,dparam,sparam);
              }
           }        }
     }
//--- If there is a symbol collection event
   if(engine.IsSymbolsEvent())
     {
      //--- If this is a tester
      if(MQLInfoInteger(MQL_TESTER))
        {
         //--- Get the list of all symbol events occurred simultaneously
         CArrayObj* list=engine.GetListSymbolsEvents();
         if(list!=NULL)
           {
            //--- Get the next event in a loop
            int total=list.Total();
            for(int i=0;i<total;i++)
              {
               //--- take an event from the list
               CEventBaseObj *event=list.At(i);
               if(event==NULL)
                  continue;
               //--- Send an event to the event handler
               long lparam=event.LParam();
               double dparam=event.DParam();
               string sparam=event.SParam();
               OnDoEasyEvent(CHARTEVENT_CUSTOM+event.ID(),lparam,dparam,sparam);
              }
           }
        }
     }
//--- If the trailing flag is set
   if(trailing_on)
     {
      TrailingPositions();
      TrailingOrders();
     }
     

   
  mytrade();
  
  OnnTick();
  
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimers()
  {
//--- Launch the library timer (only not in the tester)
   if(!MQLInfoInteger(MQL_TESTER))
      engine.OnTimer();
  }

//+------------------------------------------------------------------+
//| Handling DoEasy library events                                   |
//+------------------------------------------------------------------+
void OnDoEasyEvent(const int id,
                   const long &lparam,
                   const double &dparam,
                   const string &sparam)
  {
   int idx=id-CHARTEVENT_CUSTOM;
   string event="::"+string(idx);
   
//--- Retrieve (1) event time milliseconds, (2) reason and (3) source from lparam, as well as (4) set the exact event time
   ushort msc=engine.EventMSC(lparam);
   ushort reason=engine.EventReason(lparam);
   ushort source=engine.EventSource(lparam);
   long times=TimeCurrent()*1000+msc;
   
//--- Handling symbol events
   if(source==COLLECTION_SYMBOLS_ID)
     {
      CSymbol *symbol=engine.GetSymbolObjByName(sparam);
      if(symbol==NULL)
         return;
      //--- Number of decimal places in the event value - in case of a 'long' event, it is 0, otherwise - Digits() of a symbol
      int digits=(idx<SYMBOL_PROP_INTEGER_TOTAL ? 0 : symbol.Digits());
      //--- Event text description
      string id_descr=(idx<SYMBOL_PROP_INTEGER_TOTAL ? symbol.GetPropertyDescription((ENUM_SYMBOL_PROP_INTEGER)idx) : symbol.GetPropertyDescription((ENUM_SYMBOL_PROP_DOUBLE)idx));
      //--- Property change text value
      string value=DoubleToString(dparam,digits);
      
      //--- Check event reasons and display its description in the journal
      if(reason==BASE_EVENT_REASON_INC)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_DEC)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_MORE_THEN)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_LESS_THEN)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_EQUALS)
        {
         Print(symbol.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
     }   
     
//--- Handling account events
   else if(source==COLLECTION_ACCOUNT_ID)
     {
      CAccount *account=engine.GetAccountCurrent();
      if(account==NULL)
         return;
      //--- Number of decimal places in the event value - in case of a 'long' event, it is 0, otherwise - Digits() of a symbol
      int digits=int(idx<ACCOUNT_PROP_INTEGER_TOTAL ? 0 : account.CurrencyDigits());
      //--- Event text description
      string id_descr=(idx<ACCOUNT_PROP_INTEGER_TOTAL ? account.GetPropertyDescription((ENUM_ACCOUNT_PROP_INTEGER)idx) : account.GetPropertyDescription((ENUM_ACCOUNT_PROP_DOUBLE)idx));
      //--- Property change text value
      string value=DoubleToString(dparam,digits);
      
      //--- Checking event reasons and handling the increase of funds by a specified value,
      //--- for other events, simply display their descriptions in the journal
      
      //--- In case of a property value increase
      if(reason==BASE_EVENT_REASON_INC)
        {
         //--- Display an event in the journal
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
         //--- if this is an equity increase
         if(idx==ACCOUNT_PROP_EQUITY)
           {
            //--- Get the list of all open positions
            CArrayObj* list_positions=engine.GetListMarketPosition();
            //--- Select positions with the profit exceeding zero
            list_positions=CSelect::ByOrderProperty(list_positions,ORDER_PROP_PROFIT_FULL,0,MORE);
            if(list_positions!=NULL)
              {
               //--- Sort the list by profit considering commission and swap
               list_positions.Sort(SORT_BY_ORDER_PROFIT_FULL);
               //--- Get the position index with the highest profit
               int index=CSelect::FindOrderMax(list_positions,ORDER_PROP_PROFIT_FULL);
               if(index>WRONG_VALUE)
                 {
                  COrder* position=list_positions.At(index);
                  if(position!=NULL)
                    {
                     //--- Get a ticket of a position with the highest profit and close the position by a ticket
                     #ifdef __MQL5__
                        trade.PositionClose(position.Ticket());
                     #else 
                        PositionClose(position.Ticket(),position.Volume());
                     #endif 
                    }
                 }
              }
           }
        }
      //--- Other events are simply displayed in the journal
      if(reason==BASE_EVENT_REASON_DEC)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_MORE_THEN)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_LESS_THEN)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
      if(reason==BASE_EVENT_REASON_EQUALS)
        {
         Print(account.EventDescription(idx,(ENUM_BASE_EVENT_REASON)reason,source,value,id_descr,digits));
        }
     } 
     
//--- Handling trading events
   else if(idx>TRADE_EVENT_NO_EVENT && idx<TRADE_EVENTS_NEXT_CODE)
     {
      event=EnumToString((ENUM_TRADE_EVENT)ushort(idx));
      int digits=(int)SymbolInfoInteger(sparam,SYMBOL_DIGITS);
     }
     
//--- Handling market watch window events
   else if(idx>MARKET_WATCH_EVENT_NO_EVENT && idx<SYMBOL_EVENTS_NEXT_CODE)
     {
      string name="";
      //--- Market Watch window event
      string descr=engine.GetMWEventDescription((ENUM_MW_EVENT)idx);
      name=(idx==MARKET_WATCH_EVENT_SYMBOL_SORT ? "" : ": "+sparam);
      Print(TimeMSCtoString(lparam)," ",descr,name);
     }
  }
//+------------------------------------------------------------------+
//| Return the flag of a prefixed object presence                    |
//+------------------------------------------------------------------+
bool IsPresentObects(const string object_prefix)
  {
   for(int i=ObjectsTotal(0,0)-1;i>=0;i--)
      if(StringFind(ObjectName(0,i,0),object_prefix)>WRONG_VALUE)
         return true;
   return false;
  }
//+------------------------------------------------------------------+
//| Tracking the buttons' status                                     |
//+------------------------------------------------------------------+
void PressButtonsControl(void)
  {
   int total=ObjectsTotal(0,0);
   for(int i=0;i<total;i++)
     {
      string obj_name=ObjectName(0,i);
      if(StringFind(obj_name,prefix+"BUTT_")<0)
         continue;
      PressButtonEvents(obj_name);
     }
  }
//+------------------------------------------------------------------+
//| Create the buttons panel                                         |
//+------------------------------------------------------------------+
bool CreateButtons(const int shift_x=30,const int shift_y=0)
  {
   int h=18,w=84,offset=2;
   int cx=offset+shift_x,cy=offset+shift_y+(h+1)*(TOTAL_BUTT/2)+3*h+1;
   int x=cx,y=cy;
   int shift=0;
   for(int i=0;i<TOTAL_BUTT;i++)
     {
      x=x+(i==7 ? w+2 : 0);
      if(i==TOTAL_BUTT-6) x=cx;
      y=(cy-(i-(i>6 ? 7 : 0))*(h+1));
      if(!ButtonCreate(butt_data[i].name,x,y,(i<TOTAL_BUTT-6 ? w : w*2+2),h,butt_data[i].text,(i<4 ? clrGreen : i>6 && i<11 ? clrRed : clrBlue)))
        {
         Alert(TextByLanguage("Не удалось создать кнопку \"","Could not create button \""),butt_data[i].text);
         return false;
        }
     }
   ChartRedraw(0);
   return true;
  }
//+------------------------------------------------------------------+
//| Create the button                                                |
//+------------------------------------------------------------------+
bool ButtonCreate(const string name,const int x,const int y,const int w,const int h,const string text,const color clr,const string font="Calibri",const int font_size=8)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0)) 
        { 
         Print(DFUN,TextByLanguage("не удалось создать кнопку! Код ошибки=","Could not create button! Error code="),GetLastError()); 
         return false; 
        } 
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetString(0,name,OBJPROP_FONT,font);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrGray);
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//| Return the button status                                         |
//+------------------------------------------------------------------+
bool ButtonState(const string name)
  {
   return (bool)ObjectGetInteger(0,name,OBJPROP_STATE);
  }
//+------------------------------------------------------------------+
//| Set the button status                                            |
//+------------------------------------------------------------------+
void ButtonState(const string name,const bool state)
  {
   ObjectSetInteger(0,name,OBJPROP_STATE,state);
   if(name==butt_data[TOTAL_BUTT-1].name)
     {
      if(state)
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'220,255,240');
      else
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'240,240,240');
     }
  }
//+------------------------------------------------------------------+
//| Transform enumeration into the button text                       |
//+------------------------------------------------------------------+
string EnumToButtText(const ENUM_BUTTONS member)
  {
   string txt=StringSubstr(EnumToString(member),5);
   StringToLower(txt);
   StringReplace(txt,"set_take_profit","Set TakeProfit");
   StringReplace(txt,"set_stop_loss","Set StopLoss");
   StringReplace(txt,"trailing_all","Trailing All");
   StringReplace(txt,"buy","Buy");
   StringReplace(txt,"sell","Sell");
   StringReplace(txt,"_limit"," Limit");
   StringReplace(txt,"_stop"," Stop");
   StringReplace(txt,"close_","Close ");
   StringReplace(txt,"2"," 1/2");
   StringReplace(txt,"_by_"," by ");
   StringReplace(txt,"profit_","Profit ");
   StringReplace(txt,"delete_","Delete ");
   return txt;
  }
//+------------------------------------------------------------------+
//| Handle pressing the buttons                                      |
//+------------------------------------------------------------------+
void PressButtonEvents(const string button_name)
  {
   //--- Convert button name into its string ID
   string button=StringSubstr(button_name,StringLen(prefix));
   //--- If the button is pressed
   if(ButtonState(button_name))
     {
      //--- If the BUTT_BUY button is pressed: Open Buy position
      if(button==EnumToString(BUTT_BUY))
        {
         //--- Get the correct StopLoss and TakeProfit prices relative to StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY,0,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY,0,takeprofit);
         //--- Open Buy position
         #ifdef __MQL5__
            trade.Buy(lot,Symbol(),0,sl,tp);
         #else 
            Buy(lot,Symbol(),magic_number,sl,tp);
         #endif 
        }
      //--- If the BUTT_BUY_LIMIT button is pressed: Place BuyLimit
      else if(button==EnumToString(BUTT_BUY_LIMIT))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_LIMIT,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY_LIMIT,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY_LIMIT,price_set,takeprofit);
         //--- Set BuyLimit order
         #ifdef __MQL5__
            trade.BuyLimit(lot,price_set,Symbol(),sl,tp);
         #else 
            BuyLimit(lot,price_set,Symbol(),magic_number,sl,tp);
         #endif 
        }
      //--- If the BUTT_BUY_STOP button is pressed: Set BuyStop
      else if(button==EnumToString(BUTT_BUY_STOP))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_STOP,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY_STOP,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY_STOP,price_set,takeprofit);
         //--- Set BuyStop order
         #ifdef __MQL5__
            trade.BuyStop(lot,price_set,Symbol(),sl,tp);
         #else 
            BuyStop(lot,price_set,Symbol(),magic_number,sl,tp);
         #endif 
        }
      //--- If the BUTT_BUY_STOP_LIMIT button is pressed: Set BuyStopLimit
      else if(button==EnumToString(BUTT_BUY_STOP_LIMIT))
        {
         //--- Get the correct BuyStop order placement price relative to StopLevel
         double price_set_stop=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_STOP,distance_pending);
         //--- Calculate BuyLimit order price relative to BuyStop level considering StopLevel
         double price_set_limit=CorrectPricePending(Symbol(),ORDER_TYPE_BUY_LIMIT,distance_stoplimit,price_set_stop);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_BUY_STOP,price_set_limit,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_BUY_STOP,price_set_limit,takeprofit);
         //--- Set BuyStopLimit order
         #ifdef __MQL5__
            trade.OrderOpen(Symbol(),ORDER_TYPE_BUY_STOP_LIMIT,lot,price_set_limit,price_set_stop,sl,tp);
         #else 
            
         #endif 
        }
      //--- If the BUTT_SELL button is pressed: Open Sell position
      else if(button==EnumToString(BUTT_SELL))
        {
         //--- Get the correct StopLoss and TakeProfit prices relative to StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL,0,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL,0,takeprofit);
         //--- Open Sell position
         #ifdef __MQL5__
            trade.Sell(lot,Symbol(),0,sl,tp);
         #else 
            Sell(lot,Symbol(),magic_number,sl,tp);
         #endif 
        }
      //--- If the BUTT_SELL_LIMIT button is pressed: Set SellLimit
      else if(button==EnumToString(BUTT_SELL_LIMIT))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_LIMIT,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL_LIMIT,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL_LIMIT,price_set,takeprofit);
         //--- Set SellLimit order
         #ifdef __MQL5__
            trade.SellLimit(lot,price_set,Symbol(),sl,tp);
         #else 
            SellLimit(lot,price_set,Symbol(),magic_number,sl,tp);
         #endif 
        }
      //--- If the BUTT_SELL_STOP button is pressed: Set SellStop
      else if(button==EnumToString(BUTT_SELL_STOP))
        {
         //--- Get correct order placement relative to StopLevel
         double price_set=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_STOP,distance_pending);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL_STOP,price_set,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL_STOP,price_set,takeprofit);
         //--- Set SellStop order
         #ifdef __MQL5__
            trade.SellStop(lot,price_set,Symbol(),sl,tp);
         #else 
            SellStop(lot,price_set,Symbol(),magic_number,sl,tp);
         #endif 
        }
      //--- If the BUTT_SELL_STOP_LIMIT button is pressed: Set SellStopLimit
      else if(button==EnumToString(BUTT_SELL_STOP_LIMIT))
        {
         //--- Get the correct SellStop order price relative to StopLevel
         double price_set_stop=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_STOP,distance_pending);
         //--- Calculate SellLimit order price relative to SellStop level considering StopLevel
         double price_set_limit=CorrectPricePending(Symbol(),ORDER_TYPE_SELL_LIMIT,distance_stoplimit,price_set_stop);
         //--- Get correct StopLoss and TakeProfit prices relative to the order placement level considering StopLevel
         double sl=CorrectStopLoss(Symbol(),ORDER_TYPE_SELL_STOP,price_set_limit,stoploss);
         double tp=CorrectTakeProfit(Symbol(),ORDER_TYPE_SELL_STOP,price_set_limit,takeprofit);
         //--- Set SellStopLimit order
         #ifdef __MQL5__
            trade.OrderOpen(Symbol(),ORDER_TYPE_SELL_STOP_LIMIT,lot,price_set_limit,price_set_stop,sl,tp);
         #else 
            
         #endif 
        }
      //--- If the BUTT_CLOSE_BUY button is pressed: Close Buy with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_BUY))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            COrder* position=list.At(index);
            if(position!=NULL)
              {
               //--- Get the Buy position ticket and close the position by the ticket
               #ifdef __MQL5__
                  trade.PositionClose(position.Ticket());
               #else 
                  PositionClose(position.Ticket(),position.Volume());
               #endif 
              }
           }
        }
      //--- If the BUTT_CLOSE_BUY2 button is pressed: Close the half of the Buy with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_BUY2))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            COrder* position=list.At(index);
            if(position!=NULL)
              {
               //--- Calculate the closed volume and close the half of the Buy position by the ticket
               if(engine.IsHedge())
                 {
                  #ifdef __MQL5__
                     trade.PositionClosePartial(position.Ticket(),NormalizeLot(position.Symbol(),position.Volume()/2.0));
                  #else 
                     PositionClose(position.Ticket(),NormalizeLot(position.Symbol(),position.Volume()/2.0));
                  #endif 
                 }
               else
                 {
                  #ifdef __MQL5__
                     trade.Sell(NormalizeLot(position.Symbol(),position.Volume()/2.0));
                  #endif 
                 }
              }
           }
        }
      //--- If the BUTT_CLOSE_BUY_BY_SELL button is pressed: Close Buy with the maximum profit by the opposite Sell with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_BUY_BY_SELL))
        {
         //--- Get the list of all open positions
         CArrayObj* list_buy=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list_buy=CSelect::ByOrderProperty(list_buy,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list_buy.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_FULL);
         //--- Get the list of all open positions
         CArrayObj* list_sell=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list_sell=CSelect::ByOrderProperty(list_sell,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list_sell.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_FULL);
         if(index_buy>WRONG_VALUE && index_sell>WRONG_VALUE)
           {
            //--- Select the Buy position with the maximum profit
            COrder* position_buy=list_buy.At(index_buy);
            //--- Select the Sell position with the maximum profit
            COrder* position_sell=list_sell.At(index_sell);
            if(position_buy!=NULL && position_sell!=NULL)
              {
               //--- Close the Buy position by the opposite Sell one
               #ifdef __MQL5__
                  trade.PositionCloseBy(position_buy.Ticket(),position_sell.Ticket());
               #else 
                  PositionCloseBy(position_buy.Ticket(),position_sell.Ticket());
               #endif 
              }
           }
        }
      //--- If the BUTT_CLOSE_SELL button is pressed: Close Sell with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_SELL))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            COrder* position=list.At(index);
            if(position!=NULL)
              {
               //--- Get the Sell position ticket and close the position by the ticket
               #ifdef __MQL5__
                  trade.PositionClose(position.Ticket());
               #else 
                  PositionClose(position.Ticket());
               #endif 
              }
           }
        }
      //--- If the BUTT_CLOSE_SELL2 button is pressed: Close the half of the Sell with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_SELL2))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index=CSelect::FindOrderMax(list,ORDER_PROP_PROFIT_FULL);
         if(index>WRONG_VALUE)
           {
            COrder* position=list.At(index);
            if(position!=NULL)
              {
               //--- Calculate the closed volume and close the half of the Sell position by the ticket
               if(engine.IsHedge())
                 {
                  #ifdef __MQL5__
                     trade.PositionClosePartial(position.Ticket(),NormalizeLot(position.Symbol(),position.Volume()/2.0));
                  #else 
                     PositionClose(position.Ticket(),NormalizeLot(position.Symbol(),position.Volume()/2.0));
                  #endif 
                 }
               else
                 {
                  #ifdef __MQL5__
                     trade.Buy(NormalizeLot(position.Symbol(),position.Volume()/2.0));
                  #endif 
                 }
              }
           }
        }
      //--- If the BUTT_CLOSE_SELL_BY_BUY button is pressed: Close Sell with the maximum profit by the opposite Buy with the maximum profit
      else if(button==EnumToString(BUTT_CLOSE_SELL_BY_BUY))
        {
         //--- Get the list of all open positions
         CArrayObj* list_sell=engine.GetListMarketPosition();
         //--- Select only Sell positions from the list
         list_sell=CSelect::ByOrderProperty(list_sell,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list_sell.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Sell position with the maximum profit
         int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_FULL);
         //--- Get the list of all open positions
         CArrayObj* list_buy=engine.GetListMarketPosition();
         //--- Select only Buy positions from the list
         list_buy=CSelect::ByOrderProperty(list_buy,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
         //--- Sort the list by profit considering commission and swap
         list_buy.Sort(SORT_BY_ORDER_PROFIT_FULL);
         //--- Get the index of the Buy position with the maximum profit
         int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_FULL);
         if(index_sell>WRONG_VALUE && index_buy>WRONG_VALUE)
           {
            //--- Select the Sell position with the maximum profit
            COrder* position_sell=list_sell.At(index_sell);
            //--- Select the Buy position with the maximum profit
            COrder* position_buy=list_buy.At(index_buy);
            if(position_sell!=NULL && position_buy!=NULL)
              {
               //--- Close the Sell position by the opposite Buy one
               #ifdef __MQL5__
                  trade.PositionCloseBy(position_sell.Ticket(),position_buy.Ticket());
               #else 
                  PositionCloseBy(position_sell.Ticket(),position_buy.Ticket());
               #endif 
              }
           }
        }
      //--- If the BUTT_CLOSE_ALL is pressed: Close all positions starting with the one with the least profit
      else if(button==EnumToString(BUTT_CLOSE_ALL))
        {
         //--- Get the list of all open positions
         CArrayObj* list=engine.GetListMarketPosition();
         if(list!=NULL)
           {
            //--- Sort the list by profit considering commission and swap
            list.Sort(SORT_BY_ORDER_PROFIT_FULL);
            int total=list.Total();
            //--- In the loop from the position with the least profit
            for(int i=0;i<total;i++)
              {
               COrder* position=list.At(i);
               if(position==NULL)
                  continue;
               //--- close each position by its ticket
               #ifdef __MQL5__
                  trade.PositionClose(position.Ticket());
               #else 
                  PositionClose(position.Ticket(),position.Volume());
               #endif 
              }
           }
        }
      //--- If the BUTT_DELETE_PENDING button is pressed: Remove the first pending order
      else if(button==EnumToString(BUTT_DELETE_PENDING))
        {
         //--- Get the list of all orders
         CArrayObj* list=engine.GetListMarketPendings();
         if(list!=NULL)
           {
            //--- Sort the list by placement time
            list.Sort(SORT_BY_ORDER_TIME_OPEN);
            int total=list.Total();
            //--- In the loop from the position with the most amount of time
            for(int i=total-1;i>=0;i--)
              {
               COrder* order=list.At(i);
               if(order==NULL)
                  continue;
               //--- delete the order by its ticket
               #ifdef __MQL5__
                  trade.OrderDelete(order.Ticket());
               #else 
                  PendingOrderDelete(order.Ticket());
               #endif 
              }
           }
        }
      //--- If the BUTT_PROFIT_WITHDRAWAL button is pressed: Withdraw funds from the account
      if(button==EnumToString(BUTT_PROFIT_WITHDRAWAL))
        {
         //--- If the program is launched in the tester
         if(MQLInfoInteger(MQL_TESTER))
           {
            //--- Emulate funds withdrawal
            TesterWithdrawal(withdrawal);
           }
        }
      //--- If the BUTT_SET_STOP_LOSS button is pressed: Place StopLoss to all orders and positions where it is not present
      if(button==EnumToString(BUTT_SET_STOP_LOSS))
        {
         SetStopLoss();
        }
      //--- If the BUTT_SET_TAKE_PROFIT button is pressed: Place TakeProfit to all orders and positions where it is not present
      if(button==EnumToString(BUTT_SET_TAKE_PROFIT))
        {
         SetTakeProfit();
        }
      //--- Wait for 1/10 of a second
      Sleep(100);
      //--- "Unpress" the button (if this is not a trailing button)
      if(button!=EnumToString(BUTT_TRAILING_ALL))
         ButtonState(button_name,false);
      //--- If the BUTT_TRAILING_ALL button is pressed
      else
        {
         //--- Set the color of the active button
         ButtonState(button_name,true);
         trailing_on=true;
        }
      //--- re-draw the chart
      ChartRedraw();
     }
   //--- Return the inactive button color (if this is a trailing button)
   else if(button==EnumToString(BUTT_TRAILING_ALL))
     {
      ButtonState(button_name,false);
      trailing_on=false;
      //--- re-draw the chart
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
//| Set StopLoss to all orders and positions                         |
//+------------------------------------------------------------------+
void SetStopLoss(void)
  {
   if(stoploss_to_modify==0)
      return;
//--- Set StopLoss to all positions where it is absent
   CArrayObj* list=engine.GetListMarketPosition();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_SL,0,EQUAL);
   if(list==NULL)
      return;
   int total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* position=list.At(i);
      if(position==NULL)
         continue;
      double sl=CorrectStopLoss(position.Symbol(),position.TypeByDirection(),0,stoploss_to_modify);
      #ifdef __MQL5__
         trade.PositionModify(position.Ticket(),sl,position.TakeProfit());
      #else 
         PositionModify(position.Ticket(),sl,position.TakeProfit());
      #endif 
     }
//--- Set StopLoss to all pending orders where it is absent
   list=engine.GetListMarketPendings();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_SL,0,EQUAL);
   if(list==NULL)
      return;
   total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* order=list.At(i);
      if(order==NULL)
         continue;
      double sl=CorrectStopLoss(order.Symbol(),(ENUM_ORDER_TYPE)order.TypeOrder(),order.PriceOpen(),stoploss_to_modify);
      #ifdef __MQL5__
         trade.OrderModify(order.Ticket(),order.PriceOpen(),sl,order.TakeProfit(),trade.RequestTypeTime(),trade.RequestExpiration(),order.PriceStopLimit());
      #else 
         PendingOrderModify(order.Ticket(),order.PriceOpen(),sl,order.TakeProfit());
      #endif 
     }
  }
//+------------------------------------------------------------------+
//| Set TakeProfit to all orders and positions                       |
//+------------------------------------------------------------------+
void SetTakeProfit(void)
  {
   if(takeprofit_to_modify==0)
      return;
//--- Set TakeProfit to all positions where it is absent
   CArrayObj* list=engine.GetListMarketPosition();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_TP,0,EQUAL);
   if(list==NULL)
      return;
   int total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* position=list.At(i);
      if(position==NULL)
         continue;
      double tp=CorrectTakeProfit(position.Symbol(),position.TypeByDirection(),0,takeprofit_to_modify);
      #ifdef __MQL5__
         trade.PositionModify(position.Ticket(),position.StopLoss(),tp);
      #else 
         PositionModify(position.Ticket(),position.StopLoss(),tp);
      #endif 
     }
//--- Set TakeProfit to all pending orders where it is absent
   list=engine.GetListMarketPendings();
   list=CSelect::ByOrderProperty(list,ORDER_PROP_TP,0,EQUAL);
   if(list==NULL)
      return;
   total=list.Total();
   for(int i=total-1;i>=0;i--)
     {
      COrder* order=list.At(i);
      if(order==NULL)
         continue;
      double tp=CorrectTakeProfit(order.Symbol(),(ENUM_ORDER_TYPE)order.TypeOrder(),order.PriceOpen(),takeprofit_to_modify);
      #ifdef __MQL5__
         trade.OrderModify(order.Ticket(),order.PriceOpen(),order.StopLoss(),tp,trade.RequestTypeTime(),trade.RequestExpiration(),order.PriceStopLimit());
      #else 
         PendingOrderModify(order.Ticket(),order.PriceOpen(),order.StopLoss(),tp);
      #endif 
     }
  }
//+------------------------------------------------------------------+
//| Trailing stop of a position with the maximum profit              |
//+------------------------------------------------------------------+
void TrailingPositions(void)
  {
   MqlTick tick;
   if(!SymbolInfoTick(Symbol(),tick))
      return;
   double stop_level=StopLevel(Symbol(),2)*Point();
   //--- Get the list of all open positions
   CArrayObj* list=engine.GetListMarketPosition();
   //--- Select only Buy positions from the list
   CArrayObj* list_buy=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_BUY,EQUAL);
   //--- Sort the list by profit considering commission and swap
   list_buy.Sort(SORT_BY_ORDER_PROFIT_FULL);
   //--- Get the index of the Buy position with the maximum profit
   int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_FULL);
   if(index_buy>WRONG_VALUE)
     {
      COrder* buy=list_buy.At(index_buy);
      if(buy!=NULL)
        {
         //--- Calculate the new StopLoss
         double sl=NormalizeDouble(tick.bid-trailing_stop,Digits());
         //--- If the price and the StopLevel based on it are higher than the new StopLoss (the distance by StopLevel is maintained)
         if(tick.bid-stop_level>sl) 
           {
            //--- If the new StopLoss level exceeds the trailing step based on the current StopLoss
            if(buy.StopLoss()+trailing_step<sl)
              {
               //--- If we trail at any profit or position profit in points exceeds the trailing start, modify StopLoss
               if(trailing_start==0 || buy.ProfitInPoints()>(int)trailing_start)
                 {
                  #ifdef __MQL5__
                     trade.PositionModify(buy.Ticket(),sl,buy.TakeProfit());
                  #else 
                     PositionModify(buy.Ticket(),sl,buy.TakeProfit());
                  #endif 
                 }
              }
           }
        }
     }
   //--- Select only Sell positions from the list
   CArrayObj* list_sell=CSelect::ByOrderProperty(list,ORDER_PROP_TYPE,POSITION_TYPE_SELL,EQUAL);
   //--- Sort the list by profit considering commission and swap
   list_sell.Sort(SORT_BY_ORDER_PROFIT_FULL);
   //--- Get the index of the Sell position with the maximum profit
   int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_FULL);
   if(index_sell>WRONG_VALUE)
     {
      COrder* sell=list_sell.At(index_sell);
      if(sell!=NULL)
        {
         //--- Calculate the new StopLoss
         double sl=NormalizeDouble(tick.ask+trailing_stop,Digits());
         //--- If the price and StopLevel based on it are below the new StopLoss (the distance by StopLevel is maintained)
         if(tick.ask+stop_level<sl) 
           {
            //--- If the new StopLoss level is below the trailing step based on the current StopLoss or a position has no StopLoss
            if(sell.StopLoss()-trailing_step>sl || sell.StopLoss()==0)
              {
               //--- If we trail at any profit or position profit in points exceeds the trailing start, modify StopLoss
               if(trailing_start==0 || sell.ProfitInPoints()>(int)trailing_start)
                 {
                  #ifdef __MQL5__
                     trade.PositionModify(sell.Ticket(),sl,sell.TakeProfit());
                  #else 
                     PositionModify(sell.Ticket(),sl,sell.TakeProfit());
                  #endif 
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Trailing the farthest pending orders                             |
//+------------------------------------------------------------------+
void TrailingOrders(void)
  {
   MqlTick tick;
   if(!SymbolInfoTick(Symbol(),tick))
      return;
   double stop_level=StopLevel(Symbol(),2)*Point();
//--- Get the list of all placed orders
   CArrayObj* list=engine.GetListMarketPendings();
//--- Select only Buy orders from the list
   CArrayObj* list_buy=CSelect::ByOrderProperty(list,ORDER_PROP_DIRECTION,ORDER_TYPE_BUY,EQUAL);
   //--- Sort the list by distance from the price in points (by profit in points)
   list_buy.Sort(SORT_BY_ORDER_PROFIT_PT);
   //--- Get the index of the Buy order with the greatest distance
   int index_buy=CSelect::FindOrderMax(list_buy,ORDER_PROP_PROFIT_PT);
   if(index_buy>WRONG_VALUE)
     {
      COrder* buy=list_buy.At(index_buy);
      if(buy!=NULL)
        {
         //--- If the order is below the price (BuyLimit) and it should be "elevated" following the price
         if(buy.TypeOrder()==ORDER_TYPE_BUY_LIMIT)
           {
            //--- Calculate the new order price and stop levels based on it
            price=NormalizeDouble(tick.ask-trailing_stop,Digits());
            double sl=(buy.StopLoss()>0 ? NormalizeDouble(price-(buy.PriceOpen()-buy.StopLoss()),Digits()) : 0);
            double tp=(buy.TakeProfit()>0 ? NormalizeDouble(price+(buy.TakeProfit()-buy.PriceOpen()),Digits()) : 0);
            //--- If the calculated price is below the StopLevel distance based on Ask order price (the distance by StopLevel is maintained)
            if(price<tick.ask-stop_level) 
              {
               //--- If the calculated price exceeds the trailing step based on the order placement price, modify the order price
               if(price>buy.PriceOpen()+trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(buy.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),buy.PriceStopLimit());
                  #else 
                     PendingOrderModify(buy.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
         //--- If the order exceeds the price (BuyStop and BuyStopLimit), and it should be "decreased" following the price
         else
           {
            //--- Calculate the new order price and stop levels based on it
            price=NormalizeDouble(tick.ask+trailing_stop,Digits());
            double sl=(buy.StopLoss()>0 ? NormalizeDouble(price-(buy.PriceOpen()-buy.StopLoss()),Digits()) : 0);
            double tp=(buy.TakeProfit()>0 ? NormalizeDouble(price+(buy.TakeProfit()-buy.PriceOpen()),Digits()) : 0);
            //--- If the calculated price exceeds the StopLevel based on Ask order price (the distance by StopLevel is maintained)
            if(price>tick.ask+stop_level) 
              {
               //--- If the calculated price is lower than the trailing step based on order price, modify the order price
               if(price<buy.PriceOpen()-trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(buy.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),(buy.PriceStopLimit()>0 ? price-distance_stoplimit*Point() : 0));
                  #else 
                     PendingOrderModify(buy.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
        }
     }
//--- Select only Sell order from the list
   CArrayObj* list_sell=CSelect::ByOrderProperty(list,ORDER_PROP_DIRECTION,ORDER_TYPE_SELL,EQUAL);
   //--- Sort the list by distance from the price in points (by profit in points)
   list_sell.Sort(SORT_BY_ORDER_PROFIT_PT);
   //--- Get the index of the Sell order having the greatest distance
   int index_sell=CSelect::FindOrderMax(list_sell,ORDER_PROP_PROFIT_PT);
   if(index_sell>WRONG_VALUE)
     {
      COrder* sell=list_sell.At(index_sell);
      if(sell!=NULL)
        {
         //--- If the order exceeds the price (SellLimit), and it needs to be "decreased" following the price
         if(sell.TypeOrder()==ORDER_TYPE_SELL_LIMIT)
           {
            //--- Calculate the new order price and stop levels based on it
            price=NormalizeDouble(tick.bid+trailing_stop,Digits());
            double sl=(sell.StopLoss()>0 ? NormalizeDouble(price+(sell.StopLoss()-sell.PriceOpen()),Digits()) : 0);
            double tp=(sell.TakeProfit()>0 ? NormalizeDouble(price-(sell.PriceOpen()-sell.TakeProfit()),Digits()) : 0);
            //--- If the calculated price exceeds the StopLevel distance based on the Bid order price (the distance by StopLevel is maintained)
            if(price>tick.bid+stop_level) 
              {
               //--- If the calculated price is lower than the trailing step based on order price, modify the order price
               if(price<sell.PriceOpen()-trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(sell.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),sell.PriceStopLimit());
                  #else 
                     PendingOrderModify(sell.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
         //--- If the order is below the price (SellStop and SellStopLimit), and it should be "elevated" following the price
         else
           {
            //--- Calculate the new order price and stop levels based on it
            price=NormalizeDouble(tick.bid-trailing_stop,Digits());
            double sl=(sell.StopLoss()>0 ? NormalizeDouble(price+(sell.StopLoss()-sell.PriceOpen()),Digits()) : 0);
            double tp=(sell.TakeProfit()>0 ? NormalizeDouble(price-(sell.PriceOpen()-sell.TakeProfit()),Digits()) : 0);
            //--- If the calculated price is below the StopLevel distance based on the Bid order price (the distance by StopLevel is maintained)
            if(price<tick.bid-stop_level) 
              {
               //--- If the calculated price exceeds the trailing step based on the order placement price, modify the order price
               if(price>sell.PriceOpen()+trailing_step)
                 {
                  #ifdef __MQL5__
                     trade.OrderModify(sell.Ticket(),price,sl,tp,trade.RequestTypeTime(),trade.RequestExpiration(),(sell.PriceStopLimit()>0 ? price+distance_stoplimit*Point() : 0));
                  #else 
                     PendingOrderModify(sell.Ticket(),price,sl,tp);
                  #endif 
                 }
              }
           }
        }
     }
  }
  
  
  
  
  

//license control
string licenseState(){
if(licenseControl()==true){
 return "Valid";
}else
return "Invalid";
}

bool licenseControl(){

if (now  <= allowed_until ||LicenceKey=="Noel307") {
return true;
     
     }else{  Comment("THis EA is now expired.\n\nBot is not Trading \nPlease contact support to get renew your license"); 
  }  
  
  
return false;
}


void OnTimer(){


  starter();
  bot.GetMe();
  bot.GetKeyboard();
  
 bot.ProcessMessages();
 bot.GetUpdates(); 
  
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void fCloseAllOrders()
  {
   double   priceClose = 0.0;
   int tOrders = OrdersTotal();
   for(int i=tOrders-1; i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber() == inMagicNumber && (OrderType() == OP_BUY || OrderType() == OP_SELL))
           {
            priceClose  = (OrderType()==OP_BUY)?MarketInfo(OrderSymbol(), MODE_BID):MarketInfo(OrderSymbol(), MODE_ASK);
            if(!OrderClose(OrderTicket(), OrderLots(), priceClose, MaxSlippage, clrGold))
              {
               Print("WARNING: Close Failed");
              }
           }
        }
     }
  }
  
  



bool inTimeInterval(datetime t, int From_Hour, int From_Min, int To_Hour, int To_Min)
  {
   string TOD = TimeToString(t, TIME_MINUTES);
   string TOD_From = StringFormat("%02d", From_Hour)+":"+StringFormat("%02d", From_Min);
   string TOD_To = StringFormat("%02d", To_Hour)+":"+StringFormat("%02d", To_Min);
   return((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, TOD_To) <= 0)
     || (StringCompare(TOD_From, TOD_To) > 0
       && ((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, "23:59") <= 0)
         || (StringCompare(TOD, "00:00") >= 0 && StringCompare(TOD, TOD_To) <= 0))));
  }
  
void CloseByDuration(int sec) //close trades opened longer than sec seconds
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() > 1 || OrderOpenTime() + sec > TimeCurrent()) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      price = Bid;
      if(OrderType() == OP_SELL)
         price = Ask;
      success = OrderClose(OrderTicket(), NormalizeDouble(OrderLots(), LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, clrWhite);
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderClose failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   if(success) myAlert("order", "Orders closed by duration: "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

void DeleteByDuration(int sec) //delete pending order after time since placing the order
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() <= 1 || OrderOpenTime() + sec > TimeCurrent()) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   if(success) myAlert("order", "Orders deleted by duration: "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

void DeleteByDistance(double distance) //delete pending order if price went too far from it
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() <= 1) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      price = (OrderType() % 2 == 1) ? Ask : Bid;
      if(MathAbs(OrderOpenPrice() - price) <= distance) continue;
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   if(success) myAlert("order", "Orders deleted by distance: "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

double MM_Size(double SL) //Risk % per trade, SL = relative Stop Loss to calculate risk
  {
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double lots = MM_Percent * 1.0 / 100 * AccountBalance() / (SL / ticksize * tickvalue);
   if(lots > MaxLot) lots = MaxLot;
   if(lots < MinLot) lots = MinLot;
   return(lots);
  }

double MM_Size_BO() //Risk % per trade for Binary Options
  {  
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   return(MM_Percent * 1.0 / 100 * AccountBalance());
  }

bool TradeDayOfWeek()
  {
   int day = DayOfWeek();
   return((TradeMonday && day == 1)
   || (TradeTuesday && day == 2)
   || (TradeWednesday && day == 3)
   || (TradeThursday && day == 4)
   || (TradeFriday && day == 5)
   || (TradeSaturday && day == 6)
   || (TradeSunday && day == 0));
  }

void CloseTradesAtPL(double PL) //close all trades if total P/L >= profit (positive) or total P/L <= loss (negative)
  {
   double totalPL = TotalOpenProfit(0);
   if((PL > 0 && totalPL >= PL) || (PL < 0 && totalPL <= PL))
     {
      myOrderClose(OP_BUY, 100, "");
      myOrderClose(OP_SELL, 100, "");
     }
  }

bool Cross(int i, bool condition) //returns true if "condition" is true and was false in the previous call
  {
   bool ret = condition && !crossed[i];
   crossed[i] = condition;
   return(ret);
  }

void myAlert(string type, string message)
  {
   int handle;
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
      Print(type+" |  TradeAdviser@ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Audible_Alerts) Alert(type+" |  TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Send_Email) SendMail("TradePredictor", type+" |  TradeAdviser@ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      handle = FileOpen("TradePredictor.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
      if(handle != INVALID_HANDLE)
        {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, type+" | TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
         FileClose(handle);
        }
      if(Push_Notifications) SendNotification(type+" | TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "modify")
     {
      Print(type+" | TradePredictor @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Audible_Alerts) Alert(type+" | TradePredictor @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Send_Email) SendMail("TradePredictor", type+" |  TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      handle = FileOpen("TradePredictor.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
      if(handle != INVALID_HANDLE)
        {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, type+" |  TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
         FileClose(handle);
        }
      if(Push_Notifications) SendNotification(type+" |  TradeAdviser @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
  }

int TradesCount(int type) //returns # of open trades for order type, current symbol and magic number
  {
   int result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      result++;
     }
   return(result);
  }

datetime LastOpenTradeTime()
  {
   datetime result = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderType() > 1) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         result = OrderOpenTime();
         break;
        }
     } 
   return(result);
  }

bool SelectLastHistoryTrade()
  {
   int lastOrder = -1;
   int total = OrdersHistoryTotal();
   for(int i = total-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         lastOrder = i;
         break;
        }
     } 
   return(lastOrder >= 0);
  }

double TotalOpenProfit(int direction)
  {
   double result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)   
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if((direction < 0 && OrderType() == OP_BUY) || (direction > 0 && OrderType() == OP_SELL)) continue;
      result += OrderProfit();
     }
   return(result);
  }

datetime LastOpenTime()
  {
   datetime opentime1 = 0, opentime2 = 0;
   if(SelectLastHistoryTrade())
      opentime1 = OrderOpenTime();
   opentime2 = LastOpenTradeTime();
   if (opentime1 > opentime2)
      return opentime1;
   else
      return opentime2;
  }

int myOrderSend(int type, double prices, double volume, string ordername) //send order, return ticket ("price" is irrelevant for market orders)
  {
  prices=price;
   if(!IsTradeAllowed()) return(-1);
   int ticket = -1;
   int retries = 0;
   int err = 0;
   int long_trades = TradesCount(OP_BUY);
   int short_trades = TradesCount(OP_SELL);
   int long_pending = TradesCount(OP_BUYLIMIT) + TradesCount(OP_BUYSTOP);
   int short_pending = TradesCount(OP_SELLLIMIT) + TradesCount(OP_SELLSTOP);
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   //test Hedging
   if(!Hedging && ((type % 2 == 0 && short_trades + short_pending > 0) || (type % 2 == 1 && long_trades + long_pending > 0)))
     {
      myAlert("print", "Order"+ordername_+" not sent, hedging not allowed");
      return(-1);
     }
   //test maximum trades
   if((type % 2 == 0 && long_trades >= MaxLongTrades)
   || (type % 2 == 1 && short_trades >= MaxShortTrades)
   || (long_trades + short_trades >= MaxOpenTrades)
   || (type > 1 && type % 2 == 0 && long_pending >= MaxLongPendingOrders)
   || (type > 1 && type % 2 == 1 && short_pending >= MaxShortPendingOrders)
   || (type > 1 && long_pending + short_pending >= MaxPendingOrders)
   )
     {
      myAlert("print", "Order"+ordername_+" not sent, maximum reached");
      return(-1);
     }
   //prepare to send order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   if(type == OP_BUY)
      price = Ask;
   else if(type == OP_SELL)
      price = Bid;
   else if(price < 0) //invalid price for pending order
     {
      myAlert("order", "Order"+ordername_+" not sent, invalid price for pending order");
	  return(-1);
     }
   int clr = (type % 2 == 1) ? clrRed : clrBlue;
   if(MaxSpread > 0 && Ask - Bid > MaxSpread * myPoint)
     {
      myAlert("order", "Order"+ordername_+" not sent, maximum spread "+DoubleToStr(MaxSpread * myPoint, Digits())+" exceeded");
      return(-1);
     }
   //adjust price for pending order if it is too close to the market price
   double MinDistance = PriceTooClose * myPoint;
   if(type == OP_BUYLIMIT && Ask - price < MinDistance)
      price = Ask - MinDistance;
   else if(type == OP_BUYSTOP && price - Ask < MinDistance)
      price = Ask + MinDistance;
   else if(type == OP_SELLLIMIT && price - Bid < MinDistance)
      price = Bid + MinDistance;
   else if(type == OP_SELLSTOP && Bid - price < MinDistance)
      price = Bid - MinDistance;
   while(ticket < 0 && retries < OrderRetry+1)
     {
      ticket = OrderSend(Symbol(), type, NormalizeDouble(volume, LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, 0, 0, ordername, MagicNumber, 0, clr);
      if(ticket < 0)
        {
         err = GetLastError();
         myAlert("print", "OrderSend"+ordername_+" error #"+IntegerToString(err)+" "+ErrorDescription(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(ticket < 0)
     {
      myAlert("error", "OrderSend"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   myAlert("order", "Order sent"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
   return(ticket);
  }

void myOrderDelete(int type, string ordername) //delete pending orders of "type"
  {
   if(!IsTradeAllowed()) return;
   bool success = false;
   int err = 0;
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      success = OrderDelete(OrderTicket());
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderDelete"+ordername_+" failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   if(success) myAlert("order", "Orders deleted"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
  }

int myOrderModifyRel(int ticket, double SL, double TP) //modify SL and TP (relative to open price), zero targets do not modify
  {
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
   int retries = 0;
   int err = 0;
   SL = NormalizeDouble(SL, Digits());
   TP = NormalizeDouble(TP, Digits());
   if(SL < 0) SL = 0;
   if(TP < 0) TP = 0;
   //prepare to select order
   while(IsTradeContextBusy()) Sleep(100);
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     {
      err = GetLastError();
      myAlert("error", "OrderSelect failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   //prepare to modify order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   //convert relative to absolute
   if(OrderType() % 2 == 0) //buy
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = OrderOpenPrice() - SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = OrderOpenPrice() + TP;
     }
   else //sell
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = OrderOpenPrice() + SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = OrderOpenPrice() - TP;
     }
   //adjust targets for market order if too close to the market price
   double MinDistance = PriceTooClose * myPoint;
   if(OrderType() == OP_BUY)
     {
      if(NormalizeDouble(SL, Digits()) != 0 && Ask - SL < MinDistance)
         SL = Ask - MinDistance;
      if(NormalizeDouble(TP, Digits()) != 0 && TP - Ask < MinDistance)
         TP = Ask + MinDistance;
     }
   else if(OrderType() == OP_SELL)
     {
      if(NormalizeDouble(SL, Digits()) != 0 && SL - Bid < MinDistance)
         SL = Bid + MinDistance;
      if(NormalizeDouble(TP, Digits()) != 0 && Bid - TP < MinDistance)
         TP = Bid - MinDistance;
     }
   if(CompareDoubles(SL, 0)) SL = OrderStopLoss(); //not to modify
   if(CompareDoubles(TP, 0)) TP = OrderTakeProfit(); //not to modify
   if(CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit())) return(0); //nothing to do
   while(!success && retries < OrderRetry+1)
     {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), Digits()), NormalizeDouble(SL, Digits()), NormalizeDouble(TP, Digits()), OrderExpiration(), CLR_NONE);
      if(!success)
        {
         err = GetLastError();
         myAlert("print", "OrderModify error #"+IntegerToString(err)+" "+ErrorDescription(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(!success)
     {
      myAlert("error", "OrderModify failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   string alertstr = "Order modified: ticket="+IntegerToString(ticket);
   if(!CompareDoubles(SL, 0)) alertstr = alertstr+" SL="+DoubleToString(SL);
   if(!CompareDoubles(TP, 0)) alertstr = alertstr+" TP="+DoubleToString(TP);
   myAlert("modify", alertstr);
   return(0);
  }

void myOrderClose(int type, double volumepercent, string ordername) //close open orders for current symbol, magic number and "type" (OP_BUY or OP_SELL)
  {
   if(!IsTradeAllowed()) return;
   if (type > 1)
     {
      myAlert("error", "Invalid type in myOrderClose");
      return;
     }
   bool success = false;
   int err = 0;
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   int total = OrdersTotal();
   int orderList[][2];
   int orderCount = 0;
   int i;
   for(i = 0; i < total; i++)
     {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      if(OrderOpenTime() + MinTradeDurationSeconds * 1 > TimeCurrent()) continue; //minimum trade duration, do not close
      orderCount++;
      ArrayResize(orderList, orderCount);
      orderList[orderCount - 1][0] = (int)OrderOpenTime();
      orderList[orderCount - 1][1] = OrderTicket();
     }
   if(orderCount > 0)
      ArraySort(orderList, WHOLE_ARRAY, 0, MODE_ASCEND);
   for(i = 0; i < orderCount; i++)
     {
      if(!OrderSelect(orderList[i][1], SELECT_BY_TICKET, MODE_TRADES)) continue;
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      price = (type == OP_SELL) ? Ask : Bid;
      double volume = NormalizeDouble(OrderLots()*volumepercent * 1.0 / 100, LotDigits);
      if (NormalizeDouble(volume, LotDigits) == 0) continue;
      success = OrderClose(OrderTicket(), volume, NormalizeDouble(price, Digits()), MaxSlippage, clrWhite);
      if(!success)
        {
         err = GetLastError();
         myAlert("error", "OrderClose"+ordername_+" failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
          bot.SendMessage(ChannelName,"error"+ "OrderClose"+ordername_+" failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
        }
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   if(success) myAlert("order", "Orders closed"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
    bot.SendMessage(ChannelName,"order"+"Orders closed"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
    
  }


void mytrade(){ int ticket = -1;
   
   double TradeSize;
   double SL;
   double TP;
   
   CloseByDuration(MaxTradeDurationBars * PeriodSeconds());
   DeleteByDuration(PendingOrderExpirationHours * 3600);
   DeleteByDistance(DeleteOrderAtDistance * myPoint);
   CloseTradesAtPL(CloseAtPL);
   
    
   if(licenseControl()==true){
   //Delete Pending Buy Orders, instant signal is tested first
   RefreshRates();
   if(Cross(1, iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 0, 0) < iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 1, 0)) //TrendsFollowers crosses below TrendsFollowers
   && Bid < iCustom(NULL, PERIOD_CURRENT, "CMA[1]", 14, PRICE_CLOSE, MODE_SMA, 0, 0) //Price < CMA[1]
   )
     {   
      if(IsTradeAllowed())
         myOrderDelete(OP_BUYSTOP, "");
      else //not autotrading => only send alert
         myAlert("order", "");
     }
   
   //Delete Pending Sell Orders, instant signal is tested first
   RefreshRates();
   if(Cross(0, iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 0, 0) > iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 1, 0)) //TrendsFollowers crosses above TrendsFollowers
   && Bid > iCustom(NULL, PERIOD_CURRENT, "CMA[1]", 14, PRICE_CLOSE, MODE_SMA, 0, 0) //Price > CMA[1]
   )
     {   
      if(IsTradeAllowed())
         myOrderDelete(OP_SELLSTOP, "");
      else //not autotrading => only send alert
         myAlert("order", "");
     }
   
   //Open Buy Order
   if(iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 0, 0) > iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 1, 0) //TrendsFollowers > TrendsFollowers
   )
     {
     
         RefreshRates();
      price = Ask;
        
      SL = SL_Points * myPoint + iSAR(NULL, PERIOD_CURRENT, Step, Maximum, 0); //Stop Loss = value in points (relative to price) - Parabolic SAR
      if(SL > MaxSL) SL = MaxSL;
      if(SL < MinSL) SL = MinSL;
      TradeSize = MM_Size(SL);
    
      TP = TP_Points * myPoint; //Take Profit = value in points (relative to price)
      if(TP > MaxTP) TP = MaxTP;
      if(TP < MinTP) TP = MinTP;
      if(TimeCurrent() - LastOpenTime() < NextOpenTradeAfterHours * 3600) return; //next open trade after time after previous trade's open
      if(!inTimeInterval(TimeCurrent(), TOD_From_Hour, TOD_From_Min, TOD_To_Hour, TOD_To_Min)) return; //open trades only at specific times of the day
      if(!TradeDayOfWeek()) return; //open trades only on specific days of the week   
      if(IsTradeAllowed())
        { 
  ticket = myOrderSend(OP_BUYSTOP, price, TradeSize, "");
    
      dropPencent=(-price+OrderOpenPrice())*10;
        
        
    
         if(OrderProfit()<=5&&dropPencent<20){
         
          price = Bid;
          
          SL = SL_Points * myPoint + iSAR(NULL, PERIOD_CURRENT, Step, Maximum, 0); //Stop Loss = value in points (relative to price) + Parabolic SAR
      if(SL > MaxSL) SL = MaxSL;
      if(SL < MinSL) SL = MinSL;
      TradeSize = MM_Size(SL);
      TP = TP_Points * myPoint; //Take Profit = value in points (relative to price)
      if(TP > MaxTP) TP = MaxTP;
      if(TP < MinTP) TP = MinTP;
    
    if(OrdersTotal()>=1&& AccountFreeMargin()<AccountBalance()-200){
      
      Comment("\nNot Trading just Control risk\n");
    
           }else{ ticket = myOrderSend(OP_SELLSTOP, price, TradeSize, "");
     }
         
         }
        
         if(ticket <= 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "");
      myOrderModifyRel(ticket, SL, 0);
      myOrderModifyRel(ticket, 0, TP);
     }
   
   //Open Sell Order
   if(iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 0, 0) <= iCustom(NULL, PERIOD_CURRENT, "TrendsFollowers", 805814430, "", "", 1, 0) //TrendsFollowers < TrendsFollowers
   )
     {
      RefreshRates();
     
      price = Bid;
      SL = SL_Points * myPoint + iSAR(NULL, PERIOD_CURRENT, Step, Maximum, 0); //Stop Loss = value in points (relative to price) + Parabolic SAR
      if(SL > MaxSL) SL = MaxSL;
      if(SL < MinSL) SL = MinSL;
       TradeSize = MM_Size(SL);
   
       
     
      TP = TP_Points * myPoint; //Take Profit = value in points (relative to price)
      if(TP > MaxTP) TP = MaxTP;
      if(TP < MinTP) TP = MinTP;
      if(TimeCurrent() - LastOpenTime() < NextOpenTradeAfterHours * 3600) return; //next open trade after time after previous trade's open
      if(!inTimeInterval(TimeCurrent(), TOD_From_Hour, TOD_From_Min, TOD_To_Hour, TOD_To_Min)) return; //open trades only at specific times of the day
      if(!TradeDayOfWeek()) return; //open trades only on specific days of the week   
      if(IsTradeAllowed())
        {
        
         if(OrdersTotal()>=4&& AccountFreeMargin()>AccountBalance()){
      
      Comment("\nNot Trading just Control risk\n");
    
           }else{ ticket = myOrderSend(OP_SELLSTOP, price, TradeSize, "");
     }
        
        
        
        Comment("\n\n DropPercentage %:"+dropPencent);
         
   
         
          price = Ask;
          
          SL = SL_Points * myPoint + iSAR(NULL, PERIOD_CURRENT, Step, Maximum, 0); //Stop Loss = value in points (relative to price) + Parabolic SAR
      if(SL > MaxSL) SL = MaxSL;
      if(SL < MinSL) SL = MinSL;
      TradeSize = MM_Size(SL);
         
       if(TradeSize==OrderLots()){++TradeSize;
      
      }
   
      TP = TP_Points * myPoint; //Take Profit = value in points (relative to price)
      if(TP > MaxTP) TP = MaxTP;
      if(TP < MinTP) TP = MinTP;
      
      if(OrdersTotal()>=0&& AccountFreeMargin()<AccountBalance()){
      
      Comment("\nNot Trading just Control risk\n");
    
           }else{ ticket = myOrderSend(OP_BUYSTOP, price, TradeSize, "");
         
     }
         
         
         if(ticket <= 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "");
      myOrderModifyRel(ticket, SL, 0);
      myOrderModifyRel(ticket, 0, TP);
     }
     }else{ Comment("No trading!  Invalid license");
           }
     }
  
  
  
  
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void starter() {

   double dRPTAmtRisking;           // Used to calculate the overall risk
   double dRPTAmtRewarding;         // Used to calculate the overall target      
   int kRPT;                        // Used to loop all open orders to get the overall risk
   string sRPTObjectName;           // To name the Objects
   
   //--- Delete these objects from chart 
   ObjectsDeleteAll(0);
   
   //--- Always reset these parameters at the beginning
  	dRPTAmtRisking=0.0;
  	dRPTAmtRewarding=0.0;
   sRPTObjectName="";
   
   //--- Loop all open orders in order to calculate the overall risk
	for (kRPT=0 ; kRPT<OrdersTotal() ; kRPT++) {
	   
      //--- Select the open order	   
		if (OrderSelect(kRPT,SELECT_BY_POS,MODE_TRADES)) {

         //--- Get the risks of Buys and Sells orders
   	   if (OrderGetInteger(ORDER_TYPE)==0 || OrderGetInteger(ORDER_TYPE)==1) {

            if (OrderSymbol()==Symbol()) {

               //--- Create SL object if it is not null               
               if(OrderStopLoss()!=0) {
               
                  //--- Name of the object SL Text
                  sRPTObjectName = ""; // This here is essential
                  sRPTObjectName = StringConcatenate(OrderTicket(),OrderStopLoss());
   
                  //--- Creation of the object SL Text
                  vSetText(0,sRPTObjectName,0,TimeCurrent(),OrderStopLoss(),8,cRPTFontClr,"SL: "+DoubleToString(dValuePips(OrderSymbol(), OrderOpenPrice(), OrderStopLoss(), OrderLots())/AccountInfoDouble(ACCOUNT_BALANCE)*100,2)+"%");// = "+DoubleToString(dValuePips(OrderSymbol(), OrderOpenPrice(), OrderStopLoss(), OrderLots()),2)+" "+AccountInfoString(ACCOUNT_CURRENCY));
               
               }

               //--- Create TP object if it is not null               
               if (OrderTakeProfit()!=0) {
               
                  //--- Name of the object TP Text
                  sRPTObjectName = ""; // This here is essential
                  sRPTObjectName = StringConcatenate(OrderTicket(),OrderTakeProfit());
   
                  //--- Creation of the object TP Text
                  vSetText(0,sRPTObjectName,0,TimeCurrent(),OrderTakeProfit(),8,cRPTFontClr,"TP: "+DoubleToString(dValuePips(OrderSymbol(), OrderOpenPrice(), OrderTakeProfit(), OrderLots())/AccountInfoDouble(ACCOUNT_BALANCE)*100,2)+"%");// = "+DoubleToString(dValuePips(OrderSymbol(), OrderOpenPrice(), OrderTakeProfit(), OrderLots()),2)+" "+AccountInfoString(ACCOUNT_CURRENCY));
               
               }

               //--- Add dRPTAmtRisking if SL is not null
               if(OrderStopLoss()!=0) {
               
      	         //--- Add the risk of this open order to the overall risk
         			dRPTAmtRisking =    dRPTAmtRisking +    dValuePips(OrderSymbol(), OrderOpenPrice(), OrderStopLoss(), OrderLots());
               }
               
               //--- Add dRPTAmtRewarding if TP is not null
               if (OrderTakeProfit()!=0) {
                                       			
      	         //--- Add the target of this open order to the overall target
         			dRPTAmtRewarding =  dRPTAmtRewarding +  dValuePips(OrderSymbol(), OrderOpenPrice(), OrderTakeProfit(), OrderLots());
         			
      			}      			
            }
   		}
   	}
   }

   //--- Hide the OneClick panel
   ChartSetInteger(0,CHART_SHOW_ONE_CLICK,false);

   //--- Create the RPTBalance, RPTTotalPercentRisked & RPTTotalPercentTarget objects
   vSetLabel(0, "RPTBalance",0,25,20,8,cRPTFontClr,"Balance: "+ DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+" "+AccountInfoString(ACCOUNT_CURRENCY));         
   vSetLabel(0, "RPTAllSymbolPercentRisked",0,45,20,8,cRPTFontClr,"All "+Symbol()+"'s % Risked : "+ DoubleToString(dRPTAmtRisking/AccountInfoDouble(ACCOUNT_BALANCE)*100,2)+"%");
   vSetLabel(0, "RPTAllSymbolPercentTarget",0,65,20,8,cRPTFontClr,"All "+Symbol()+"'s % Target : "+ DoubleToString(dRPTAmtRewarding/AccountInfoDouble(ACCOUNT_BALANCE)*100,2)+"%");

}
  
  
  
  
  
  
  

//+------------------------------------------------------------------+

  
  
  //############################################################################################################   
     
     
     
     
     
  

     
  