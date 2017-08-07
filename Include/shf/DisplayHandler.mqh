//+------------------------------------------------------------------+
//|                                               DisplayHandler.mqh |
//|                                                     Eaymon Latif |
//|                                          http://www.someshed.com |
//+------------------------------------------------------------------+


extern string  s222="================================================================";
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  chf               ="---- Chart feedback display ----";
extern bool    ShowChartFeedback=true;
// if using Comments
extern int     DisplayGapSize    = 30;
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
extern bool    DisplayAsText     = true;
//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern bool    KeepTextOnTop     = true;
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color    colour            = Yellow;
// adjustment to reform lines for different font size
extern double  spacingtweek      = 0.6;
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////