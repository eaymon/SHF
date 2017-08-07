//+------------------------------------------------------------------+
//|                                                      Awesome.mq4 |
//|                                                    Steve Hopwood |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"



////////////////////////////////////////////////////////////////////////////////////////////
//START OF INDIVIDUAL TRADE MANAGEMENT MODULE


bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   
   if (AccountMargin() > 0)
   {
      
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < MinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()


double CalculateTakeProfit(int type, double price, int cc)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take = 0;//Take profit to return.
   double takeprofit = TakeProfits[cc];
   
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(takeprofit, 0) )
      {
         take = NormalizeDouble(price + (takeprofit / factor),digits);
      }//if (!CloseEnough(takeprofit, 0) )
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(takeprofit, 0) )
      {
         take = NormalizeDouble(price - (takeprofit / factor),digits);
      }//if (!CloseEnough(takeprofit, 0) )
   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

double CalculateStopLoss(int type, double price, int cc)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop = 0;
   double stoploss = StopLosses[cc];//'Hard' stop loss.
     
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(stoploss, 0) ) 
      {
         stop = NormalizeDouble(price - (stoploss / factor),digits);
      }//if (!CloseEnough(StopLoss, 0) )       
   }//if (type == OP_BUY)      
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(stoploss, 0) ) 
      {
         stop = NormalizeDouble(price + (stoploss / factor),digits);
      }//if (!CloseEnough(StopLoss, 0) )
   }//if (type == OP_SELL)   
   
   return(stop);
   
}//End double CalculateStopLoss(int type)
void BreakEvenStopLoss(int ticket, int cc) 
{

   // Move stop loss to breakeven
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   //I have copied this from MuptiPurposeTradeManage Updated, so set
   //up some local variables to save having to edit those already in place.
   double BreakEven = BreakEvenPips[cc];
   double BreakEvenProfit = BreakEvenProfitPips[cc];

   //No need to continue if already at BE
   if (OrderType() == OP_BUY)
      if (OrderStopLoss() >= OrderOpenPrice() )
         return;
         
   if (OrderType() == OP_SELL)
      if (!CloseEnough(OrderStopLoss(), 0) )//Sell stops need this extra conditional to cater for no stop loss trades
         if (OrderStopLoss() <= OrderOpenPrice() )
            return;
             

   int err = 0;
   bool modify = false;
   double stop = 0;
   
  //Can we move the stop loss to breakeven?        
   if (OrderType()==OP_BUY)
      if (OrderStopLoss() < OrderOpenPrice() )
         if (bid >= OrderOpenPrice() + (BreakEven / factor) )
            if (OrderStopLoss() < OrderOpenPrice() )
            {
               modify = true;
               stop = NormalizeDouble(OrderOpenPrice() + (BreakEvenProfit / factor), digits);
            }//if (OrderStopLoss()<OrderOpenPrice())
   	                  			         
          
   if (OrderType()==OP_SELL)
      if (OrderStopLoss() > OrderOpenPrice() || CloseEnough(OrderStopLoss(), 0) )
         if (bid <= OrderOpenPrice() - (BreakEven / factor) )
         {
            modify = true;
            stop = NormalizeDouble(OrderOpenPrice() - (BreakEvenProfit / factor), digits);
         }//if (OrderStopLoss()>OrderOpenPrice()) 
         
   //Modify the order stop loss if BE has been achieved
   if (modify)
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
   }//if (modify)
   

}//End void BreakEvenStopLoss(int ticket, int cc)



