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
      bool              m_isDrawBack;
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
      int               m_volumeTotal;
      int               m_volumeWidth;
      int               m_volumeHeight;
      
   private:
      void              SetDefaultBg() { m_isUpdate = true; m_profileBg = ColorToARGB((color)ChartGetInteger(m_chartId, CHART_COLOR_BACKGROUND, m_subWin), 0); }
      void              SetProfileSize(int width, int height);
      void              DrawVolume(const int i, const int c1, const int c2);
      //---
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
      bool              DrawBack()                   { return m_isDrawBack;                          }
      void              DrawBack(bool isDrawBack)    { m_isUpdate = true; m_isDrawBack = isDrawBack; }
      int               VolumeDistance()             { return m_volumeDistance;                      }
      bool              VolumeDistance(int distance);
      //---
      bool              VolumeSet(const VolumeProfileData &volumeData[]);
      int               VolumeGet(VolumeProfileData &volumeData[]);
      bool              VolumeUpdate(int index, double volumeInPercent = NULL, uint volumeClr = NULL);
      bool              VolumeRemove(int index);
      void              VolumeDelete();
      int               VolumeTotal() { return m_volumeTotal; }
};

int VolumeProfile::s_nameSuffix = 0;

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
VolumeProfile::VolumeProfile(): m_profileHeight(0)
{
   m_isUpdate       = false;
   m_isVertical     = true;
   m_isDrawBack     = false;
   m_volumeDistance = 1;
   m_volumeTotal    = 0;
   m_volumeWidth    = 0;
   m_volumeHeight   = 0;
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
   
   m_profileTime  = time;
   m_profilePrice = price;
   m_subWin       = subWin;
   
   SetProfileSize(width, height);
   
   if (chartID > 0)
      m_chartId = chartID;
   else
      m_chartId = ChartID();
      
   if (! m_profile.CreateBitmap(m_chartId, m_subWin, GenerateName(), time, price, width, height, COLOR_FORMAT_ARGB_RAW))
      return false;
   
   SetDefaultBg();
   
   return true;
}

//+------------------------------------------------------------------+
//| Create by coordinates                                            |
//+------------------------------------------------------------------+
bool VolumeProfile::Create(int x, int y, int width, int height, long chartID = 0, int subWin = 0)
{
   if (m_profileHeight != 0 || x < 0 || y < 0 || width < 1 || height < 1)
      return false;
   
   m_profileX = x;
   m_profileY = y;
   m_subWin   = subWin;
   
   SetProfileSize(width, height);
   
   if (chartID > 0)
      m_chartId = chartID;
   else
      m_chartId = ChartID();
   
   if (! m_profile.CreateBitmapLabel(m_chartId, m_subWin, GenerateName(), x, y, width, height, COLOR_FORMAT_ARGB_RAW))
      return false;
   
   SetDefaultBg();
   
   return true;
}

//+------------------------------------------------------------------+
//| Set Profile size                                                 |
//+------------------------------------------------------------------+
void VolumeProfile::SetProfileSize(int width, int height)
{
   m_profileWidth  = width;
   m_profileHeight = height;
   
   if (m_isVertical)
   {
      m_volumeWidth  = width;
      m_volumeHeight = height;
   }
   else
   {
      m_volumeWidth  = height;
      m_volumeHeight = width;
   }
}

//+------------------------------------------------------------------+
//| Move profile by time and price                                   |
//+------------------------------------------------------------------+
bool VolumeProfile::Move(datetime time, double price)
{
   if (m_profileHeight == 0 || m_profileTime == 0 || time < 1 || price <= 0)
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
   if (m_profileHeight == 0 || m_profileTime != 0 || x < 0 || y < 0)
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
   
   SetProfileSize(width, height);
   
   m_isUpdate = true;
   
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
      if (m_volumeHeight < (distance+2))
         return false;
      
      int volumeCnt = ArraySize(m_volumeData);
      if (volumeCnt > 2 && m_volumeHeight < (((volumeCnt-1)*distance)+volumeCnt))
         return false;
   }
   
   m_volumeDistance = distance;
   m_isUpdate       = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Set volume                                                       |
