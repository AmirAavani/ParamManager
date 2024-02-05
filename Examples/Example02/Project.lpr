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
    First: TIntValue;
    Second: TIntValue;

  public
    destructor Destroy; override;

  end;

  { TParam }

  // All the Fields that we want to be assignable using InitAndParse must be
  // defined as "published" and inherit from TValue.
  TParam = class(TValue)
  published
    Range: TRange;
    Modulo: TIntValue;
    Verbose: TBooleanValue;

  public
    destructor Destroy; override;

  end;

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
  Range.Free;
  Modulo.Free;
  Verbose.Free;

  inherited Create;

end;

var
  Param: TParam;
  i: Integer;
  Count: Integer;

begin
  Param := TParam.Create;
  InitAndParse('Range.Start=-1,Range.Finish=128,Modulo=2,Verbose=True', Param);
  WriteLn('Param.Modulo: ', Param.Modulo.Value);
  InitFromParameters(Param);

  Count := 0;
  for i := Param.Range.Start.Value to Param.Range.Finish.Value do
    if i mod Param.Modulo.Value = 0 then
    begin	    
      Inc(Count);
      if Param.Verbose.Value then
      begin
	WriteLn(i);
      end;

    end;
  WriteLn(Format('There are %d integers in [%d, %d] that are divisible by %d', [Count, Param.Range.Start.Value, Param.Range.Finish.Value, Param.Modulo.Value]));
  Param.Free;
end.

