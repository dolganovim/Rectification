﻿unit UFaseSos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs;


type
   TArrOfDouble = array of double;
   TFazeSost = class
      F: double;  // общий мольный расход моль/ч
      G: double;  // газовый мольный расход моль/ч
      L: double;  // жидкостный мольный расход моль/ч
      e: double;  // доля отгона мольная

      T: double;  // температура, С
      P: double;  // давление, Па
      NComp: integer; //  количество компонентов
      Kf: TArrOfDouble; //константа фазового равновесия
      Pc: TArrOfDouble; // критические давления Па
      Tc: TArrOfDouble; // критические температуры, С
      omega: TArrOfDouble; // Ацентрические факторы

      Ps: TArrOfDouble; // парциальные давления Па
      zF: TArrOfDouble;  // мольная доля компонентов в исходном потоке
      xL: TArrOfDouble;  // мольная доля компонентов в жидком потоке
      yG: TArrOfDouble;  // мольная доля компонентов в газовом потоке


      procedure Wilson;  // расчет констант равновесия по Вильсону
      function FazeCalc: integer; // расчет на фазовое состояние (одна или две фазы)0- две фазы, 1- 1 одна жидкая, 2- одна газовая
                                  // 3 - точка начала кипения, 4- точка начала росы
      procedure Rashford_Rice; // расчет мольной доли отгона
      procedure Calculation(T, P: double; zF: TArrOfDouble; N: double; var _L, _G: double; var _xL, _yG: TArrOfDouble);

      procedure SetDefaultParam; //задать дефолтные параметры
      procedure SetParam(T, P: double; zF: TArrOfDouble; N: double); // задать параметры

   end;
   TTermoPak = class

      function GetCp(zF: TArrOfDouble; T: double): double;  // теплоемкость по составу


   end;
const

  //свойства компонентов
