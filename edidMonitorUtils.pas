unit edidMonitorUtils;

interface

uses
  {$ifdef mswindows}Windows, winEdidUtils,{$endif}
  Classes, SysUtils, edidTypes
  ;

type
  TMonitor = class
  public
    Name       : string;
    Resolution : TSize;
    PhysSizeCm : TSize; // cm
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
    wm.PhysSizeCm.cx := ed.SzH;
    wm.PhysSizeCm.cy := ed.SzV;

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

function GetSysMonitors(list: TList): Boolean;
begin
{$ifdef MSWindows}
  if not Assigned(List) then begin
    Result := false;
    Exit;
  end;
  Result:=WinEnumMonitors(list);
{$else}
  Result:=false;
{$endif}
end;

end.
