unit UColumn;

interface

uses
  UFaseSos;

type

  TCubeCol = class
     Rashodi: record            //����/���
       F: double;  // ������� ����
       W: double;  // ����� ����
       V: double;  // ������� ����� �� ����
       L: double;  // ������ ����� � ���
       N: double;  // ���������� �������� � ����
     end;
     Teplota: record
       Q_F: double;  // ������� �������
       Q_W: double;  // ������� ����� ����
       Q_V: double;  // ������� ������� ����� �� ����
       Q_L: double;  // ������� ������ ����� � ���
       Q_N: double;  // ������� ���������� �������� � ����

       Cp_F: double;  // ������������ �������
       Cp_W: double;  // ������������ ����� ����
       Cp_V: double;  // ������������ ������� ����� �� ����
       Cp_L: double;  // ������������ ������ ����� � ���
       Cp_N: double;  // ������������ ���������� �������� � ����

       T_F: double;  // ����������� �������
       T_W: double;  // ����������� ����� ����
       T_V: double;  // ����������� ������� ����� �� ����
       T_L: double;  // ����������� ������ ����� � ���
     end;
     Sostavi: record              //����/����
       zF: TArrOfDouble;  // �������
       xW: TArrOfDouble;  // ����� ����
       yV: TArrOfDouble;  // ������� ����� �� ����
       xL: TArrOfDouble;  // ������ ����� � ���
       zN: TArrOfDouble;  // ���������� �������� � ����
     end;
     Geometry: record     //�
       Diam: double;  // ������� ����
       High: double;  // ������ ����

     end;
     LevelCurrent: double;  // ������� ������� � ����  %
     LevelUst: double;  // ������� ������� � ����       %
     LevelK: double;  // ����������� ������������������

     T: double;  // ����������� � ����     �
     P: double;  // �������� � ����        ��
     dt: double;  // ��� �� �������        ���

     procedure SetSostavi(
       zF: TArrOfDouble;  // �������
       xW: TArrOfDouble;  // ����� ����
       yV: TArrOfDouble;  // ������� ����� �� ����
       xL: TArrOfDouble;  // ������ ����� � ���
       zN: TArrOfDouble);
     procedure SetRashodi(
       F: double;  // �������
       W: double;  // ����� ����
       V: double;  // ������� ����� �� ����
       L: double;  // ������ ����� � ���
       N: double  // ���������� �������� � ����
       );
     procedure SetGeometry(
        Diam: double;  // ������� ����
        High: double  // ������ ����
      );

     procedure SetAutomat(
        LevelUst: double;  // ������� ������� � ����       %
        LevelK: double;  // ����������� ������������������
        dt: double       // ��� ��������������
     );
     procedure SetTechParam(
        _T: double;  // ����������� � ����     �
        _P: double;  // �������� � ����        ��
        T_F: double;  // ����������� �������
        T_W: double;  // ����������� ����� ����
        T_V: double;  // ����������� ������� ����� �� ����
        T_L: double  // ����������� ������ ����� � ���
     );

     procedure BalanceMaterial; //������ ������������� �������
     procedure CalcLevel;     // ������ ������ ��������
     function getPl: double;  // ��������� �������� �������� � ����
     procedure RecalcVapour; // ����������� ������ ���� �� ����������
     procedure ExecuteAp;  // ���������� ������
     procedure BalanceTeplot; // ������ ��������� �������


  end;

  TTarCol = class

  end;

implementation

{ TCubeCol }

procedure TCubeCol.BalanceMaterial;
var
  i: integer;
  N_old: double;
  FazeSost:TFazeSost;
begin
  N_old:=Rashodi.N;
  //�������� ����� ��������
  with Rashodi do
    N:=N+(F-W+L-V)*dt;
  // �������� �������� ������
  with Sostavi do
  begin
    for I := 0 to Length(zN)-1 do
    begin
      with Rashodi do
        zN[i]:=(zN[i]*N_old+(zF[i]*F-
                  xW[i]*W+xL[i]*L-yV[i]*V)*dt)/N;

    end;
  end;
  //�������� ���������� �������� � ���� � �� ������� �� ����������
  FazeSost:=TFazeSost.Create;
  FazeSost.Calculation(T, P, Sostavi.zN, Rashodi.N, Rashodi.W, Rashodi.V, Sostavi.xW, Sostavi.yV);
  FazeSost.Free;

  //�������� ������
  BalanceTeplot;

