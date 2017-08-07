//+------------------------------------------------------------------+
//|                                                       Common.mqh |
//|                                                     Eaymon Latif |
//|                                          http://www.someshed.com |
//+------------------------------------------------------------------+




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


void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()



/*struct Position {

   bool           isOpen=false;
   int            Count=0;
   double         LatestPrice=0, EarliestPrice=0, HighestPrice=0, LowestPrice=0;
   int            TicketNo=-1, HighestTicketNo=-1, LowestTicketNo=-1, LatestTicketNo=-1, EarliestTicketNo=-1;
   double         PipsUpl=0;
   double         CashUpl=0;
   datetime       LatestTradeTime=0;
   datetime       EarliestTradeTime=0;
}*/

//Missing indi check
bool indiExists( string indiName ) 
{

   //Returns true if a custom indi exists in the user's indi folder, else false
   bool exists = false;
   
   ResetLastError();
   double value = iCustom( Symbol(), Period(), indiName, 0, 0 );
   if ( GetLastError() == 0 ) exists = true;
   
   return(exists);

}//End bool indiExists( string indiName ) 

double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
   double profit = 0;
   
   if (type == OP_BUY)
   {
      profit = bid - OrderOpenPrice();
   }//if (OrderType() == OP_BUY)

   if (type == OP_SELL)
   {
      profit = OrderOpenPrice() - ask;
   }//if (OrderType() == OP_SELL)
   //profit *= PFactor(OrderSymbol()); // use PFactor instead of point. This line for multi-pair ea's
   profit *= factor; // use PFactor instead of point.

   return(profit); // in real pips
}//double CalculateTradeProfitInPips(int type)


bool CloseEnough(double num1,double num2)
{
/*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */

   if(num1==0 && num2==0) return(true); //0==0
   if(MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);

//Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)

bool AreWeAtRollover()
{

   double time;
   int hours,minutes,rstart,rend,ltime;
   
   time=StrToDouble(RollOverStarts);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rstart=60*hours+minutes;
      
   time=StrToDouble(RollOverEnds);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rend=60*hours+minutes;
   
   ltime=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());

   if (rend>rstart)
     if(ltime>rstart && ltime<rend)
       return(true);
   if (rend<rstart) //Over midnight
     if(ltime>rstart || ltime<rend)
       return(true);

   //Got here, so not at rollover
   return(false);

}//End bool AreWeAtRollover()