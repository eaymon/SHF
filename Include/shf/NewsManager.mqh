//+------------------------------------------------------------------+
//|                                                  NewsManager.mqh |
//|                                                     Eaymon Latif |
//|                                          http://www.someshed.com |
//+------------------------------------------------------------------+
#property copyright "Eaymon Latif"
#property link      "http://www.someshed.com"
#property strict

#import  "Wininet.dll"
   int InternetOpenW(string, int, string, string, int);
   int InternetConnectW(int, string, int, string, string, int, int, int);
   int HttpOpenRequestW(int, string, string, int, string, int, string, int);
//start 2015 atstrader revision
   //   int InternetOpenUrlW(int, string, string, int, int, int);
//end 2015 atstrader revision
   int InternetOpenUrlW(int, string, string, uint, uint, uint);
   int InternetReadFile(int, uchar & arr[], int, int & arr[]);
   int InternetCloseHandle(int);
#import





extern string  sep9="================================================================";
//News is a profit killer... this will avoid trading those pairs that have an event soon
extern string  avo="---- Avoid News ----";
extern bool    StopTradingNews=true;
// stop trading for high, high/medium or high/medium/low events 
extern int     Stop_Impacts_H_HM_HML_123=1;
//Stop trading XX minutes before the news event
extern double  NewsMinutesBefore=60;
extern double  NewsMinutesUntilResume=240;





#define READURL_BUFFER_SIZE   100

#define TITLE		0
#define COUNTRY   1
#define DATE		2
#define TIME		3
#define IMPACT		4
#define FORECAST	5
#define PREVIOUS	6

static int	   UpdateRateMin = 10;
int	         currentMin = 0;
int            WebUpdateFreq = 240; 
int            Minutes[8], newsIdx, next;
bool           skip;
string 		   xmlFileName;
string         xmlSearchName;
datetime       newsTime,calendardate;   //sundaydate calendar
double   	   ExtMapBuffer0[];     // Contains (minutes until) each news event
int 	         xmlHandle, BoEvent, finalend, end, begin, minsTillNews;
string	      sUrl = "http://www.forexfactory.com/ff_calendar_thisweek.xml"; //original
string   	   myEvent,mainData[200][7], sData, csvoutput, sinceUntil, TimeStr;
string    	   G,/*pair, cntry1, cntry2,*/ Title[8], Country[8], Impact[8],event[5],Color[5];
string 	      sTags[7] = { "<title>", "<country>", "<date><![CDATA[","<time><![CDATA[",
               "<impact><![CDATA[", "<forecast><![CDATA[", "<previous><![CDATA[" };
string 	      eTags[7] = { "</title>", "</country>", "]]></date>", "]]></time>",
               "]]></impact>", "]]></forecast>", "]]></previous>" };



//+-----------------------------------------------------------------------------------------------+
//| Initialization                                                                      |
//+-----------------------------------------------------------------------------------------------+
void InitNewsManager()
{
   
   //Get current time frame
	//Make sure we are connected.  Otherwise exit.
   //With the first DLL call below, the program will exit (and stop) automatically after one alert.
   if ( !IsDllsAllowed() ) 
   {
      Alert(Symbol()," ",Period(),", Cal: Allow DLL Imports");
   }
   //Management of FFCal.xml Files involves setting up a search to find and delete files
	//that are not of this Sunday date.  This search is limited to 10 weeks back (604800 seconds).
	//Files with Sunday dates that are older will not be purged by this search and will have to be
	//manually deleted by the user.
	xmlFileName = GetXmlFileName();
   for (int k=calendardate;k>=calendardate-6048000;k=k-604800)
   {
      xmlSearchName =  (StringConcatenate(TimeYear(k),"-",
         PadString(DoubleToStr(TimeMonth(k),0),"0",2),"-",
         PadString(DoubleToStr(TimeDay(k),0),"0",2),"-FFCal-News",".xml"));
      xmlHandle = FileOpen(xmlSearchName, FILE_BIN|FILE_READ);
	   if(xmlHandle >= 0) //file exists.  A return of -1 means file does not exist.
	   {
	      FileClose(xmlHandle);
	      if(xmlSearchName != xmlFileName)FileDelete(xmlSearchName);
	   }
	}
}

void DeinitNewsManager(){


}