FProperConst: array[0..39, 1..12] of string =
(('Компонент', 	'Молярная масса, г/моль', 	'Плотность, кг/м3', 	'A', 	'B', 	'C', 	'D', 	'ОЧ ИМ', 	'ОЧ ММ', 	'Pкритич.,  бар', 	'Ткритич., К', 	'ω'),
('Бутен-1', 	'56,1077003479004', 	'593,789001464844', 	'-0,715', 	'0,08436', 	'-0,00004754', 	'0,00000001066', 	'94,2963814413153', 	'76,9383346106406', 	'40,2260009765625', 	'419,450006103516', 	'0,187000006437302'),
('Бутен-2', 	'56,1077003479004', 	'625,953002929688', 	'0,105', 	'0,07054', 	'-0,00002431', 	'-0,000000000147', 	'97,4894864213387', 	'95,1420451525046', 	'41,5406005859375', 	'431,952508544922', 	'0,210565000772476'),
('Изобутен', 	'56,1077003479004', 	'592,793029785156', 	'3,834', 	'0,06698', 	'-0,00002607', 	'0,000000002173', 	'97,9884090744673', 	'83,6767247007228', 	'40,02330078125', 	'417,748010253906', 	'0,189980000257492'),
('Н(+)', 	'1,008', 	'70,811', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('Изобутан', 	'58,1240005493164', 	'561,966003417969', 	'-0,332', 	'0,09189', 	'-0,00004409', 	'0,000000006915', 	'101,780221238245', 	'98,1592347450787', 	'36,476201171875', 	'407,946008300781', 	'0,184790000319481'),
('iC4H9(+)', 	'57,1160005493164', 	'561,966003417969', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('nC4H10', 	'58,1240005493164', 	'583,223022460938', 	'2,266', 	'0,07913', 	'-0,00002647', 	'-0,000000000674', 	'93,3983206656837', 	'90,6162607636434', 	'37,966201171875', 	'425,049005126953', 	'0,20100000500679'),
('TMC5(+)', 	'113,224002258301', 	'694,955017089844', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('224TMC5', 	'114,232002258301', 	'694,955017089844', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'104,274834503888', 	'103,590176011712', 	'25,6757006835938', 	'543,810021972656', 	'0,310000002384186'),
('233TMC5', 	'114,232002258301', 	'729,041015625', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'111,858458831444', 	'101,679289269749', 	'28,198701171875', 	'573,409020996094', 	'0,28999000787735'),
('234TMC5', 	'114,232002258301', 	'721,9580078125', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'105,771602463274', 	'105,601635740095', 	'27,296201171875', 	'566,258020019531', 	'0,319990009069443'),
('ДMC6(+)', 	'113,224002258301', 	'696,671020507813', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('25ДMC6', 	'114,232002258301', 	'696,671020507813', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'55,5799835585319', 	'55,8180074626216', 	'24,8651000976563', 	'549,909020996094', 	'0,345990002155304'),
('24ДMC6', 	'114,232002258301', 	'703,263000488281', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'69,7493869073856', 	'65,573587145278', 	'25,563701171875', 	'553,37001953125', 	'0,340990006923676'),
('23ДMC6', 	'114,232002258301', 	'715,013000488281', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'77,2332267043154', 	'72,9154151538751', 	'26,283701171875', 	'563,339013671875', 	'0,340000003576279'),
('C3H6', 	'42,0806007385254', 	'520,955017089844', 	'0,886', 	'0,05602', 	'-0,00002771', 	'0,000000005266', 	'105,472248871397', 	'100,572986419138', 	'46,2041015625', 	'364,85', 	'0,148000001907349'),
('24ДMC5', 	'100,205001831055', 	'675,994018554688', 	'-11,966', 	'0,2139', 	'-0,0001519', 	'0,00000004146', 	'83,6194366643621', 	'83,5761517143037', 	'27,3678002929688', 	'519,639001464844', 	'0,307000011205673'),
('223TMC4', 	'100,205001831055', 	'693,25', 	'-5,48', 	'0,1796', 	'-0,0001056', 	'0,000000024', 	'111,858458831444', 	'101,679289269749', 	'29,536201171875', 	'531,019006347656', 	'0,259990006685257'),
('2MC6', 	'100,205001831055', 	'681,539001464844', 	'-9,408', 	'0,2064', 	'-0,0001502', 	'0,00000004386', 	'44,3043315978243', 	'40,6314865133318', 	'27,336201171875', 	'530,219018554688', 	'0,340000003576279'),
('23ДMC5', 	'100,205001831055', 	'698,046020507813', 	'-11,966', 	'0,2139', 	'-0,0001519', 	'0,00000004146', 	'90,9037074000405', 	'89,0070929809372', 	'29,0802001953125', 	'537,198022460938', 	'0,305000007152557'),
('3MC6', 	'100,205001831055', 	'690,200012207031', 	'-1,683', 	'0,1633', 	'-0,00008919', 	'0,00000001871', 	'53,8836465378945', 	'51,2922230737604', 	'28,137900390625', 	'535,1', 	'0,326990008354187'),
('I7', 	'100,205001831055', 	'701,168029785156', 	'-9,408', 	'0,2064', 	'-0,0001502', 	'0,00000004386', 	'69,1506797236312', 	'65,3724411724397', 	'28,9080004882813', 	'540,490014648438', 	'0,314000010490417'),
('I8', 	'114,232002258301', 	'716,465026855469', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'99,7845306257305', 	'93,5328773697984', 	'24,843701171875', 	'559,488000488281', 	'0,38400000333786'),
('C5H10', 	'70,1350009765625', 	'638,723022460938', 	'-0,032', 	'0,1034', 	'-0,00005534', 	'0,00000001118', 	'93,4981051963095', 	'78,0446374612511', 	'35,2869995117188', 	'464,549005126953', 	'0,232960000634193'),
('I9', 	'128,259002685547', 	'730,927001953125', 	'-2,201', 	'0,1877', 	'-0,0001051', 	'0,00000002316', 	'79,8276245005844', 	'70,4010904933966', 	'22,898701171875', 	'586,6', 	'0,416680008172989'),
('C3H8', 	'44,0970001220703', 	'506,678009033203', 	'-1,009', 	'0,07315', 	'-0,00003789', 	'0,000000007678', 	'105,472248871397', 	'100,572986419138', 	'42,5666015625', 	'369,748010253906', 	'0,152400001883507'),
('iC5H12', 	'72,1510009765625', 	'623,442016601563', 	'-2,275', 	'0,121', 	'-0,00006519', 	'0,00000001367', 	'92,7996134819294', 	'91,2196986821582', 	'33,3359008789063', 	'460,248010253906', 	'0,222240000963211'),
('23ДMC4', 	'86,1779022216797', 	'665,168029785156', 	'-3,489', 	'0,1469', 	'-0,00008063', 	'0,00000001629', 	'102,578497483251', 	'96,3489209895342', 	'31,268701171875', 	'499,830010986328', 	'0,246950000524521'),
('22ДMC4', 	'86,1779022216797', 	'652,565002441406', 	'-3,973', 	'0,1503', 	'-0,00008314', 	'0,00000001636', 	'93,1987516044323', 	'92,3260015327687', 	'31', 	'488,85', 	'0,231940001249313'),
('2MC5', 	'86,1779022216797', 	'656,507019042969', 	'-2,524', 	'0,1477', 	'-0,00008533', 	'0,00000001931', 	'73,3416300099119', 	'73,8205720316473', 	'30,1036010742188', 	'497,347009277344', 	'0,279100000858307'),
('3MC5', 	'86,1779022216797', 	'667,684020996094', 	'0,57', 	'0,1359', 	'-0,00006854', 	'0,00000001202', 	'74,3394753161692', 	'74,7257289094196', 	'31,2384008789063', 	'504,299005126953', 	'0,275000005960464'),
('iC12H25(+)', 	'169,331004516602', 	'751,14501953125', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('iC12H26', 	'170,339004516602', 	'751,14501953125', 	'-14,932', 	'0,2362', 	'-0,0001384', 	'0,00000003084', 	'49,8922653128652', 	'40,2291945676552', 	'18,2992004394531', 	'658,149011230469', 	'0,561990022659302'),
('I10', 	'142,285003662109', 	'751,544006347656', 	'-3,928', 	'0,1671', 	'-0,00009841', 	'0,00000002228', 	'59,8707183754383', 	'50,286493209569', 	'23,096201171875', 	'619,889001464844', 	'0,409990012645721'),
('I11', 	'156,313003540039', 	'742,846008300781', 	'-7,473', 	'0,1788', 	'-0,0001099', 	'0,00000002582', 	'49,8922653128652', 	'40,2291945676552', 	'19,6493005371094', 	'638,149011230469', 	'0,535000026226044'),
('C2H6', 	'30,0699005126953', 	'355,683013916016', 	'1,292', 	'0,04254', 	'-0,00001657', 	'0,000000002081', 	'106,869232300157', 	'104,595905875904', 	'48,8385009765625', 	'305,278009033203', 	'0,0986000001430511'),
('HSO4', 	'97,0720018310547', 	'1840', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('H2SO4', 	'98,0800018310547', 	'1840', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0'),
('Polymer', 	'504,969303131104', 	'1025', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0', 	'0')
);

FSosAlkConst: array [0..39, 1..2] of string = (('Наименование', 'Значение'),
('Бутен-1', '0,000209278037178949'),
('Бутен-2', '0,000359671570500376'),
('Изобутен', '0,0041878235058655'),
('Н(+)', '0'),
('Изобутан', '0,740818408089137'),
('iC4H9(+)', '0'),
('nC4H10', '0,169331690116057'),
('TMC5(+)', '0'),
('224TMC5', '0,00317314044780702'),
('233TMC5', '0,00179021220328622'),
('234TMC5', '0,00151236264248399'),
('ДMC6(+)', '0'),
('25ДMC6', '0,000500498031139314'),
('24ДMC6', '0,000416432800323763'),
('23ДMC6', '0,000348415055561567'),
('C3H6', '1,56243726649583E-05'),
('24ДMC5', '0,000595123589538013'),
('223TMC4', '0,000180936556841919'),
('2MC6', '0,000128725023644453'),
('23ДMC5', '0,000600106691536634'),
('3MC6', '0,000236847548767985'),
('I7', '0'),
('I8', '0,000230604867080974'),
('C5H10', '3,81662631408713E-11'),
('I9', '0,00133580390626511'),
('C3H8', '0,0630626505275624'),
('iC5H12', '0,00942814555334569'),
('23ДMC4', '0,000795663706303852'),
('22ДMC4', '0'),
('2MC5', '0,000224057138887738'),
('3MC5', '0,000110153215983092'),
('iC12H25(+)', '0'),
('iC12H26', '0'),
('I10', '0,000116283586722849'),
('I11', '0,00029134117734716'),
('C2H6', '0'),
('HSO4', '0'),
('H2SO4', '0'),
('Polymer', '0'));

implementation

{ TFazeSost }

procedure TFazeSost.Wilson;

var
  i: integer;
  _P, _T: extended; // Давление и температура в системе
begin
  // Инитциализация параметров
  _P:= P / 100000; // Перевод в бары
  _T:= T + 273;    // Перевод в кельвины
  // Расчет парциальных давлений и коэффициентов распределения
  SetLength(Ps, NComp);
  SetLength(Kf, NComp);

  for I := 0 to NComp-1 do
  begin
    Ps[i]:= Pc[i] * exp(5.372697 * (1 + omega[i]) * (1 - Tc[i] / _T));
    Kf[i]:= Ps[i] / _P;
  end;
end;

procedure TFazeSost.Calculation(T, P: double; zF: TArrOfDouble; N: double; var _L, _G: double; var _xL, _yG: TArrOfDouble);
var
  fc, i: integer;
begin
  SetParam(T, P, zF, N);
  Wilson;
  fc:=FazeCalc;
  case fc of
    0: Rashford_Rice;
    1: begin
         e:=0;
         for I := 0 to NComp-1 do
         begin
           xL[i]:=zF[i];
           yG[i]:=0;
         end;
       end;
    2:begin
        e:=1;
        for I := 0 to NComp-1 do
         begin
           xL[i]:=0;
           yG[i]:=zF[i];
         end;
      end;
    3: Rashford_Rice;
    4: Rashford_Rice;
  end;
  G:=F*e;
  L:=F-G;
  _L:=L;
  _G:=G;
  for I := 0 to NComp-1 do
  begin
    _xL[i]:=xL[i];
    _yG[i]:=yG[i];
  end;

end;

function TFazeSost.FazeCalc: integer;
var
  S1, S2: double;
  i: integer;
begin
  result:=-1;
  S1:=0;
  S2:=0;

  for I := 0 to NComp-1 do
    begin
      S1:=S1+zF[i]*Kf[i];
      if Kf[i]>0 then
        S2:=S2+zF[i]/Kf[i];
    end;
  if (S1>1) and (S2>1) then result:=0; // 2 фазы
  if (S1<1) then result:=1;  //жидкая
  if (S2<1) then result:=2;  //газовая
  if S1=1 then result:=3;    //точка кипения
  if S2=1 then result:=4;    //точка росы
end;

procedure TFazeSost.Rashford_Rice; // Решение уравнения Рашфорда-Райса
const
  eps = 1e-6;
var
  a, b, _e: extended;
  I: Integer;
function fn (_e: extended): extended;
var
  s: extended;
  i: integer;
begin
  s:= 0;
  for I := 0 to NComp-1 do
    if Kf[i] > 0 then
      s:= s + zF[i] * (Kf[i] - 1) / (1 + _e * (Kf[i] - 1));
  result:= s;
end;

begin
  a:= 0;
  b:= 1;
  if fn(a) * fn(b) < 0 then
    begin
      repeat
        _e:= (a + b) / 2;
        if fn(a) * fn(_e) > 0 then
          a:= _e
        else
          b:= _e;
      until abs(a - b) <= eps;
      _e:= (a + b) / 2
    end; (*e:= 0.8680;*)
  //showmessage(floattostr(e));
  for I := 0 to NComp-1 do
    begin
      xL[i]:= zF[i] / (1 + _e * (Kf[i] - 1));
      yG[i]:= Kf[i] * xL[i]
    end;
  self.e:=_e;
end;


procedure TFazeSost.SetDefaultParam;

var
  i: integer;
begin
  F:= 1000;
  G:=0;
  L:=0;
  e:=0;
  T:=45;
  P:=600000;
  NComp:=39;
  SetLength(Pc, NComp);
  SetLength(Tc, NComp);
  SetLength(omega, NComp);
  SetLength(zF, NComp);
  SetLength(xL, NComp);
  SetLength(yG, NComp);

  for i:= 0 to NComp-1 do
  begin
    Pc[i]:= StrToFloat(FProperConst[i+1,10]); // критические давления Па
    Tc[i]:= StrToFloat(FProperConst[i+1,11]); // критические температуры, С
    omega[i]:= StrToFloat(FProperConst[i+1,12]); // Ацентрические факторы

    zF[i]:= StrToFloat(FSosAlkConst[i+1,2]);  // мольная доля компонентов в исходном потоке
    xL[i]:= 0;  // мольная доля компонентов в жидком потоке
    yG[i]:= 0;  // мольная доля компонентов в газовом потоке
  end;
end;

procedure TFazeSost.SetParam(T, P: double; zF: TArrOfDouble; N: double);

var
  i: integer;
begin
  Self.F:= N;
  G:=0;
  L:=0;
  e:=0;
  Self.T:=T;
  Self.P:=P;
  NComp:=39;
  SetLength(Pc, NComp);
  SetLength(Tc, NComp);
  SetLength(omega, NComp);
  SetLength(Self.zF, NComp);
  SetLength(Self.xL, NComp);
  SetLength(Self.yG, NComp);

  for i:= 0 to NComp-1 do
  begin
    Pc[i]:= StrToFloat(FProperConst[i+1,10]); // критические давления Па
    Tc[i]:= StrToFloat(FProperConst[i+1,11]); // критические температуры, С
    omega[i]:= StrToFloat(FProperConst[i+1,12]); // Ацентрические факторы

    Self.zF[i]:= zF[i];  // мольная доля компонентов в исходном потоке
    Self.xL[i]:= 0;  // мольная доля компонентов в жидком потоке
    Self.yG[i]:= 0;  // мольная доля компонентов в газовом потоке
  end;

end;

{ TTermoPak }
{Данная функция предназначена для расчета теплоемкости в зависимости от мольных концентраций компонентов
и температуры. }
function TTermoPak.GetCp(zF: TArrOfDouble; T: double): double;
var
  i: integer;
  a,b,c,d: array of double;
  sum: double;
begin
  sum:=0;
  SetLength(a, Length(zF));
  SetLength(b, Length(zF));
  SetLength(c, Length(zF));
  SetLength(d, Length(zF));

  for i := 0 to Length(zF)-1 do
  begin
    a[i]:=StrToFloat(FProperConst[i+1, 4]);
    b[i]:=StrToFloat(FProperConst[i+1, 5]);
    c[i]:=StrToFloat(FProperConst[i+1, 6]);
    d[i]:=StrToFloat(FProperConst[i+1, 7]);
  end;

  for I := 0 to Length(zF)-1 do
  begin
    sum:=sum+zF[i]*(a[i]+b[i]*T+c[i]*T*T+d[i]*T*T*T);
  end;

  result:=sum;
end;

end.
