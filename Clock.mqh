//+------------------------------------------------------------------+
//|                                                        Clock.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#define DAYLIGHTSAVING_METHOD_NONE 0
#define DAYLIGHTSAVING_METHOD_US 1
#define DAYLIGHTSAVING_METHOD_UK 2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Clock
  {
private:
   int               _year;
   datetime          _srvdt;
   datetime          _gmtdt;
   datetime          _dst_us_begin;
   datetime          _dst_us_end;
   datetime          _dst_uk_begin;
   datetime          _dst_uk_end;
   void              ComputeDaylightSavingTime();
   void              ComputeGreenwichMeanTime(void);
public :
   int               GMTOffset;
   int               DSTMethod;
   void              Clock(void);
   void              Clock(int offset, int method);
   void              Set(const datetime value);
   datetime          DateTime(int offset, int method);
   datetime          ServerTime(void) {return(_srvdt);}
   datetime          GreenwichMeanTime(void) {return(_gmtdt);}
   bool              IsDaylightSavingTime(void);
   bool              IsDaylightSavingTime(int method);
   bool              IsDaylightSavingTime(datetime value, int method);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Clock::Clock(void)
  {
   GMTOffset = 0;
   DSTMethod = 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Clock::Clock(int offset,int method)
  {
   GMTOffset = offset;
   DSTMethod = method;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Clock::Set(const datetime value)
  {
   _srvdt = value;
   ComputeDaylightSavingTime();
   ComputeGreenwichMeanTime();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime Clock::DateTime(int offset,int method)
  {
   return _gmtdt + (offset + IsDaylightSavingTime(method))*3600;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Clock::IsDaylightSavingTime(void)
  {
   datetime tmpdt = _srvdt-GMTOffset*3600;
   if(DSTMethod == 0)
      return false;
   else
      if(DSTMethod == 1)
         return (_dst_us_begin <= tmpdt && tmpdt < _dst_us_end) ? true:false;
      else
         if(DSTMethod == 2)
            return (_dst_uk_begin <= tmpdt && tmpdt < _dst_uk_end) ? true:false;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Clock::IsDaylightSavingTime(int method)
  {
   datetime tmpdt = _srvdt-GMTOffset*3600;
   if(method == 0)
      return false;
   else
      if(method == 1)
         return (_dst_us_begin <= tmpdt && tmpdt < _dst_us_end) ? true:false;
      else
         if(method == 2)
            return (_dst_uk_begin <= tmpdt && tmpdt < _dst_uk_end) ? true:false;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Clock::IsDaylightSavingTime(datetime value,int method)
  {
   datetime tmpdt = value;
   if(method == 0)
      return false;
   else
      if(method == 1)
         return (_dst_us_begin <= tmpdt && tmpdt < _dst_us_end) ? true:false;
      else
         if(method == 2)
            return (_dst_uk_begin <= tmpdt && tmpdt < _dst_uk_end) ? true:false;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Clock::ComputeDaylightSavingTime()
  {
   MqlDateTime mqldt;
   TimeToStruct(_srvdt,mqldt);
   if(mqldt.year!=_year)
     {
      _year = mqldt.year;
      MqlDateTime str1, str2, str3, str4;
      datetime dt1, dt2, dt3,dt4;
      /* US DST begins at 01:00 GMT on the second Sunday of March and
         ends at 01:00 GMT (02:00 UST) on the first Sunday in November*/
      dt1 = (datetime)((string)_year+".3.14");
      dt2 = (datetime)((string)_year+".11.07");
      /* UK DST begins at 01:00 GMT on the last Sunday of March and
      ends at 01:00 GMT (02:00 BST) on the last Sunday of October.*/
      dt3 = (datetime)((string)_year+".3.31");
      dt4 = (datetime)((string)_year+".10.31");
      TimeToStruct(dt1,str1);
      TimeToStruct(dt2,str2);
      TimeToStruct(dt3,str3);
      TimeToStruct(dt4,str4);
      _dst_us_begin = dt1-(str1.day_of_week*86400);
      _dst_us_end   = dt2-(str2.day_of_week*86400);
      _dst_uk_begin = dt3-(str3.day_of_week*86400);
      _dst_uk_end   = dt4-(str4.day_of_week*86400);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Clock::ComputeGreenwichMeanTime(void)
  {
   datetime dt = _srvdt - (GMTOffset + IsDaylightSavingTime())*3600;
   _gmtdt = dt;
  }
//+------------------------------------------------------------------+