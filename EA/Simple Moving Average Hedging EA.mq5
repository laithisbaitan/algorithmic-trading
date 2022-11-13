//+------------------------------------------------------------------+
//|                             Simple Moving Average Hedging EA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+
#include "currDirectoryTradingFunctions.mqh"
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property description "Moving Avrage Expert Advisor provided as template as part of the Algorithmatic Trading Course"
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//| EA Enumerations                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Input & Global Variables                                         |
//+------------------------------------------------------------------+
sinput group                           "EA GENERAL SETTINGS"
input ulong                            MagicNumber             = 101;

sinput group                           "MOVING AVERAGE SETTINGS"
input int                              MAPeriod                = 30;
input ENUM_MA_METHOD                   MAMethod                = MODE_SMA;
input int                              MAShift                 = 0;
input ENUM_APPLIED_PRICE               MAPrice                 = PRICE_CLOSE;

sinput group                           "MONEY MANAGEMENT"
input double                           FixedVolume             = 0.01;

sinput group                           "POSITION MANAGEMENT"
input ushort                           SLFixedPoints           = 0;
input ushort                           SLFixedPointsMA         = 200;
input ushort                           TPFixedPoints           = 0;
input ushort                           TSLFixedPoints          = 0;
input ushort                           BEFixedPoints           = 0;

datetime glTimeBarOpen;
int MAHandle;
//+------------------------------------------------------------------+
//| Event Handlers                                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      glTimeBarOpen = D'1971.01.01 00:00';
      
      MAHandle = MA_Int(MAPeriod,MAShift,MAMethod,MAPrice);
      if(MAHandle == -1){
         return(INIT_FAILED);
      }
      
      Print("Expert initialized");
      return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
      Print("Expert removed");
  }

void OnTick()
  {

   //---------------//
   // NEW BAR CONTROL 
   //---------------//
   bool newBar = false;
  
   //Check for new bar
   if(glTimeBarOpen != iTime(_Symbol, PERIOD_CURRENT,0)){
      newBar = true;
     glTimeBarOpen = iTime(_Symbol, PERIOD_CURRENT,0);
   }
  
   if(newBar == true){
      
      //---------------//
      // PRICE & INDICATORS
      //---------------//
      
      //price
      double close1 = Close(1);
      double close2 = Close(2);

      //Normalization of close price to tick size
      double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      close1 = round(close1/tickSize) * tickSize;
      close2 = round(close2/tickSize) * tickSize;

      //Moving Average
      double ma1 = ma(MAHandle,1);
      double ma2 = ma(MAHandle,2);
      
      //---------------//
      // TRADE EXIT
      //---------------//
      
      //Exit Signals & Clobe Trades Execution
      string exitSignal = MA_ExitSignal(close1,close2,ma1,ma2);
      
      if(exitSignal == "EXIT_LONG" || exitSignal == "EXIT_SHORT"){
         CloseTrades(MagicNumber,exitSignal);
      }
      
      Sleep(1000);
      
      //---------------//
      // TRADE PLACEMENT
      //---------------//
      
      //Entry Signals & Order Placement Execution
      string entrySignal = MA_EntrySignal(close1,close2,ma1,ma2);
      Comment("EA #",MagicNumber," | ",exitSignal," | ",entrySignal," SIGNALS DETECTED");
      
      if((entrySignal == "LONG" || entrySignal == "SHORT") && CheckPlacedPositions(MagicNumber) == false){
         ulong ticket = OpenTrades(entrySignal,MagicNumber,FixedVolume);
         
         //SL & TP Trade Modification
         if(ticket > 0){
            double stopLoss = CalculateStopLoss(entrySignal,SLFixedPoints,SLFixedPointsMA,ma1); 
            double takeProfit = CalculateTakeProfit(entrySignal,TPFixedPoints);
            TradeModification(ticket,MagicNumber,stopLoss,takeProfit);
         }
      }
         //---------------//
         // POSITION MANAGEMENT
         //---------------//
         
         if(TSLFixedPoints > 0){TralingStopLoss(MagicNumber,TSLFixedPoints);}
         if(BEFixedPoints > 0){BreakEven(MagicNumber,BEFixedPoints);}
  }
}