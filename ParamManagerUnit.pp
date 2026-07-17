unit ParamManagerUnit;

{$mode ObjFPC}{$H+}
{$COPERATORS ON}

interface

uses
  Classes, SysUtils;

type
  {$M+}

  { TValue }

  TValue = class(TObject)
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Update(const x: AnsiString); virtual;
    function ToString: AnsiString; override;
  end;

  TValueClass = class of TValue;

  { Leaf Nodes: Simple types }

  { TIntValue }

  TIntValue = class(TValue)
  protected
    FValue: int64;
  public
    property Value: int64 read FValue;
    procedure Update(const x: AnsiString); override;
    function ToString: AnsiString; override;
  end;

  { TStringValue }

  TStringValue = class(TValue)
  protected
    FValue: AnsiString;
  public
    property Value: AnsiString read FValue;
    procedure Update(const x: AnsiString); override;
    function ToString: AnsiString; override;
  end;

  { TExtendedValue }

  TExtendedValue = class(TValue)
  protected
    FValue: extended;
  public
    property Value: extended read FValue;
    procedure Update(const x: AnsiString); override;
    function ToString: AnsiString; override;
  end;

  { TBooleanValue }

  TBooleanValue = class(TValue)
  protected
    FValue: Boolean;
  public
    property Value: Boolean read FValue;
    procedure Update(const x: AnsiString); override;
    function ToString: AnsiString; override;
  end;

{ Parsing Functions }
function InitAndParse(constref ParamStr: AnsiString; Param: TValue): Boolean;
function InitFromParameters(Param: TValue): Boolean;

implementation

uses
  { Move these here to keep the interface clean }
  TypInfo,
  Generics.Collections;

type
  TStringStringMap = specialize TDictionary<AnsiString, AnsiString>;

  { TValue }

constructor TValue.Create;
begin
  inherited Create;
end;

destructor TValue.Destroy;
var
  vft: PVmtFieldTable;
  vfe: PVmtFieldEntry;
  i: SizeInt;
  ChildObj: TValue;
begin
  { VMT walking to automatically free children }
  vft := PVmtFieldTable(PVMT(Self.ClassType)^.vFieldTable);
  if vft <> nil then
  begin
    for i := 0 to vft^.Count - 1 do
    begin
      vfe := vft^.Field[i];
      ChildObj := TValue(Self.FieldAddress(vfe^.Name)^);
      ChildObj.Free;
    end;
  end;
  inherited Destroy;
end;

procedure TValue.Update(const x: AnsiString);
begin
end;

function TValue.ToString: AnsiString;

  procedure Process(vft: PVmtFieldTable; Obj: TValue; constref Prefix: AnsiString;
  var OutStr: AnsiString);
  var
    vfe: PVmtFieldEntry;
    i: SizeInt;
    ChildObj: TValue;
    FieldClass: TClass;
  begin
    if vft = nil then Exit;
    for i := 0 to vft^.Count - 1 do
    begin
      vfe := vft^.Field[i];
      FieldClass := vft^.ClassTab^.ClassRef[vfe^.TypeIndex - 1]^;
      if not FieldClass.InheritsFrom(TValue) then Continue;

      ChildObj := TValue(Obj.FieldAddress(vfe^.Name)^);
      if ChildObj = nil then Continue;

      if PVMT(FieldClass)^.vFieldTable = nil then
      begin
        if Length(OutStr) > 0 then OutStr += ',';
        OutStr += Prefix + vfe^.Name + '=' + ChildObj.ToString;
      end
      else
        Process(PVmtFieldTable(PVMT(FieldClass)^.vFieldTable), ChildObj,
          Prefix + vfe^.Name + '.', OutStr);
    end;
  end;

begin
  Result := '';
  Process(PVmtFieldTable(PVMT(Self.ClassType)^.vFieldTable), Self, '', Result);
end;

{ Leaf Implementations }

procedure TIntValue.Update(const x: AnsiString);
begin
  FValue := StrToInt64(x);
end;

function TIntValue.ToString: AnsiString;
begin
  Result := IntToStr(FValue);
end;

procedure TExtendedValue.Update(const x: AnsiString);
begin
  FValue := StrToFloat(x);
end;

function TExtendedValue.ToString: AnsiString;
begin
  Result := FloatToStr(FValue);
end;

procedure TBooleanValue.Update(const x: AnsiString);
begin
  FValue := StrToBool(x);
end;

function TBooleanValue.ToString: AnsiString;
begin
  Result := BoolToStr(FValue);
end;

procedure TStringValue.Update(const x: AnsiString);
begin
  if (Length(x) >= 2) and (x[1] = #39) and (x[Length(x)] = #39) then
    FValue := Copy(x, 2, Length(x) - 2)
  else
    FValue := x;
end;

function TStringValue.ToString: AnsiString;
begin
  Result := FValue;
end;

{ Recursive Logic }

procedure RecursivePopulate(vft: PVmtFieldTable; Obj: TValue;
  CurrentName: AnsiString; Map: TStringStringMap);
var
  vfe: PVmtFieldEntry;
  i: SizeInt;
  FullName, StrValue: AnsiString;
  ChildObj: TValue;
  FieldClass: TClass;
begin
  if vft = nil then Exit;
  for i := 0 to vft^.Count - 1 do
  begin
    vfe := vft^.Field[i];
    FieldClass := vft^.ClassTab^.ClassRef[vfe^.TypeIndex - 1]^;
    FullName := CurrentName + '.' + LowerCase(vfe^.Name);
    ChildObj := TValue(Obj.FieldAddress(vfe^.Name)^);
    if ChildObj = nil then
    begin
      ChildObj := TValueClass(FieldClass).Create;
      TObject(Obj.FieldAddress(vfe^.Name)^) := ChildObj;
    end;
    if PVMT(FieldClass)^.vFieldTable = nil then
    begin
      if Map.TryGetValue(FullName, StrValue) then ChildObj.Update(StrValue);
    end
    else
      RecursivePopulate(PVmtFieldTable(PVMT(FieldClass)^.vFieldTable),
        ChildObj, FullName, Map);
  end;
end;

function InitAndParse(constref ParamStr: AnsiString; Param: TValue): Boolean;
var
  Map: TStringStringMap;
  Pairs: TStringList;
  S, K, V: AnsiString;
  EqPos: integer;
begin
  Map := TStringStringMap.Create;
  Pairs := TStringList.Create;
  Pairs.Delimiter := ',';
  Pairs.DelimitedText := ParamStr;
  for S in Pairs do
  begin
    EqPos := Pos('=', S);
    if EqPos > 0 then
    begin
      K := LowerCase('.' + Copy(S, 1, EqPos - 1));
      V := Copy(S, EqPos + 1, Length(S));
      Map.AddOrSetValue(K, V);
    end;
  end;
  RecursivePopulate(PVmtFieldTable(PVMT(Param.ClassType)^.vFieldTable), Param, '', Map);
  Pairs.Free;
  Map.Free;
  Result := True;
end;

function InitFromParameters(Param: TValue): Boolean;
var
  Combined: AnsiString;
  i: integer;
begin
  if ParamCount = 0 then Exit(True);
  Combined := '';
  for i := 1 to ParamCount do
  begin
    if i > 1 then Combined += ',';
    Combined += ParamStr(i);
  end;
  Result := InitAndParse(Combined, Param);
end;

end.