//+------------------------------------------------------------------+
bool VolumeProfile::VolumeSet(const VolumeProfileData &volumeData[])
{
   int arrSize = ArraySize(volumeData);
   
   if (arrSize == 0)
   {
      m_volumeTotal = 0;
      ArrayFree(m_volumeData);
   }
   else
   {
      if (arrSize != m_volumeTotal && ArrayResize(m_volumeData, arrSize) == -1)
         return false;
      
      m_volumeTotal = ArrayCopy(m_volumeData, volumeData);
   }
   
   m_isUpdate = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get volume                                                       |
//| -------------                                                    |
//| Return ERROR: -1                                                 |
//+------------------------------------------------------------------+
int VolumeProfile::VolumeGet(VolumeProfileData &volumeData[])
{
   if (m_volumeTotal == 0)
   {
      ArrayFree(volumeData);
      return 0;
   }
   
   if (ArraySize(volumeData) != m_volumeTotal && ArrayResize(volumeData, m_volumeTotal) == -1)
      return -1;
   
   ArrayCopy(volumeData, m_volumeData);
   
   return m_volumeTotal;
}

//+------------------------------------------------------------------+
//| Update volume                                                    |
//+------------------------------------------------------------------+
bool VolumeProfile::VolumeUpdate(int index, double volumeInPercent, uint volumeClr)
{
   if (index > (m_volumeTotal-1))
      return false;
   
   if (volumeInPercent != NULL)
      m_volumeData[index].volumeInPercent = volumeInPercent;
   if (volumeClr != NULL)
      m_volumeData[index].volumeClr = volumeClr;
   
   m_isUpdate = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Remove volume                                                    |
//+------------------------------------------------------------------+
bool VolumeProfile::VolumeRemove(int index)
{
   if (index > (m_volumeTotal-1))
      return false;
   
   if (! ArrayRemove(m_volumeData, index, 1))
      return false;
   
   m_volumeTotal = ArraySize(m_volumeData);
   m_isUpdate = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Delete volume                                                    |
//+------------------------------------------------------------------+
void VolumeProfile::VolumeDelete()
{
   ArrayFree(m_volumeData);
   m_volumeTotal = 0;
   m_isUpdate = true;
}

//+------------------------------------------------------------------+
//| Draw volume                                                      |
//+------------------------------------------------------------------+
void VolumeProfile::DrawVolume(const int i, const int c1, const int c2)
{
   if (m_isVertical)
   {
      if (m_isDrawBack)
         m_profile.FillRectangle(m_volumeWidth-int(m_volumeWidth*m_volumeData[i].volumeInPercent/100), c1, m_volumeWidth, c2, m_volumeData[i].volumeClr);
      else
         m_profile.FillRectangle(0, c1, int(m_volumeWidth*m_volumeData[i].volumeInPercent/100), c2, m_volumeData[i].volumeClr);
   }
   else
   {
      if (m_isDrawBack)
         m_profile.FillRectangle(c1, 0, c2, int(m_volumeWidth*m_volumeData[i].volumeInPercent/100), m_volumeData[i].volumeClr);
      else
         m_profile.FillRectangle(c1, m_volumeWidth-int(m_volumeWidth*m_volumeData[i].volumeInPercent/100), c2, m_volumeWidth, m_volumeData[i].volumeClr);
   }
}

//+------------------------------------------------------------------+
//| Update                                                           |
//+------------------------------------------------------------------+
bool VolumeProfile::Update()
{
   m_profile.Erase(m_profileBg);
   
   if (m_volumeTotal == 0)
      return true;
   if (m_volumeDistance >= m_volumeHeight)
      return false;
   
   double volumeStep;
   
   if (m_volumeDistance > 0)
   {
      int volumeHeight = m_volumeHeight-(m_volumeDistance*(m_volumeTotal-1));
      if (volumeHeight < m_volumeTotal)
         return false;
      
      volumeStep = double(volumeHeight) / double(m_volumeTotal);
   }
   else
      volumeStep = double(m_volumeHeight) / double(m_volumeTotal);
   
   int    stepInt       = (int)MathFloor(volumeStep);
   double stepRemainder = volumeStep-stepInt;
   double srPlus        = 0.0;
   
   if (m_volumeDistance > 0 || stepInt > 0)
   {
      int y2;
      
      for (int i=0,i2=0; i<m_volumeTotal; i++,i2+=1+m_volumeDistance)
      {
         y2 = i2 + stepInt - 1;
         srPlus += stepRemainder;
         
         if (srPlus >= 1)
         {
            y2 += 1;
            srPlus -= 1.0;
         }
         
         DrawVolume(i, i2, y2);
         i2 = y2;
      }
   }
   else
   {
      for (int i=0,i2=0; i<m_volumeTotal; i++)
      {
         srPlus += stepRemainder;
         if (srPlus >= 1)
         {
            i2++;
            srPlus -= 1.0;
         }
         
         DrawVolume(i, i2, i2);
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Redraw                                                           |
//+------------------------------------------------------------------+
bool VolumeProfile::Redraw()
{
   if (m_isUpdate)
   {
      if (! Update())
         return false;
      
      m_isUpdate = false;
   }
   
   m_profile.Update();
   
   return true;
}

//+------------------------------------------------------------------+
