Offset  | Size  | Field                         | Description
---     | ---   | ---                           | ---
0       | 4     | Signature                     | Magic number signature: 0x64 0x65 0x66 0x30
4       | u2    | Specification Major Version   | Major version of the specification the assembly is compiled against
6       | u2    | Specification Minor Version   | Major version of the specification the assembly is compiled against
8       | u4    | Assembly Major Version        | Assembly major version
12      | u4    | Assembly Minor Version        | Assembly minor version
16      | u4    | Assembly Patch Version        | Assembly patch version
20      | u4    | Assembly Build Version        | Assembly build version
24      | u4    | String Heap Offset            | String heap starting offset
28      | u4    | Code Heap Offset              | Code heap starting offset