end;

procedure TCubeCol.BalanceTeplot;
var
  TermoPak:TTermoPak;
  Ttek: double;
begin
  TermoPak:=TTermoPak.Create;
  with Teplota do
  begin
    T:=T+273.15;
    T_F:=T_F+273.15;
    T_L:=T_l+273.15;
    T_W:=T_W+273.15;
    T_V:=T_V+273.15;
    repeat
      Ttek:=T;
      Cp_F:=TermoPak.GetCp(Sostavi.zF,T_F);
      Cp_L:=TermoPak.GetCp(Sostavi.xL,T_L);
      Cp_W:=TermoPak.GetCp(Sostavi.xW,T_W);
      Cp_V:=TermoPak.GetCp(Sostavi.yV,T_V);
      Cp_N:=TermoPak.GetCp(Sostavi.zN, T);

      Q_N:=Rashodi.N*T*Cp_N;
      Q_F:=Rashodi.F*T_F*Cp_F;
      Q_L:=Rashodi.L*T_L*Cp_L;
      Q_W:=Rashodi.W*T_W*Cp_W;
      Q_V:=Rashodi.V*T_V*Cp_V;
      T:=(Q_N+(Q_F+Q_L-Q_W-Q_V)*dt)/(Rashodi.N*Cp_N);
      T_W:=T;
      T_V:=T;
    until abs(Ttek-T)<0.01;
  end;
  TermoPak.Free;
end;

procedure TCubeCol.CalcLevel;
var
  Vc: double; // ����� ����
  Vzh: double; // ����� �������� � ����
begin
  with Geometry do
    Vc:=High*3.14*Diam*Diam/4;

  // ��� ���� ����� ��������, �.�. ����� ��������� �������� ���������
  Vzh:=Rashodi.N/getPl;
  LevelCurrent:=Vzh/Vc*100; //� %

end;

procedure TCubeCol.ExecuteAp;
begin
  BalanceMaterial;
  CalcLevel;
  RecalcVapour;
end;

function TCubeCol.getPl: double;
begin
  result:=1;
end;

procedure TCubeCol.RecalcVapour;
begin
  with Rashodi do
  begin
    W:=F-V+L;
    W:=W*(1-LevelK*(LevelUst-LevelCurrent)/LevelUst);

    if W<0 then W:=0;

  end;
end;

procedure TCubeCol.SetAutomat(LevelUst, LevelK, dt: double);
begin
  self.LevelUst:=LevelUst;
  self.LevelK:=LevelK;
  self.dt:=dt;
end;

procedure TCubeCol.SetGeometry(Diam, High: double);
begin
  self.Geometry.Diam:=Diam;
  self.Geometry.High:=High;
end;

procedure TCubeCol.SetRashodi(F, W, V, L, N: double);
begin
  self.Rashodi.F:=F;
  self.Rashodi.W:=W;
  self.Rashodi.V:=V;
  self.Rashodi.L:=L;
  self.Rashodi.N:=N;

end;

procedure TCubeCol.SetSostavi(zF, xW, yV, xL, zN: TArrOfDouble);
var
  i: integer;
begin
  SetLength(self.Sostavi.zF, Length(zF));
  SetLength(self.Sostavi.xW, Length(xW));
  SetLength(self.Sostavi.yV, Length(yV));
  SetLength(self.Sostavi.xL, Length(xL));
  SetLength(self.Sostavi.zN, Length(zN));

  for I := 0 to Length(zF)-1 do
  begin
    self.Sostavi.zF[i]:=zF[i];
    self.Sostavi.xW[i]:=xW[i];
    self.Sostavi.yV[i]:=yV[i];
    self.Sostavi.xL[i]:=xL[i];
    self.Sostavi.zN[i]:=zN[i];
  end;

end;

procedure TCubeCol.SetTechParam(_T, _P: double; T_F: double;  // ����������� �������
        T_W: double;  // ����������� ����� ����
        T_V: double;  // ����������� ������� ����� �� ����
        T_L: double  // ����������� ������ ����� � ���);
        );
begin
  T:=_T;
  P:=_P;
  Self.Teplota.T_F:=T_F;
  Self.Teplota.T_W:=T_W;
  Self.Teplota.T_V:=T_V;
  Self.Teplota.T_L:=T_L;

end;

end.
