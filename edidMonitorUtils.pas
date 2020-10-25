unit edidMonitorUtils;

interface

uses
  Types,
  {$ifdef darwin}MacOSAll,{$endif}
  {$ifdef mswindows}Windows, winEdidUtils,{$endif}
  Classes, SysUtils, edidTypes
  ;

type
  TMonitor = class
  public
    Name       : string;
    Resolution : TSize;
    PhysSizeMm : TSize; // milimeters
    Frequency  : double;
    Bounds     : TRect;
  end;

function GetSysMonitors(list: TList): Boolean;

implementation

{$ifdef MSWindows}

function CallbackEnum(monitor: HMONITOR;
  Arg2: HDC;  Arg3: LPRECT; Arg4: LPARAM): BOOL; stdcall;
var
  dst     : TList;
  mi      : MONITORINFOEXA;
  wm      : TMonitor;
  monname : string;
  ed      : TEDIDRec;
  devmod  : TDEVMODEA;
begin
  dst := Tlist(Arg4);

  FillChar(mi, sizeof(mi), 0);
  mi.info.cbSize := sizeof(mi);
  if GetMonitorInfoA(monitor, @mi) then
    monname := mi.szDevice
  else
    monname := '';

  if (monname <>'') and (GetEdidForDevicePath( monname, ed)) then begin
    wm := TMonitor.Create;
    wm.bounds := mi.info.rcMonitor;
    EdidGetPhysSizeMm(ed, wm.PhysSizeMm.cx, wm.PhysSizeMm.cy);

    FillChar(devmod, sizeof(devmod), 0);
    devmod.dmSize := sizeof(devmod);
    EnumDisplaySettingsA(PChar(monname), ENUM_CURRENT_SETTINGS, devmod);
    wm.Name := EdidGetDisplayName(ed);

    wm.Resolution.cx := devmod.dmPelsWidth;
    wm.Resolution.cy := devmod.dmPelsHeight;
    wm.Frequency := devmod.dmDisplayFrequency;
    dst.Add(wm);
  end;

  Result := true;
end;


function WinEnumMonitors(list: TList): Boolean;
begin
  Result := EnumDisplayMonitors(0, nil, @CallbackEnum, LParam(list));
end;
{$endif}

{$ifdef darwin}
function CocoaEnumMonitors(list: TList): Boolean;
var
  wm  : TMonitor;
  dsp : array of CGDirectDisplayID;
  i   : integer;
  cnt : UInt32;
  sz  : CGSize;
  r   : CGRect;
  md  : CGDisplayModeRef;
begin
  Result := Assigned(list);
  if not Result then Exit;

  SetLength(dsp, 256);
  cnt := 0;
  CGGetActiveDisplayList(length(dsp), @dsp[0], cnt);
  for i:=0 to Integer(cnt)-1 do begin
    wm := TMonitor.Create;
    md := CGDisplayCopyDisplayMode(dsp[i]);
    try
      sz := CGDisplayScreenSize(dsp[i]);
      wm.PhysSizeMm.cx := Round(sz.width);
      wm.PhysSizeMm.cy := Round(sz.height);
      r := CGDisplayBounds(dsp[i]);
      wm.Bounds := Bounds( Round(r.origin.x), Round(r.origin.y),
        Round(r.size.width), Round(r.size.height));
      wm.Resolution.cx := Round(r.size.width);
      wm.Resolution.cy := Round(r.size.height);
      wm.Frequency := CGDisplayModeGetRefreshRate(md);
      if wm.Frequency = 0 then
        wm.Frequency := 60;
    finally
      CGDisplayModeRelease(md);
    end;
    list.Add(wm);
    inc(cnt);
  end;
  Result := (cnt > 0)
end;
{$endif}

function GetSysMonitors(list: TList): Boolean;
begin
{$ifdef MSWindows}
  if not Assigned(List) then begin
    Result := false;
    Exit;
  end;
  Result:=WinEnumMonitors(list);
{$else}
  {$ifdef darwin}
  Result:=CocoaEnumMonitors(list);
  {$endif}
  Result:=false;
{$endif}
end;

end.