//+-----------------------------------------------------------------------------------------------+
//| Indicator Start                                                                               |
//+-----------------------------------------------------------------------------------------------+
int RunNewsManager()
{
   if(!StopTradingNews)  return (0);   


   InitNews(sUrl);
   //if we haven't changed time frame then keep doing what we are doing
   if(MathMod(Minute(),UpdateRateMin)  != 0)
   {
 
      return (true);
   }
   
   
	//New xml file handling coding and revised parsing coding
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ);
	if(xmlHandle>=0)
	{
	   int size = FileSize(xmlHandle);
	   sData = FileReadString(xmlHandle, size);
	   FileClose(xmlHandle);
	}
   

	//Parse the XML file looking for an event to report
	newsIdx = 0;
	//tmpMins = 0;
	BoEvent = 0;
	while (true)
   {
		BoEvent = StringFind(sData, "<event>", BoEvent);
		if (BoEvent == -1) break;
		BoEvent += 7;
		next = StringFind(sData, "</event>", BoEvent);
		if (next == -1) break;
		myEvent = StringSubstr(sData, BoEvent, next - BoEvent);
		BoEvent = next;
		begin = 0;
		skip = false;
		for (int i=0; i < 7; i++)
		{
			mainData[newsIdx][i] = "";
			next = StringFind(myEvent, sTags[i], begin);
			// Within this event, if tag not found, then it must be missing; skip it
			if (next == -1) continue;
			else
			{
				// We must have found the sTag okay...
				begin = next + StringLen(sTags[i]);		   	// Advance past the start tag
				end = StringFind(myEvent, eTags[i], begin);	// Find start of end tag
				//Get data between start and end tag
				if (end > begin && end != -1)
				   {mainData[newsIdx][i] = StringSubstr(myEvent, begin, end - begin);}
			}
		}//End "for" loop

		if ((Stop_Impacts_H_HM_HML_123 == 1) &&
		   ((mainData[newsIdx][IMPACT] == "Medium") || (mainData[newsIdx][IMPACT] == "Low")))
		   {skip = true;}

		else if ((Stop_Impacts_H_HM_HML_123 == 2) && (mainData[newsIdx][IMPACT] == "Low"))
		   {skip = true;}

		else if (StringSubstr(mainData[newsIdx][TITLE],0,4)!= "Bank")
		    {skip = true;}

		else if (StringSubstr(mainData[newsIdx][TITLE],0,8)!= "Daylight")
		    {skip = true;}

   	else if (mainData[newsIdx][TIME] == "All Day" || 
   	         mainData[newsIdx][TIME] == "Tentative" ||
		  	      mainData[newsIdx][TIME] == "")
		  	{skip = true;}
      

		//If not skipping this event, then log time to event it into ExtMapBuffer0
		if (!skip)
		{
			// Now calculate the minutes until this announcement (may be negative)
			newsTime = MakeDateTime(mainData[newsIdx][DATE], mainData[newsIdx][TIME]);
			minsTillNews = (newsTime - TimeGMT()) / 60;
			
			//save events that are within our time window 
			if(minsTillNews > -NewsMinutesUntilResume && minsTillNews <= NewsMinutesBefore)
			   newsIdx++;

		}//End "skip" routine
	}//End "while" routine
   return (0);
}



bool IsNewsInRange(string cSymbol){
   if(!StopTradingNews) return (false);	
	for (int i=0; i<20; i++)
	{  
	   //check if the current symbol exists in any of the tagged events
	   if(StringFind(cSymbol,mainData[i][COUNTRY],0) >= 0)
	       return (true);  
	}
	return (false);  
}



//+-----------------------------------------------------------------------------------------------+
//| Subroutines: recoded creation and maintenance of single xml file                              |
//+-----------------------------------------------------------------------------------------------+   
//void InitNews(string& mainData[][], string newsUrl)
void InitNews(string newsUrl)
{
   if(DoFileDownLoad()) //Added to check if the CSV file already exists
   {
      DownLoadWebPageToFile(newsUrl); //downloading the xml file
   }
}

//If we have recent file don't download again
bool DoFileDownLoad()
{
   xmlHandle = 0;
   int size;
   datetime time = TimeCurrent();
   //datetime time = TimeLocal();

   if(GlobalVariableCheck("Update.FF_Cal") == false)return(true);
   if((time - GlobalVariableGet("Update.FF_Cal")) > WebUpdateFreq*60)return(true);

   xmlFileName = GetXmlFileName();
   xmlHandle=FileOpen(xmlFileName,FILE_BIN|FILE_READ);  //check if file exist
   if(xmlHandle>=0)//when the file exists we read data
   {
	   size = FileSize(xmlHandle);
	   sData = FileReadString(xmlHandle, size);
      FileClose(xmlHandle);//close it again check is done
      return(false);//file exists no need to download again
   }
   //File does not exist if FileOpen return -1 or if GetLastError = ERR_CANNOT_OPEN_FILE (4103)
   return(true); //commando true to download xml file
}

//+-----------------------------------------------------------------------------------------------+
//| Subroutine: getting the name of the ForexFactory .xml file                                    |
//+-----------------------------------------------------------------------------------------------+

