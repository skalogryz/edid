unit winEdidUtils;

interface

uses
  SysUtils,
  Windows, edidTypes;

// MonitorID - is expected to match "HardwareID" in registry. i.e: "MONITOR\ACR0282"
// Driver    - is matching "Driver" to match "Driver" in registry
// "MonitorID"+"Driver" is returned in "ID" by EnumDisplayDevices() for a "\\.\display1" device path
function GetIdByMonitorIdAndDriver(const MonitorId, Driver: string; var edid: TEDIDRec): Boolean;
// splits DeviceID "MONITOR\ACR0282\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001", into
// hardware ID "MONITOR\ACR0282"
// and driver "{4d36e96e-e325-11ce-bfc1-08002be10318}\0001"
function SplitDisplayDeviceId(const DeviceID: string; out monId, drv : string): Boolean;
// splits MonitorId and calls for GetIdByMonitorIdAndDriver
function GetMonitorDeviceId(const MonitorId: string; var edid: TEDIDRec): Boolean;

function FindEdid(monitor: HMONITOR): Boolean;

type
  MONITORINFO = record
    cbSize    : DWORD ;
    rcMonitor : Windows.RECT;
    rcWork    : Windows.RECT;
    dwFlags   : DWORD;
  end;
  PMONITORINFO = ^MONITORINFO;

  MONITORINFOEXA = record
    info     : MONITORINFO;
    szDevice : array [0..CCHDEVICENAME-1] of AnsiChar;
  end;
  PMONITORINFOEXA = ^MONITORINFOEXA;

const
  MONITOR_DEFAULTTONULL     = $00000000;
  MONITOR_DEFAULTTOPRIMARY  = $00000001;
  MONITOR_DEFAULTTONEAREST  = $00000002;

function GetMonitorInfoA(
  hMonitor: HMONITOR;
  lpmi : Pointer //LPMONITORINFO;
): BOOL; stdcall; external 'user32.dll';

function MonitorFromPoint( pt : Windows.POINT; dwFlags: DWORD): HMonitor; stdcall; external 'user32.dll';

type
  DISPLAY_DEVICEA = record
    cb           : DWORD;
    DeviceName   : array [0..32-1] of CHAR;
    DeviceString : array [0..128-1] of CHAR;
    StateFlags   : DWORD;
    DeviceID     : array [0..128-1] of CHAR;
    DeviceKey    : array [0..128-1] of CHAR;
  end;
  PDISPLAY_DEVICEA = ^DISPLAY_DEVICEA;

function EnumDisplayDevicesA(
  lpDevice        : LPCSTR;
  iDevNum         : DWORD;
  lpDisplayDevice : PDISPLAY_DEVICEA;
  dwFlags         : DWORD
): BOOL; stdcall; external 'user32.dll';

const
  EDD_GET_DEVICE_INTERFACE_NAME = $00000001;

implementation

function FindEdid(monitor: HMONITOR): Boolean;
var
  mi : MONITORINFOEXA;
begin
  FillChar(mi, sizeof(mi), 0);
  mi.info.cbSize := sizeof(mi);
  GetMonitorInfoA(monitor, @mi);
end;

function RegReadStr(const hk: HKey; const relativePath: string; const DefaultVal: string = ''): string;
var
  sz : integer;
  res : integer;
begin
  sz := 0;
  res := RegQueryValueEx(hk, PChar(relativePath), nil, nil, nil, @sz);
  if (res <> ERROR_SUCCESS) then begin
    Result:=DefaultVal;
    Exit;
  end;
  SetLength(Result, sz);
  if (RegQueryValueEx(hk, PChar(relativePath), nil, nil, @Result[1], @sz) <> ERROR_SUCCESS) then
    Result:=DefaultVal;

  SetLength(Result, sz-1);
  Result := Result;
end;

function RegReadEdid(const hk: HKey; const relativePath: string; var ed: TEDIDRec): Boolean;
var
  sz  : integer;
  res : integer;
  buf : array of byte;
