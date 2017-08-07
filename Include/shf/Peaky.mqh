//+------------------------------------------------------------------+
//|                                                        Peaky.mqh |
//|                                                     Eaymon Latif |
//|                                          http://www.someshed.com |
//+------------------------------------------------------------------+


#define  longdirection " Long: "
#define  shortdirection " Short: "

//TP and SL use sixths choices. This means that the tp/sl will be one Sixth of the pips in between the peaks.
//Peak hilo and trading lines prices.
double         PeakHigh;
double         PeakLow;

extern string  sep1="================================================================";
extern string  pek="---- Peak HiLo inputs ----";
extern bool    UsePeaky=true;
extern ENUM_TIMEFRAMES PeakyTimeFrame=PERIOD_D1;
//No of bars to calculate the peak hilo
extern int     NoOfBars=1682;
////////////////////////////////////////////////////////////////////////////////
//Market direction.
string         PeakyMarketDirection[];//The Overall market direction constants are defined at the top of this code.
////////////////////////////////////////////////////////////////////////////////





void GetPeaks(string symbol, int tf, int cc)
{
   /*
   Note:
      * tf = the chart time frame being calculated.
      * cc = the time frame index being passed. This is 0 to 3.
   */

   //Calculates the PH and PL of the pair being passed by symbol. Stores these in the PeakHighs etc arrays..
   //Calculates the trading direction and stores it in the MarketDirection array.
   //Calculates the Sixths trading status and stores it in the MarketDirection array.
   
   //Get the bar shift of the peaks
   int currentPeakHighBar = iHighest(symbol, tf, MODE_CLOSE, NoOfBars, 1);
   int currentPeakLowBar = iLowest(symbol, tf, MODE_CLOSE, NoOfBars, 1);

   //Read the peak prices
   PeakHigh = iClose(symbol, tf, currentPeakHighBar);
   PeakLow = iClose(symbol, tf, currentPeakLowBar);
   
   //Calculate the market direction.
   //Short
   if (currentPeakHighBar < currentPeakLowBar)
      PeakyMarketDirection[cc] = shortdirection;
   else   
      PeakyMarketDirection[cc] = longdirection;
      
   /*
   Calculate the Sixths trading status i.e.
      - untradable outside the Sixths.
      - tradable short from within the top Sixth.
      - tradable long from within the bottom Sixth.
      - Also tell PoS to close opposite direction trades.
   */   
   
}//End void GetPeaks(string symbol, int tf)

void DeInitPeaky(){

   ArrayFree(PeakyMarketDirection);
}