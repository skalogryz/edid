program winEdidFromReg;

uses
  Windows, SysUtils,
  Types,
  edidTypes, winEdidUtils;

procedure EnumDisplayForPath(const pth: string; const pfx: string = '');
var
  i : integer;
  dev : DISPLAY_DEVICEA;
  devmod : TDeviceMode;
  flag : integer;
  p   : PChar;
begin
  i:=0;
  FillChar(dev, sizeof(dev), 0);
  dev.cb := sizeof(dev);

  if (pth = '') then begin
    p:=nil;
    flag := 0;
  end else begin
    p := PChar(pth);
    flag := 0; // EDD_GET_DEVICE_INTERFACE_NAME
  end;

  FillChar(devmod, sizeof(devmode), 0);
  devmod.dmSize := sizeof(devmod);

  while EnumDisplayDevicesA(p, i, @dev, 0) do begin
    if dev.StateFlags <> 0 then begin
      writeln('#',i);
      writeln('  Name: ',dev.DeviceName);
      writeln('  Str:  ',dev.DeviceString);
      writeln('  ID:   ',dev.DeviceID);
      writeln('  Key:  ',dev.DeviceKey);
      writeln('  Flag: ',IntToHeX(dev.StateFlags,8));

      EnumDisplaySettings(dev.DeviceName, ENUM_CURRENT_SETTINGS, devmod);

      writeln(' bpp: ', devmod.dmBitsPerPel
        ,'; res: ',devmod.dmPelsWidth,'x',devmod.dmPelsHeight
        ,'; refresh: ',devmod.dmDisplayFrequency
        ,'; flags: ',IntToHex(devmod.dmDisplayFlags,8));

      EnumDisplayForPath(dev.DeviceName, pfx+'    ');
    end;
    inc(i);
  end;
end;

var
  ed : TEDIDRec;
  m  : HMonitor;
begin
  //EnumDisplayForPath('');
  //exit;
  //GetIdByMonitorIdAndDriver('MONITOR\ACR0282','{4d36e96e-e325-11ce-bfc1-08002be10318}\0000', ed);
  //writeln(ed.SzH,' ',ed.SzV);
  //GetIdByMonitorIdAndDriver('MONITOR\ACR0282','{4d36e96e-e325-11ce-bfc1-08002be10318}\0001', ed);
  //writeln(ed.SzH,' ',ed.SzV);
  //GetIdByMonitorIdAndDriver('MONITOR\CMN1735','{4d36e96e-e325-11ce-bfc1-08002be10318}\0002', ed);
  //writeln(ed.SzH,' ',ed.SzV);
  //p.x:=0;
  //p.y:=0;
  if GetEdidForMonitor(MonitorFromPoint( Point(0,0), MONITOR_DEFAULTTOPRIMARY), ed) then begin
    writeln(EdidManToStr( ed.ManId));
    writeln(ed.SzH,' ',ed.SzV);
  end else
    writeln('unable to find');
end.

