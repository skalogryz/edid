program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, edidMonitorUtils;

var
  l : TList;
  i : integer;
  m : TMonitor;
begin
  l := TList.Create;
  try
    GetSysMonitors(l);
    for i:=0 to l.Count-1 do begin
      m := TMonitor(l[i]);
      writeln('Res: ',m.Resolution.cx,' ',m.Resolution.cy,' '
       ,'Offset: ',m.Bounds.Left,' ',m.Bounds.Top,' '
       ,'Refreh Rate: ',m.Frequency:0:1,'hz; '
       ,'Phys Size (apx): ',m.PhysSizeCm.cx,'cm ',m.PhysSizeCm.cy,'cm');
    end;
  finally
    l.free;
  end;
end.
