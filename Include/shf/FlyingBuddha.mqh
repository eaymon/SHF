//+------------------------------------------------------------------+
//|                                                 FlyingBuddha.mqh |
//|                                                     Eaymon Latif |
//|                                          http://www.someshed.com |
//+------------------------------------------------------------------+



//Flying Buddha
#define  fbnoarrow "= No arrow:"
#define  fbuparrowtradable "= Tradable up arrow:"
#define  fbdownarrowtradable "= Tradable down arrow:"
#define  fbuparrowuntradable "= Untradable up arrow:"
#define  fbdownarrowuntradable "= Untradable down arrow:"


sinput string  sep3="================================================================";
sinput string  fbi="---- Flying Buddha inputs ----";
sinput string  ini="-- Indi inputs --";
sinput int     FbFastPeriod=5;
sinput int     FbFastAvgMode=1;
sinput int     FbFastPrice=0;
sinput int     FbSlowPeriod=5;
sinput int     FbSlowAvgMode=1;
sinput int     FbSlowPrice=0;
sinput int     FbMaxBars=2000;
sinput double  FbFactorWindow=0.03;
//Take every trade signal
sinput string  tri="-- Trading inputs --";
sinput bool    TradeEverySignal=true;
//Up to this maximum
sinput int     MaxSignalsToFollow=10;
//With this distance between signals.
sinput int     MinimumDistanceBetweenSignalsPips=10;
//Use atr to calculate the minimum distance
sinput bool    UsePercentageOfAtrForDistance=true;
//over this period
sinput int     FbAtrPeriod=24;                     
//at this percentage.
sinput int     FbPercentageOfAtrToUse=100;         
sinput string  trcl="-- Trade closure inputs --";
//Close buys following a down arrow and sells at an up arrow
sinput bool    CloseOnOppositeFB=true;            
//but only when SS is the same direction as the arrow.
sinput bool    OnlyCloseWhenSuperSlopeAgrees=true; 
////////////////////////////////////////////////////////////////////////////////////////
string         FbStatus[];//Constants defined at top of file
double         MinimumDistanceBetweenSignals=0;
double         fbAtrVal=0;
////////////////////////////////////////////////////////////////////////////////////////





double GetFlyingBuddha(string symbol, int tf, int ffp, int ffam, int ffpr, int fsp, int fsam, int fspr, int buffer, int shift)
{

   //Code by Baluda. Thanks very much Paul.
   
   double fastMA = iMA( symbol, tf, ffp, 0, ffam, ffpr, shift );
   double slowMA = iMA( symbol, tf, fsp, 0, fsam, fspr, shift );
   double high = iHigh( symbol, tf, shift );
   double low  = iLow( symbol, tf, shift );

   double result = EMPTY_VALUE;
      
   //-- long signal
   if ( buffer == 2 && high < MathMin( fastMA, slowMA ) ) result = low;
     
   //-- short signal
   if ( buffer == 3 && low > MathMax( fastMA, slowMA ) ) result = high;
   
   return ( result );

}//End double GetFlyingBuddha()