string GetXmlFileName()
{
   int adjustDays = TimeDayOfWeek(TimeLocal());
   /*switch(TimeDayOfWeek(TimeLocal()))
      {
      case 0:
      adjustDays = 0;
      break;
      case 1:
      adjustDays = 1;
      break;
      case 2:
      adjustDays = 2;
      break;
      case 3:
      adjustDays = 3;
      break;
      case 4:
      adjustDays = 4;
      break;
      case 5:
      adjustDays = 5;
      break;
      case 6:
      adjustDays = 6;
      break;
      }
      */
   calendardate =  TimeLocal() - (adjustDays  * 86400);
   string fileName =  (StringConcatenate(TimeYear(calendardate),"-",
          PadString(DoubleToStr(TimeMonth(calendardate),0),"0",2),"-",
          PadString(DoubleToStr(TimeDay(calendardate),0),"0",2),"-FFCal-News",".xml"));

   return (fileName); //Always a Sunday date
}

//+-----------------------------------------------------------------------------------------------+
//| Subroutine: downloading the ForexFactory .xml file                                            |
//+-----------------------------------------------------------------------------------------------+

void DownLoadWebPageToFile(string url = "http://www.forexfactory.com/ff_calendar_thisweek.xml")
{
   int HttpOpen = InternetOpenW(" ", 0, " ", " ", 0);
   int HttpConnect = InternetConnectW(HttpOpen, "", 80, "", "", 3, 0, 1);
   int HttpRequest = InternetOpenUrlW(HttpOpen, url, NULL, 0, 0x84000100, 0);


   int read[1];
   uchar  Buffer[];
   ArrayResize(Buffer, READURL_BUFFER_SIZE + 1);
   string NEWS = "";

	xmlFileName = GetXmlFileName();
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_READ|FILE_WRITE);
	//File exists if FileOpen return >=0.
   if (xmlHandle >= 0) {FileClose(xmlHandle); FileDelete(xmlFileName);}

   //Open new XML.  Write the ForexFactory page contents to a .htm file.  Close new XML.
	xmlHandle = FileOpen(xmlFileName, FILE_BIN|FILE_WRITE);

   while (true)
   {
      InternetReadFile(HttpRequest, Buffer, READURL_BUFFER_SIZE, read);
      string strThisRead = CharArrayToString(Buffer, 0, read[0], CP_UTF8);
      if (read[0] > 0)NEWS = NEWS + strThisRead;
      else
      {
         FileWriteString(xmlHandle, NEWS);
         FileClose(xmlHandle);
		   //Find the XML end tag to ensure a complete page was downloaded.
		   end = StringFind(NEWS, "</weeklyevents>", 0);
		   //If the end of file tag is not found, a return -1 (or, "end <=0" in this case),
		   //then return (false).
		   if (end == -1)
		   {
		      Alert(Symbol()," ",Period(),", FFCal Error: File download incomplete!");
		      return;
		   }
		   //Else, set global to time of last update
		   else {GlobalVariableSet("Update.FF_Cal", TimeCurrent());}
         break;
      }
   }
   if (HttpRequest > 0) InternetCloseHandle(HttpRequest);
   if (HttpConnect > 0) InternetCloseHandle(HttpConnect);
   if (HttpOpen > 0) InternetCloseHandle(HttpOpen);
}

//+-----------------------------------------------------------------------------------------------+
//| Subroutine: to pad string                                                                     |
//+-----------------------------------------------------------------------------------------------+
string PadString(string toBePadded, string paddingChar, int paddingLength)
{
   while(StringLen(toBePadded) <  paddingLength)
   {
      toBePadded = StringConcatenate(paddingChar,toBePadded);
   }
   return (toBePadded);
}

//+-----------------------------------------------------------------------------------------------+
//| Indicator Subroutine For Date/Time    changed by deVries                                      |
//+-----------------------------------------------------------------------------------------------+
datetime MakeDateTime(string strDate, string strTime)  //not string now datetime
{
	int n1stDash = StringFind(strDate, "-");
	int n2ndDash = StringFind(strDate, "-", n1stDash+1);

	string strMonth = StringSubstr(strDate, 0, 2);
	string strDay = StringSubstr(strDate, 3, 2);
	string strYear = StringSubstr(strDate, 6, 4);

	int nTimeColonPos = StringFind(strTime, ":");
	string strHour = StringSubstr(strTime, 0, nTimeColonPos);
	string strMinute = StringSubstr(strTime, nTimeColonPos+1, 2);
	string strAM_PM = StringSubstr(strTime, StringLen(strTime)-2);

	int nHour24 = StrToInteger(strHour);
	if ((strAM_PM == "pm" || strAM_PM == "PM") && nHour24 != 12) {nHour24 += 12;}
	if ((strAM_PM == "am" || strAM_PM == "AM") && nHour24 == 12) {nHour24 = 0;}

	datetime newsevent = StringToTime(strYear+ "." + strMonth + "." +
	   strDay)+nHour24*3600+ (StringToInteger(strMinute)*60);
	return(newsevent);
}

//+-----------------------------------------------------------------------------------------------+
//| End                                                                                 |
//+-----------------------------------------------------------------------------------------------+