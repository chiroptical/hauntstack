Recording some traps I constantly fall into.

- `X:32`: X is a 32 bit integer
- `X:4/binary`: X is a 32 bit binary
- `<<16#1>>` is a hexadecimal encoded 1, one octet
  - `byte_size(<<16#1>>) =:= 1. true`
- `<<16#1:16>>` is a hexadecimal encoded 1, two octet
  - `byte_size(<<16#1:16>>) =:= 2. true`
- `<<1>>` is the binary 1, one octet
  - `<<1>> =:= 1. false`
