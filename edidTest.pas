program edidTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, EdidTypes;


var
  acerBuf : string;
  p : PEDIDRec;
  m : TEDIDMan;
  i : integer;
begin
  // 0b100

  acerBuf :=
    #$00#$ff#$ff#$ff#$ff#$ff#$ff#$00
   +#$04#$72#$82#$02#$dd#$04#$10#$20
   +#$01#$16#$01#$03#$68#$33#$1d#$78
   +#$ae#$77#$c5#$a3#$54#$4f#$9f#$27
   +#$11#$50#$54#$b3#$0c#$00#$71#$4f
   +#$81#$80#$81#$00#$95#$00#$d1#$c0
   +#$01#$01#$01#$01#$01#$01#$02#$3a
   +#$80#$18#$71#$38#$2d#$40#$58#$2c
   +#$45#$00#$fd#$1e#$11#$00#$00#$1e
   +#$00#$00#$00#$fd#$00#$37#$4b#$1e
   +#$50#$11#$00#$0a#$20#$20#$20#$20
   +#$20#$20#$00#$00#$00#$fc#$00#$53
   +#$32#$33#$30#$48#$4c#$0a#$20#$20
   +#$20#$20#$20#$20#$00#$00#$00#$ff
   +#$00#$4c#$54#$53#$30#$52#$30#$32
   +#$36#$32#$34#$30#$30#$0a#$00#$f5;

  p:=@acerBuf[1];
  writeln(p^.ManId.let1,' ', p^.ManId.let2,' ', p^.ManId.let3);
  writeln('descr = ', sizeof(TEDIDDescr),' =',sizeof(TEDIDDisplayDescr),' ',sizeof(TEDIDRec));
  writeln(EditManToStr(p^.ManId));
  m.res:=1;
  writeln(m.w);

  writeln('product code:  ', p^.ProdCode);
  writeln('Serial Number: ', p^.SerNum,' ',IntToHex(p^.SerNum, 8) );
  writeln('Manf Week:     ', p^.ManWeek);
  writeln('Manf Year:     ', p^.ManYear);
  writeln('Edid Version:  ', p^.EdidVer,'.',p^.EdidRev);

  writeln(p^.VideoInp.isDigital);
  writeln('horz:  ', p^.SzH);
  writeln('vert:  ', p^.SzV);

  //writeln( sizeof(TEDIDSupportedTiming));

  for i:=0 to length(p^.descr)-1 do begin
    if (p^.descr[i].disp.zero = 0) then begin
      case p^.descr[i].disp.descrType of
        DISPDESCR_TEXT:
          writeln('text:      ',p^.descr[i].disp.text);
        DISPDESCR_DISPNAME:
          writeln('display:   ', p^.descr[i].disp.displayText);
        DISPDESCR_SERIALNUM:
          writeln('serialNum: ',p^.descr[i].disp.serialNum);
      else
        writeln(IntToHeX(p^.descr[i].disp.descrType,2))
      end;
    end else
      writeln(p^.descr[i].disp.zero);
  end;
  writeln('extensions: ', p^.extNum);
  writeln(length(acerBuf));
  writeln(Ofs(p^.extNum)-Ofs(p^));
  writeln(Ofs(p^.checkSum)-Ofs(p^));
end.

