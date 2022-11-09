//+------------------------------------------------------------------+
//|                             Simple Moving Average Hedging EA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+
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
      
      }
      
      Sleep(1000);
      
      //---------------//
      // TRADE PLACEMENT
      //---------------//
      
      string entrySignal = MA_EntrySignal(close1,close2,ma1,ma2);
      
      if(entrySignal == "LONG"){
         printf("Long trade placed");
         
      }else if(entrySignal == "SHORT"){
         Print("Short trade placed");
      }
  }


   
  }

//+------------------------------------------------------------------+
//|EA Functions                                                      |
//+------------------------------------------------------------------+

///////////price functions////////////
double Close(int pShift){
   
   MqlRates bar[];    //it creates an object array of MqlRates structure
   ArraySetAsSeries(bar,true); //it sets our array as a series array (so current bar is position 0, previows bar 1.....)
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,bar); // it copies the bar price information of bars position0,1 and 2 to our array "bar"
   
   return bar[pShift].close;
}

double Open(int pShift){
   
   MqlRates bar[];    //it creates an object array of MqlRates structure
   ArraySetAsSeries(bar,true); //it sets our array as a series array (so current bar is position 0, previows bar 1.....)
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,bar); // it copies the bar price information of bars position0,1 and 2 to our array "bar"
   
   return bar[pShift].open;
}

////////////Moving Average Functions/////////////

int MA_Int(int pMAPeriod, int pMAShift, ENUM_MA_METHOD pMAMethod, ENUM_APPLIED_PRICE pMAPrice){
   
   //In case of error when initializing the MA, GetLastError() will get the error and store it in _lastError
   //RestLastError will change _lastError variabl to 0
   ResetLastError();
   
   //A unique identifier for the indicator. 
   //Used for all actions related to the indicator, such as copying data and removing the indicator
   int Handle = iMA(_Symbol,PERIOD_CURRENT,pMAPeriod,pMAShift,pMAMethod,pMAPrice);
   
   if(Handle == INVALID_HANDLE){
      return -1;
      Print("There was an error creating the MA Indicator Handle: ",GetLastError());
   }
   Print("MA Indicator handle initialized successfully");
   
   return Handle;
}

double ma(int pMAHandle, int pShift){
   ResetLastError();
   
   //We create and fill an array with MA values
   double ma[];
   ArraySetAsSeries(ma,true);
   
   //We fill the array with the 3 most reset ma values
   bool fillResult = CopyBuffer(pMAHandle,0,0,3,ma);
   if(fillResult == false){
      Print("FILL_ERROR: ",GetLastError());
   }
   //We ask for the ma value stored in pShift
   double maValue = ma[pShift];
   
   //We normalize the maValue to our symbol's digits and return it
   maValue = NormalizeDouble(maValue,_Digits);
   
   return maValue;
}

string MA_EntrySignal(double pPrice1, double pPrice2, double pMA1, double pMA2){
   string str = "";
   string indicatorValues;
   
   if(pPrice1 > pMA1 && pPrice2 <= pMA2){
      str = "LONG";
   }else if(pPrice1 < pMA1 && pPrice2 >= pMA2){
      str = "SHORT";
   }else{
      str = "NO_TRADE";
   }
   
   StringConcatenate(indicatorValues
                     ,"MA 1: ",DoubleToString(pMA1,_Digits)," | "
                     ,"MA 2: ",DoubleToString(pMA2,_Digits)," | "
                     ,"Close 1: ",DoubleToString(pPrice1,_Digits)," | "
                     ,"Close 2: ",DoubleToString(pPrice2,_Digits));
                     
   Print("Indicator Values: ", indicatorValues);
   return str;
}

string MA_ExitSignal(double pPrice1, double pPrice2, double pMA1, double pMA2){
   string str = "";
   string indicatorValues;
   
   if(pPrice1 > pMA1 && pPrice2 <= pMA2){
      str = "EXIT_SHORT";
   }else if(pPrice1 < pMA1 && pPrice2 >= pMA2){
      str = "EXIT_LONG";
   }else{
      str = "NO_TRADE";
   }
   
   StringConcatenate(indicatorValues
                     ,"MA 1: ",DoubleToString(pMA1,_Digits)," | "
                     ,"MA 2: ",DoubleToString(pMA2,_Digits)," | "
                     ,"Close 1: ",DoubleToString(pPrice1,_Digits)," | "
                     ,"Close 2: ",DoubleToString(pPrice2,_Digits));
                     
   Print("Indicator Values: ", indicatorValues);
   return str;
}

////////////Bollinger Bands Functions///////////// 

int BB_Int(int pBBPeriod, int pBBShift, double pBBDeviation, ENUM_APPLIED_PRICE pBBPrice){
   
   //In case of error when initializing the BB, GetLastError() will get the error and store it in _lastError
   //RestLastError will change _lastError variabl to 0
   ResetLastError();
   
   //A unique identifier for the indicator. 
   //Used for all actions related to the indicator, such as copying data and removing the indicator
   int Handle = iBands(_Symbol,PERIOD_CURRENT,pBBPeriod,pBBShift,pBBDeviation,pBBPrice);
   
   if(Handle == INVALID_HANDLE){
      return -1;
      Print("There was an error creating the BB Indicator Handle: ",GetLastError());
   }
   Print("BB Indicator handle initialized successfully");
   
   return Handle;
}

double BB(int pBBHandle,int pBBLineBuffer, int pShift){
   ResetLastError();
   
   //We create and fill an array with MA values
   double BB[];
   ArraySetAsSeries(BB,true);
   
   //We fill the array with the 3 most reset ma values
   bool fillResult = CopyBuffer(pBBHandle,pBBLineBuffer,0,3,BB);
   if(fillResult == false){
      Print("FILL_ERROR: ",GetLastError());
   }
   //We ask for the ma value stored in pShift
   double BBValue = BB[pShift];
   
   //We normalize the maValue to our symbol's digits and return it
   BBValue = NormalizeDouble(BBValue,_Digits);
   
   return BBValue;
}
