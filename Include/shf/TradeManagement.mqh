//+------------------------------------------------------------------+
//|                                                      Awesome.mq4 |
//|                                                    Steve Hopwood |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"


//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "
#define  tpsl " take profit or stop loss insertion failed with error "
#define  oop " pending order price modification failed with error "


////////////////////////////////////////////////////////////////////////////////////////////
//START OF INDIVIDUAL TRADE MANAGEMENT MODULE
void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()

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