//+------------------------------------------------------------------+
//|                                                   SuperSlope.mqh |
//|                                                     Eaymon Latif |
//|                                          http://www.someshed.com |
//+------------------------------------------------------------------+



//SuperSlope colours
#define  red " Red:"
#define  blue " Blue:"
//Changed by tomele
#define white " White:"

extern string  sep2="================================================================";
extern string  ssi="---- SuperSlope inputs ----";
extern bool    UseSuperSlope=true;
extern ENUM_TIMEFRAMES SsTimeFrame=PERIOD_D1;
extern int     SsTradingMaxBars              = 0;
extern bool    SsTradingAutoTimeFrame        = true;
extern double  SsTradingDifferenceThreshold  = 0.0;
extern double  SsTradingLevelCrossValue      = 2.0;
extern int     SsTradingSlopeMAPeriod        = 5; 
extern int     SsTradingSlopeATRPeriod       = 50; 
extern bool    SsCloseTradesOnColourChange=false;
////////////////////////////////////////////////////////////////////////////////////////
//I added HTF as an afterthought, so these variables are for TradingTimeFrame
double         SsTtfCurr1Val=0, SsTtfCurr2Val=0;
string         SsColour[];
bool           BrokerHasSundayCandles;
bool           LongTradeTrigger=false, ShortTradeTrigger=false;//Set to true when there is a signal on the TradingTimeFrame
////////////////////////////////////////////////////////////////////////////////////////


double GetSuperSlope(string symbol, int tf, int maperiod, int atrperiod, int pShift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = pShift;
   if ( BrokerHasSundayCandles && PERIOD_CURRENT == PERIOD_D1 )
   {
      if ( TimeDayOfWeek( iTime( symbol, PERIOD_D1, pShift ) ) == 0  ) shiftWithoutSunday++;
   }   

   double atr = iATR( symbol, tf, atrperiod, shiftWithoutSunday + 10 ) / 10;
   double result = 0.0;
   if ( atr != 0 )
   {
      dblTma = iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday );
      dblPrev = ( iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday + 1 ) * 231 + iClose( symbol, tf, shiftWithoutSunday ) * 20 ) / 251;

      result = ( dblTma - dblPrev ) / atr;
   }
   
   return ( result );
   
}//GetSuperSlope(}
