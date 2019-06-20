unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs,
  VCLTee.Chart, UFaseSos, Vcl.Grids, Math, UColumn;



type
  TForm1 = class(TForm)
    ShCube: TShape;
    ShLevel: TShape;
    Button1: TButton;
    Timer1: TTimer;
    EdF: TEdit;
    Label1: TLabel;
    EdV: TEdit;
    Label2: TLabel;
    EdL: TEdit;
    Label3: TLabel;
    EdN: TEdit;
    Label4: TLabel;
    EdW: TEdit;
    Label5: TLabel;
    LabProc: TLabel;
    Chart1: TChart;
    Series1: TLineSeries;
    EdUst: TEdit;
    Label6: TLabel;
    EdT: TEdit;
    Label7: TLabel;
    EdP: TEdit;
    Label8: TLabel;
    StringGrid1: TStringGrid;
    Label9: TLabel;
    EdT_F: TEdit;
    Label10: TLabel;
    EdT_W: TEdit;
    Label11: TLabel;
    EdT_L: TEdit;
    Label12: TLabel;
    EdT_V: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  CubeCol: TCubeCol;
  n: integer;
implementation

{$R *.dfm}




procedure TForm1.Button1Click(Sender: TObject);
var
  zF: TArrOfDouble;  // питание
  xW: TArrOfDouble;  // отбор куба
  yV: TArrOfDouble;  // паровой поток из куба
  xL: TArrOfDouble;  // жидкий поток в куб
  zN: TArrOfDouble;  // количество вещества в кубе
  i: integer;
begin
  SetLength(zF, 39);
  SetLength(xW, 39);
  SetLength(yV, 39);
  SetLength(xL, 39);
  SetLength(zN, 39);
  for I := 0 to 38 do
  begin
    zF[i]:=StrToFloat(FSosAlkConst[i+1,2]);
    xW[i]:=StrToFloat(FSosAlkConst[i+1,2]);
    yV[i]:=StrToFloat(FSosAlkConst[i+1,2]);
    xL[i]:=StrToFloat(FSosAlkConst[i+1,2]);
    zN[i]:=StrToFloat(FSosAlkConst[i+1,2]);
  end;

  CubeCol:= TCubeCol.Create;
  CubeCol.SetSostavi(zF, xW, yV, xL, zN);
  CubeCol.SetGeometry(6,10);
  Timer1.Enabled:=true;
  Chart1.Series[0].Clear;
  n:=0;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  i,j: integer;

  sum1, sum2, sum3: double;
begin

  CubeCol.SetAutomat(StrToFloat(EdUst.Text), 5,0.05);
  CubeCol.SetRashodi(StrToFloat(EdF.Text),StrToFloat(EdW.Text),StrToFloat(EdV.Text),StrToFloat(EdL.Text),StrToFloat(EdN.Text));
  CubeCol.SetTechParam(StrToFloat(EdT.Text), StrToFloat(EdP.Text), StrToFloat(EdT_F.Text),
                       StrToFloat(EdT_W.Text), StrToFloat(EdT_V.Text), StrToFloat(EdT_L.Text));
  CubeCol.ExecuteAp;
  EdN.Text:=FloatToStr(CubeCol.Rashodi.N);
  EdV.Text:=FloatToStr(CubeCol.Rashodi.V);
  EdW.Text:=FloatToStr(CubeCol.Rashodi.W);
  EdT.Text:=FloatToStr(CubeCol.T-273.15);
  EdT_W.Text:=FloatToStr(CubeCol.Teplota.T_W-273.15);
  EdT_V.Text:=FloatToStr(CubeCol.Teplota.T_V-273.15);

  ShLevel.Height:=trunc(ShCube.Height*CubeCol.LevelCurrent/100);
  ShLevel.Top:=ShCube.Top+ShCube.Height-ShLevel.Height;
  LabProc.Caption:=FloatToStr(roundto(CubeCol.LevelCurrent,-1));
  LabProc.Top:=ShLevel.Top-20;
  n:=n+1;
  Chart1.Series[0].AddXY(n,CubeCol.LevelCurrent);

  StringGrid1.Cells[0,0]:='Компонент';
  StringGrid1.Cells[1,0]:='В кубе';
  StringGrid1.Cells[2,0]:='Жидкость';
  StringGrid1.Cells[3,0]:='Пар';
  for I := 1 to 39 do
  begin
    StringGrid1.Cells[0,i]:= FProperConst[i,1];
  end;
  sum1:=0;
  sum2:=0;
  sum3:=0;

  //вывод составов
  for I := 0 to 39 do
  begin
    StringGrid1.Cells[1,i+1]:= FloatToStr(CubeCol.Sostavi.zN[i]);
    sum1:=sum1+CubeCol.Sostavi.zN[i];
    StringGrid1.Cells[2,i+1]:= FloatToStr(CubeCol.Sostavi.xW[i]);
    sum2:=sum2+CubeCol.Sostavi.xW[i];
    StringGrid1.Cells[3,i+1]:= FloatToStr(CubeCol.Sostavi.yV[i]);
    sum3:=sum3+CubeCol.Sostavi.yV[i];
  end;
  StringGrid1.Cells[0,40]:='Сумма';
  StringGrid1.Cells[1,40]:=FloatToStr(sum1);
  StringGrid1.Cells[2,40]:=FloatToStr(sum2);
  StringGrid1.Cells[3,40]:=FloatToStr(sum3);


end;

end.
