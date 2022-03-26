//+------------------------------------------------------------------+
//|                                                VolumeProfile.mqh |
//|                            Copyright 2022, Diamond Systems Corp. |
//|                                   https://github.com/mql-systems |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Diamond Systems Corp."
#property link      "https://github.com/mql-systems"
#property version   "1.00"

//--- includes
#include <Canvas\Canvas.mqh>

//--- structures
struct VolumeProfileData
{
   double volumeInPercent;
   uint   volumeClr;
};

//+------------------------------------------------------------------+
//| class VolumeProfile                                              |
//+------------------------------------------------------------------+
class VolumeProfile
{
   private:
      long              m_chartId;
      int               m_subWin;
      static int        s_nameSuffix;
      CCanvas           m_profile;
      //---
      bool              m_isUpdate;
      bool              m_isVertical;
      uint              m_profileBg;
      //---
      datetime          m_profileTime;
      double            m_profilePrice;
      int               m_profileX;
      int               m_profileY;
      int               m_profileWidth;
      int               m_profileHeight;
      //---
      int               m_volumeDistance;
      VolumeProfileData m_volumeData[];
      
   private:
      string            GenerateName() { return "VolumeProfileBar"+(string)(++s_nameSuffix); }
      bool              Update();
      
   public:
                        VolumeProfile();
                       ~VolumeProfile();
      //---
      bool              Create(datetime time, double price, int width, int height, long chartID = 0, int subWin = 0);
      bool              Create(int x, int y, int width, int height, long chartID = 0, int subWin = 0);
      bool              Redraw();
      //---
      string            Name()             { return m_profile.ChartObjectName();    }
      //---
      datetime          Time()             { return m_profileTime;                  }
      double            High()             { return m_profilePrice;                 }
      datetime          X()                { return m_profileX;                     }
      double            Y()                { return m_profileY;                     }
      int               Width()            { return m_profileWidth;                 }
      bool              Width(int width)   { return Resize(width, m_profileHeight); }
      int               Height()           { return m_profileHeight;                }
      bool              Height(int height) { return Resize(m_profileWidth, height); }
      //---
      bool              Move(datetime time, double price);
      bool              Move(int x, int y);
      bool              Resize(int width, int height);
      //---
      uint              Bg()                         { return m_profileBg;                           }
      void              Bg(uint clr)                 { m_isUpdate = true; m_profileBg = clr;         }
      bool              Vertical()                   { return m_isVertical;                          }
      void              Vertical(bool isVertical)    { m_isUpdate = true; m_isVertical = isVertical; }
      int               VolumeDistance()             { return m_volumeDistance;                      }
      bool              VolumeDistance(int distance);
};

int VolumeProfile::s_nameSuffix = 0;

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
VolumeProfile::VolumeProfile(): m_profileHeight(0)
{
   m_isUpdate       = false;
   m_isVertical     = true;
   m_profileBg      = 0;
   m_volumeDistance = 1;
   //---
   m_profileTime  = 0;
   m_profilePrice = 0.0;
   m_profileX     = 0;
   m_profileY     = 0;
   m_profileWidth = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
VolumeProfile::~VolumeProfile()
{
   m_profile.Destroy();
}

//+------------------------------------------------------------------+
//| Create on time and price                                         |
//+------------------------------------------------------------------+
bool VolumeProfile::Create(datetime time, double price, int width, int height, long chartID = 0, int subWin = 0)
{
   if (m_profileHeight != 0 || time < 1 || price <= 0 || width < 1 || height < 1)
      return false;
   
   m_profileTime   = time;
   m_profilePrice  = price;
   m_profileWidth  = width;
   m_profileHeight = height;
   m_subWin        = subWin;
   
   if (chartID > 0)
      m_chartId = chartID;
   else
      m_chartId = ChartID();
      
   if (! m_profile.CreateBitmap(m_chartId, m_subWin, GenerateName(), time, price, width, height, COLOR_FORMAT_ARGB_RAW))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Create by coordinates                                            |
//+------------------------------------------------------------------+
bool VolumeProfile::Create(int x, int y, int width, int height, long chartID = 0, int subWin = 0)
{
   if (m_profileHeight != 0 || x < 0 || y < 0 || width < 1 || height < 1)
      return false;
   
   m_profileX      = x;
   m_profileY      = y;
   m_profileWidth  = width;
   m_profileHeight = height;
   m_subWin        = subWin;
   
   if (chartID > 0)
      m_chartId = chartID;
   else
      m_chartId = ChartID();
   
   if (! m_profile.CreateBitmapLabel(m_chartId, m_subWin, GenerateName(), x, y, width, height, COLOR_FORMAT_ARGB_RAW))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Move profile by time and price                                   |
//+------------------------------------------------------------------+
bool VolumeProfile::Move(datetime time, double price)
{
   if (m_profileTime == 0 || time < 1 || price <= 0)
      return false;
   
   string name = Name();
   
   if (! ObjectSetInteger(m_chartId, name, OBJPROP_TIME, time))
      return false;
   if (! ObjectSetDouble(m_chartId, name, OBJPROP_PRICE, price))
      return false;
   
   m_profileTime = time;
   m_profilePrice = price;
   
   return true;
}

//+------------------------------------------------------------------+
//| Move profile by coordinates                                      |
//+------------------------------------------------------------------+
bool VolumeProfile::Move(int x, int y)
{
   if ((m_profileHeight != 0 && m_profileTime != 0) || x < 0 || y < 0)
      return false;
   
   string name = Name();
   
   if (! ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x))
      return false;
   if (! ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y))
      return false;
   
   m_profileX = x;
   m_profileY = y;
   
   return true;
}

//+------------------------------------------------------------------+
//| Resize                                                           |
//+------------------------------------------------------------------+
bool VolumeProfile::Resize(int width, int height)
{
   if (m_profileHeight == 0 || width < 1 || height < 1)
      return false;
   
   if (! m_profile.Resize(width, height))
      return false;
   
   m_profileWidth  = width;
   m_profileHeight = height;
   m_isUpdate      = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Volume distance                                                  |
//+------------------------------------------------------------------+
bool VolumeProfile::VolumeDistance(int distance)
{
   if (distance < 0)
      return false;
   if (m_volumeDistance == distance)
      return true;
   
   if (distance > 0)
   {
      int width = m_isVertical ? m_profileHeight : m_profileWidth;
      if (width < (distance+2))
         return false;
      
      int volumeCnt = ArraySize(m_volumeData);
      if (volumeCnt > 2 && width < (((volumeCnt-1)*distance)+volumeCnt))
         return false;
   }
   
   m_volumeDistance = distance;
   m_isUpdate       = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Update                                                           |
//+------------------------------------------------------------------+
bool VolumeProfile::Update()
{
   m_profile.Erase(m_profileBg);
   
   //------
   // code
   //------
   
   return true;
}

//+------------------------------------------------------------------+
//| Redraw                                                           |
//+------------------------------------------------------------------+
bool VolumeProfile::Redraw()
{
   if (m_isUpdate)
   {
      Update();
      m_isUpdate = false;
   }
   
   m_profile.Update();
   
   return true;
}

//+------------------------------------------------------------------+
