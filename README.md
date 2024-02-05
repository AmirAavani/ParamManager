# ParamManager

This library allows you to load the object from string. This could be be used to
1) Parse and set config params from Run time parameters,
2) Load the data from file,
etc.

## Examples 
```
  Example1:

  Param := TParam.Create;
  InitAndParse('Int1=123,Range.Start=23,pair.Second=True', Param);
  ....
  Param.Free;


  Example02:
  Param := TParam.Create;
  InitAndParse('Int1=123,Range.Start=23,pair.Second=True', Param);
  InitFromParameters(Param);
  ...
  Param.Free;


```

