Very specific memory test
-------------------------

For a system with 32 GB total memory
Assumed at least 30 GB available!!

Manager:
  must be executed with --sort

Runner:
  must be executed with 5 simultaneous jobs and -m10G

Jobs:

name	starts	ends	memory
A1	0	16 	0
A2	0	18	4 GB
A3	0	30	0
A4	0	40	14 GB
A5	0	20	11 GB
B1	20	36	8 GB
B2	20	42	4 GB
B3	20	32	0
C1	36	44	0

Assumes it takes 1s to access 1GB of memory pages

Expected behavior (I: initialize; M: secure memory; B: blocked; S: stops)

Time   Job  Event  Memory   Total  Running
   0   A1    I     0 / 0    0      A1
   0   A2    I     0 / 4    0      A1 A2
   0   A3    I     0 / 0    0      A1 A2 A3
   0   A4    I     0 /14    0      A1 A2 A3 A4
   0   A5    I     0 /11    0      A1 A2 A3 A4 A5
   4   A2    M     4 / 4    4      A1 A2 A3 A4 A5
  11   A5    M     11/11    15     A1 A2 A3 A4 A5
  14   A4    M     14/14    29     A1 A2 A3 A4 A5
  16   A1    S     --/ 0    29     A2 A3 A4 A5
  16   B1    B     --/--    29     A2 A3 A4 A5
  18   A2    S     --/ 4    25     A3 A4 A5
  18   B2    B     --/--    25     A3 A4 A5
  20   A5    S     --/11    14     A3 A4
  20   B1    I     0 / 8    14     A3 A4 B1
  20   B2    I     0 / 4    14     A3 A4 B1 B2
  20   B3    I     0 / 0    14     A3 A4 B1 B2 B3
  24   B2    M     4 / 4    18     A3 A4 B1 B2 B3
  28   B1    M     8 / 8    24     A3 A4 B1 B2 B3
  30   A3    S     --/ 0    26     A4 B1 B2 B3
  30   C1    B     --/--    26     A4 B1 B2 B3
  32   B3    S     --/ 0    26     A4 B1 B2
  32   C1    B     --/--    26     A4 B1 B2
  36   B1    S     --/ 8    18     A4 B2
  36   C1    I     0 / 0    18     A4 B2 C1
  40   A4    S     --/14    4      B2 C1
  42   B2    S     --/ 4    0      C1
  44   C1    S     --/ 0    0      --
