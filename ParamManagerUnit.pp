unit ParamManagerUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type

  {$M+}

  { TValue }

  TValue = class(TObject)
  public
    constructor Create; virtual;
    procedure Update(constref x: AnsiString); virtual;

  end;
  TValueClass = class of TValue;

  { TIntValue }

  TIntValue = class(TValue)
  protected
    FValue: Int64;

  public
    property Value: Int64 read FValue;

    constructor Create; override;
    procedure Update(constref x: AnsiString); override;

  end;

  { TStringValue }

  TStringValue = class(TValue)
  protected
    FValue: AnsiString;

  public
    property Value: AnsiString read FValue;

    constructor Create; override;
    procedure Update(constref x: AnsiString); override;

  end;

  { TExtendedValue }

  TExtendedValue = class(TValue)
  protected
    FValue: Extended;

  public
    property Value: Extended read FValue;

    constructor Create; override;
    procedure Update(constref x: AnsiString); override;

  end;

  { TBooleanValue }

  TBooleanValue = class(TValue)
  protected
    FValue: Boolean;

  public
    property Value: Boolean read FValue;

    constructor Create; override;
    procedure Update(constref x: AnsiString); override;

  end;


// As its input, it gets a comma separated String where each part is in form of
// `Name=Value`. Name is a string, like "Start", "UserInfo.Username", "Date.YYYY".
// This function initializes the appropriate field (field of subfield, etc) with
// the given Value.
// Please have a look at Examples to find more.
function InitAndParse(constref ParamStr: AnsiString; Param: TValue): Boolean;
// Instead of accepting a ParamStr, this function makes one by joining ParamStrs
// with ",".
function InitFromParameters(Param: TValue): Boolean;

implementation

uses
  TypInfo, fgl;

type

  { EInvalidValueClass }

  EInvalidValueClass = class(Exception)
  public
    constructor Create(constref AClassName: AnsiString);

  end;

{ EInvalidValueClass }

constructor EInvalidValueClass.Create(constref AClassName: AnsiString);
begin
  inherited Create(Format('Invalid Value ClassName %s', [AClassName]));

end;


{ TValue }

constructor TValue.Create;
begin
  inherited Create;

end;

procedure TValue.Update(constref x: AnsiString);
begin

end;


{ TIntValue }

constructor TIntValue.Create;
begin
  inherited Create;

  FValue := 0;

end;

procedure TIntValue.Update(constref x: AnsiString);
begin
  FValue := StrToInt64(x);

end;

{ TExtendedValue }

constructor TExtendedValue.Create;
begin
  inherited Create;

  FValue := 0.0;

end;

procedure TExtendedValue.Update(constref x: AnsiString);
begin
  FValue := StrToFloat(x);

end;

{ TBooleanValue }

constructor TBooleanValue.Create;
begin
  inherited Create;
  FValue := False;

end;

procedure TBooleanValue.Update(constref x: AnsiString);
begin
  FValue := StrToBool(x);

end;

{ TStringValue }

constructor TStringValue.Create;
begin
  inherited Create;

  FValue := '';

end;

procedure TStringValue.Update(constref x: AnsiString);
begin
  FValue := x;

end;


// The current implementation has certain short-commings.
// 1) It uses ',' as a separator, and will break if ',' is part of a string value.
// 2) It does not support more succint ParamStr in the form of
//       A.B.C:{x=1,y=2}
//generic function InitAndParse<TParam>(constref ParamStr: AnsiString): TParam;
function InitAndParse(constref ParamStr: AnsiString; Param: TValue): Boolean;
type
  TStringStringMap = specialize TFPGMap<AnsiString, AnsiString>;

var
  NameValueMap: TStringStringMap;

  procedure Process(vft: PVmtFieldTable; Obj: TValue; CurrentName: AnsiString);
  var
    vfe: PVmtFieldEntry;
    i: SizeInt;
    Name, StrValue: AnsiString;
    ChildObj: TValue;
    FieldClass: TClass;
    ChildTClass: TValueClass;

  begin
    if vft = nil then
    begin
      if not (Obj is TValue) then
      begin
        WriteLn('Invalid Setup');
        Halt(1);
      end;


    end;

    // Writeln(vft^.Count, ' field(s) with ', vft^.ClassTab^.Count, ' type(s)');
    for i := 0 to vft^.Count - 1 do
    begin
       vfe := vft^.Field[i];
       // Writeln(i, ' -> ', vfe^.Name, ' @ ', vfe^.FieldOffset, ' of type ', vft^.ClassTab^.ClassRef[vfe^.TypeIndex - 1]^.ClassName);

       FieldClass :=  vft^.ClassTab^.ClassRef[vfe^.TypeIndex - 1]^;
       if not FieldClass.InheritsFrom(TValue) then
         raise EInvalidValueClass.Create(FieldClass.ClassName);

       ChildObj := TValue(Obj.FieldAddress(vfe^.Name)^);
       if ChildObj = nil then
       begin
         ChildTClass := TValueClass(FieldClass);
         ChildObj := ChildTClass.Create;
         TObject(Obj.FieldAddress(vfe^.Name)^) := ChildObj;
       end;

       if PVMT(ChildTClass)^.vFieldTable = nil then
       begin
         Name := CurrentName + '.' + LowerCase(vfe^.Name);

         StrValue := '';
         if NameValueMap.TryGetData(Name, StrValue) then
         begin
           ChildObj.Update(StrValue);

         end;

         Continue;
       end;
       Process(
         PVmtFieldTable(PVMT(ChildTClass)^.vFieldTable),
         ChildObj,
         CurrentName + '.' + LowerCase(vfe^.Name)
       );

     end;

  end;

var
  NameValues: TStringList;
  NameValue: AnsiString;
  AList: TStringList;
  Name, Value: AnsiString;

begin
  NameValueMap := TStringStringMap.Create;
  NameValues := TStringList.Create;
  NameValues.Delimiter := ',';
  NameValues.DelimitedText := ParamStr;
  for NameValue in NameValues do
  begin
    AList := TStringList.Create;
    AList.Delimiter := '=';
    AList.DelimitedText := NameValue;
    Value := AList[AList.Count - 1];
    AList.Free;
    Name := NameValue;
    Delete(Name, Length(Name) - Length(Value), 1 + Length(Value));

    // WriteLn('NameValue: ', NameValue, ' Name: ', Name, ' Value: ', Value);
    NameValueMap.Add(LowerCase('.' + Name), Value);
  end;
  NameValues.Free;

  // Param := TParam.Create;

  Process(PVmtFieldTable(PVMT(Param.ClassType)^.vFieldTable), Param, '');

  NameValueMap.Free;

end;

function InitFromParameters(Param: TValue): Boolean;
var
  AllParamStr: AnsiString;
  i: Integer;

begin
  AllParamStr := '';

  for i := 1 to ParamCount do
    AllParamStr += ParamStr(i);

  Result := InitAndParse(AllParamStr, Param);

end;

end.

