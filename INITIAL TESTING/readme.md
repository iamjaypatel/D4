# INITIAL TESTING TIMES

  - Flamegraph Info:
    - 100.txt: initial_100.html
    - 1000.txt: initial_1000.html
    - sample.txt: initial_sample.txt
    - long.txt: initial_long.txt


| File Name               | Real     | User     | Sys      |
|-------------------------|----------|----------|----------|
| 100.txt                 | 0m0.635s | 0m0.583s | 0m0.039s |
| 1000.txt                | 0m6.548s | 0m6.313s | 0m0.144s |
| Sample.txt              | 0m0.188s | 0m0.152s | 0m0.029s |
| bad_block_hash.txt      | 0m0.191s | 0m0.153s | 0m0.030s |
| bad_number.txt          | 0m0.180s | 0m0.144s | 0m0.029s |
| bad_prev_hash.txt       | 0m0.189s | 0m0.152s | 0m0.029s |
| bad_timestamp.txt       | 0m0.191s | 0m0.154s | 0m0.030s |
| invalid_format.txt      | 0m0.128s | 0m0.100s | 0m0.024s |
| invalid_transcation.txt | 0m0.186s | 0m0.150s | 0m0.028s |

| File Name               | Real     | User     | Sys      |
|-------------------------|----------|----------|----------|
| long.txt                | 1m5.982s | 1m3.897s | 0m1.237s |
|                         | 1m7.932s | 1m5.567s | 0m1.327s |
|                         | 1m8.680s | 1m5.830s | 0m1.504s |

- Flamegraph Images

![](initial_100.png?raw=true)
![](initial_sample.png?raw=true)