begin
  sz := 0;
  res := RegQueryValueEx(hk, PChar(relativePath), nil, nil, nil, @sz);
  if (res <> ERROR_SUCCESS) then begin
    Result := false;
    Exit;
  end;
  Result := (sz >= sizeof(ed));
  if not Result then Exit;

  if sz = sizeof(ed) then begin
    Result := RegQueryValueEx(hk, PChar(relativePath), nil, nil, @ed, @sz) = ERROR_SUCCESS
  end else begin
    SetLength(buf, sz);
    Result := RegQueryValueEx(hk, PChar(relativePath), nil, nil, @buf[0], @sz) = ERROR_SUCCESS;
    Move(buf, ed, sizeof(ed));
  end;
end;

function MonitorDrvMatch(const Mon1, Drv1, Mon2, Drv2: string): Boolean;
begin
  Result := (Mon1 = Mon2) and (Drv1 = Drv2);
end;

function GetIdByMonitorIdAndDriver(const MonitorId, Driver: string; var edid: TEDIDRec): Boolean;
var
  keyName : string;
  dispKey : HKEY;
  di      : integer;
  nm      : DWORD;
  devKey  : HKey;
  devId   : string;
  devI    : integer;
  devnm   : DWORD;
  valKey  : HKEY;
  prmKey  : HKEY;
  m,d     : string;
begin
  Result := RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Enum\DISPLAY\', 0, KEY_READ, dispKey) = ERROR_SUCCESS;
  if not Result then Exit;
  Result := false;
  SetLength(keyName, MAX_PATH);
  SetLength(devId, MAX_PATH);
  try
    di := 0;
    nm := length(KeyName);
    while (RegEnumKeyEx(dispKey, di, PChar(keyName), @nm, nil, nil, nil, nil) = ERROR_SUCCESS) do begin
      if (RegOpenKeyEx(dispKey, PChar(keyName), 0, KEY_READ, @devKey) = ERROR_SUCCESS) then begin
        try
          devi := 0;
          devnm := MAX_PATH;
          while (RegEnumKeyExA(devKey, devi, PChar(devId), @devnm, nil, nil, nil, nil) = ERROR_SUCCESS) do begin
            if (RegOpenKeyEx(devKey, PChar(devid), 0, KEY_READ, @valKey) = ERROR_SUCCESS) then begin
              try
                m := Trim(RegReadStr(valKey, 'HardwareID'));
                d := Trim(RegReadStr(valKey, 'Driver'));
                if MonitorDrvMatch(MonitorId, Driver, m, d)
                  and (RegOpenKeyEx(valKey, 'Device Parameters', 0, KEY_READ, @prmKey) = ERROR_SUCCESS) then
                  try
                    Result := RegReadEdid(prmKey, 'EDID', edid);
                  finally
                    RegCloseKey(prmKey);
                  end;
              finally
                RegCloseKey(valKey);
              end;
            end;
            devnm := MAX_PATH;
            inc(devi);
          end;
        finally
          RegCloseKey(devKey);
        end;
      end;
      nm:=length(keyName);
      inc(di);
    end;
  finally
    RegCloseKey(dispKey);
  end;
end;

function SplitDisplayDeviceId(const DeviceID: string; out monId, drv : string): Boolean;
var
  i : integer;
  f   : integer;
begin
  i:=1;
  f :=0;
  monId := '';
  drv := '';
  for i:=1 to length(DeviceID) do begin
    if DeviceID[i]='\' then inc(f);
    if f=2 then begin
      monId := Copy(DeviceID, 1, i-1);
      drv := Copy(DeviceID, i+1, length(DeviceId));
      break;
    end;
  end;
  Result := monId <> '';
end;

function GetMonitorDeviceId(const MonitorId: string; var edid: TEDIDRec): Boolean;
var
  hrd, drv: string;
begin
  Result := SplitDisplayDeviceId (MonitorId, hrd, drv);
  if not Result then Exit;
  Result := GetIdByMonitorIdAndDriver(hrd, drv, edid);
end;

end.