void JumpingStopLoss(int ticket, int cc) 
{
   // Jump stop loss by pips intervals chosen by user.
   // Also carry out partial closure if the user requires this


   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;//Order has closed, so nothing to do.    

   //I have copied this from MuptiPurposeTradeManage Updated, so set
   //up some local variables to save having to edit those already in place.
   bool JumpAfterBreakevenOnly = JumpAfterBreakEvenOnly[cc];
   double JumpingStop = JumpingStopPips[cc];

   
   // Abort the routine if JumpAfterBreakevenOnly is set to true and be stop is not yet set
   if (JumpAfterBreakevenOnly) 
   {
      if (OrderType()==OP_BUY)
         if(OrderStopLoss() < OrderOpenPrice() ) 
            return;
   
      if (OrderType()==OP_SELL)
         if(OrderStopLoss() > OrderOpenPrice() ) 
            return;
   }//if (JumpAfterBreakevenOnly)
   
  
   double stop = OrderStopLoss(); //Stop loss
   bool result = false, modify = false, TradeClosed = false;
   bool PartCloseSuccess = false;
   int err = 0;
   
   if (OrderType()==OP_BUY)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop < OrderOpenPrice() )
      {
         if (bid >= OrderOpenPrice() + (JumpingStop / factor))
         {
            stop = OrderOpenPrice();
            modify = true;
         }//if (ask >= OrderOpenPrice() + (JumpingStop / factor))
      }//if (CloseEnough(stop, 0) || stop<OrderOpenPrice())

      // Increment stop by stop + JumpingStop.
      // This will happen when market price >= (stop + JumpingStop)
      if (!modify)  
         if (stop >= OrderOpenPrice())      
            if (bid >= stop + ((JumpingStop * 2) / factor) ) 
            {
               stop+= (JumpingStop / factor);
               modify = true;
            }// if (bid>= stop + (JumpingStop / factor) && stop>= OrderOpenPrice())      
      
   
   }//if (OrderType()==OP_BUY)
   
   if (OrderType()==OP_SELL)
   {
      // First check if stop needs setting to breakeven
      if (CloseEnough(stop, 0) || stop > OrderOpenPrice())
      {
         if (bid <= OrderOpenPrice() - (JumpingStop / factor))
         {
            stop = OrderOpenPrice();
            modify = true;
         }//if (ask <= OrderOpenPrice() - (JumpingStop / factor))
      } // if (stop==0 || stop>OrderOpenPrice()

      // Decrement stop by stop - JumpingStop.
      // This will happen when market price <= (stop - JumpingStop)
      if (!modify)  
         if (stop <= OrderOpenPrice())      
            if (bid <= stop - ((JumpingStop * 2) / factor) ) 
            {
               stop-= (JumpingStop / factor);
               modify = true;
            }// if (bid>= stop + (JumpingStop / factor) && stop>= OrderOpenPrice())      
        
   }//if (OrderType()==OP_SELL)

   //Modify the order stop loss if a jump has been achieved
   if (modify)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), 
                                OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (result)
      {
         
         
      }//if (result)

   }//if (modify)


} //End void JumpingStopLoss(int ticket, int cc) 

void TradeManagementModule(int ticket, int cc)
{

   //Break even
   if (UseBreakEven[cc])
      BreakEvenStopLoss(ticket, cc);
      
   
   //Jumping stop loss
   if (UseJumpingStop[cc])
      JumpingStopLoss(ticket, cc);
   
}//End void TradeManagementModule(int ticket, int cc)


//END OF INDIVIDUAL TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////////

//Spread filter
bool SpreadOk(int cc)
{

   //Calculate the max allowable spread
   double target = AverageSpread[cc] * MultiplierToDetectStopHunt;
   if (CloseEnough(target, 0) )
      return(true);//Just in case.
      
   if (spread >= target)//Too wide
      return(false);

   //Got this far, so spread is ok.
   return(true);
   
}//End bool SpreadOk(int cc)

//Spread filter
void ReCalculateAverageSpread(string symbol, int cc, int counter)
{
   //Keep a running total of the spread for each pair, the periodically
   //re-calculate the average.
   RunningTotalOfSpreads[cc] += spread;
   
   //Do we need a recalc
   if (counter >= 100)
   {
      AverageSpread[cc] = RunningTotalOfSpreads[cc] / counter;
      SpreadGvName = symbol + " average spread";
      GlobalVariableSet(SpreadGvName, AverageSpread[cc]);      
      RunningTotalOfSpreads[cc] = 0;
   }//if (counter >= 100)


}//End void ReCalculateAverageSpread(string symbol, int cc, int counter)