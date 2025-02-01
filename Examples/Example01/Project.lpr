program Project;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, ParamManagerUnit, sysutils
  { you can add units after this };

type

  {$M+}

  { TRange }

  TRange = class(TValue)
  published
    Start: TIntValue;
    Finish: TIntValue;

  public
    destructor Destroy; override;

  end;

  { TPair }

  TPair = class(TValue)
  published
    First: TExtendedValue;
    Second: TBooleanValue;

  public
    destructor Destroy; override;

  end;

  { TParam }

  // All the Fields that we want to be assignable using InitAndParse must be
  // defined as "published" and inherit from TValue.
  TParam = class(TValue)
  published
    Range: TRange;
    Int1: TIntValue;
    Name: TStringValue;
    Pair: TPair;

  public
    destructor Destroy; override;

  end;

var
  Param1: TParam;

destructor TRange.Destroy;
begin
  Self.Start.Free;
  Self.Finish.Free;

  inherited Destroy;
end;

{ TPair }

destructor TPair.Destroy;
begin
  Self.First.Free;
  Self.Second.Free;

  inherited Destroy;
end;

{ TParam }

destructor TParam.Destroy;
begin
  inherited Create;

end;

begin

  Param1 := TParam.Create;
  InitAndParse('Int1=123,Name=NoName', Param1);
  WriteLn(Format('Int1: %d Name: "%s" Range: (%d, %d)  Pair:(%0.4f, %s)',
    [Param1.Int1.Value, Param1.Name.Value, Param1.Range.Start.Value,
    Param1.Range.Finish.Value,
    Param1.Pair.First.Value, BoolToStr(Param1.Pair.Second.Value)])
    );
  Param1.Free;


  Param1 := TParam.Create;
  InitAndParse('Int1=123,Range.Start=23,pair.Second=True', Param1);
  WriteLn(Format('Int1: %d Name: %s Range:(%d, %d) Pair:(%0.4f, %s)',
    [Param1.Int1.Value, Param1.Name.Value, Param1.Range.Start.Value,
    Param1.Range.Finish.Value,
    Param1.Pair.First.Value, BoolToStr(Param1.Pair.Second.Value)])
  );
  Param1.Free;

  Param1 := TParam.Create;
  Param1.Name := TStringValue.Create;
  Param1.Name.Update('MyName');
  InitAndParse('Pair.Second=123,Range.Start=23,pair.Second=True', Param1);
  WriteLn(Format('Int1: %d Name: %s Range:(%d, %d) Pair:(%0.4f, %s)',
    [Param1.Int1.Value, Param1.Name.Value, Param1.Range.Start.Value,
    Param1.Range.Finish.Value,
    Param1.Pair.First.Value, BoolToStr(Param1.Pair.Second.Value)])
  );
  Param1.Free;

end.

