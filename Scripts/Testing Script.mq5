//+------------------------------------------------------------------+
//|                                               Testing Script.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      ""
#property version   "1.00"

uint MagicNumber = 101;

void OnStart()
  {
      //Buy positions open trades at the Ask but close them at the Bid
      //Sell positions open trades at Bid but close them at the Ask
      
      double askPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      
      //Price must be normalized either to digits or ticksize
      askPrice = round(askPrice/tickSize) * tickSize;
      bidPrice = round(bidPrice/tickSize) * tickSize;
  
      string comment = "LONG" + " | " + _Symbol + " | " + string(MagicNumber);
       
      //Request and Result Declaration and Initialization
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      
      //Request Parameters
      request.action = TRADE_ACTION_DEAL;
      request.symbol = _Symbol;
      request.volume = 0.01;
      request.type = ORDER_TYPE_BUY;
      request.price = askPrice;
      request.deviation = 10;
      request.magic = MagicNumber;
      request.comment = comment;
      
      //Request send
      if(!OrderSend(request,result)){
         Print("OrderSend trade placement error: ", GetLastError()); //if request was not send, print error code
      }
      //Trade Information
      Print("Open ",request.symbol," LONG"," Order #",result.order
            ,": ",result.retcode,", volume: ",result.volume
            ,", Price: ",DoubleToString(result.price,_Digits));
      
  }
