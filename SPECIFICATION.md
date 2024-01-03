## Assembly Header

Offset  | Size  | Field                         | Description
---     | ---   | ---                           | ---
0       | 4     | Signature                     | Magic number signature, "def0" 0x64 0x65 0x66 0x30
4       | 2     | Specification Major Version   | Major version of the specification the assembly is compiled against
6       | 2     | Specification Minor Version   | Major version of the specification the assembly is compiled against
8       | 4     | Assembly Major Version        | Assembly major version
12      | 4     | Assembly Minor Version        | Assembly minor version
16      | 4     | Assembly Patch Version        | Assembly patch version
20      | 4     | Assembly Build Version        | Assembly build version

## Block Header

Offset  | Size  | Field           | Description
---     | ---   | ---             | ---
0       | 1     | Header marker   | Header start marker, "#" 0x23
1       | 4     | Block header    | Block header, any unused bytes are filled with 0x00
5       | 4     | Block data size | Size of the block data in bytes
9       | n     | Block data      | Block data

## Code Block, "code" 0x63 0x6f 0x64 0x65
