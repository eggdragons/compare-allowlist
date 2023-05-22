# how-to-use

## install

```
forge install
npm install
```

## test

for windows

```
npm run testReport
```

for mac

```
npm run testReport-mac
```

※Currently foundry does not allow for legitimate gas comparisons.
※Please note that accurate gas reports are not available.

~ include ~

create Allowlist & Merkle Datas & Ecdsa Datas

& forge test --match-test testGasReportCheckMintNormal

& combine reports

for Len = 64,128,256,512,1024

result --> data/result/output.json

averageGasUsedForSettings = gasUsedForSettings / totalAmounts
averageGasUsedForFunctions = gasUsedForFunctions / totalAmounts

## testReport

### Len=128,trial=3

| test                | averageGasUsedForSettings | averageGasUsedForFunctions | averageGasUsedForTotal | averageGasUsedForTotaldiff |
| ------------------- | ------------------------: | -------------------------: | ---------------------: | -------------------------: |
| NonCheckSign128     |                         0 |                      11659 |                  11659 |                          0 |
| MerkleSign128       |                        84 |                      12751 |                  12835 |                       1176 |
| SSTORE2CheckSign128 |                      1039 |                      11946 |                  12985 |                       1326 |
| EcdsaSign128        |                       199 |                      12828 |                  13027 |                       1368 |
| MappingCheckSign128 |                      4768 |                      11790 |                  16558 |                       4899 |
| BytesCheckSign128   |                      3176 |                      14667 |                  17843 |                       6184 |

### Len=256,trial=3

| test                | averageGasUsedForSettings | averageGasUsedForFunctions | averageGasUsedForTotal | averageGasUsedForTotaldiff |
| ------------------- | ------------------------: | -------------------------: | ---------------------: | -------------------------: |
| NonCheckSign256     |                         0 |                      11021 |                  11021 |                          0 |
| MerkleSign256       |                        39 |                      12157 |                  12196 |                       1175 |
| SSTORE2CheckSign256 |                       909 |                      11311 |                  12220 |                       1199 |
| EcdsaSign256        |                       140 |                      12138 |                  12278 |                       1257 |
| MappingCheckSign256 |                      4450 |                      11164 |                  15614 |                       4593 |
| BytesCheckSign256   |                      2939 |                      16422 |                  19361 |                       8340 |

### Len=512,trial=3

| test                | averageGasUsedForSettings | averageGasUsedForFunctions | averageGasUsedForTotal | averageGasUsedForTotaldiff |
| ------------------- | ------------------------: | -------------------------: | ---------------------: | -------------------------: |
| NonCheckSign512     |                         0 |                      11205 |                  11205 |                          0 |
| SSTORE2CheckSign512 |                       896 |                      11512 |                  12408 |                       1203 |
| EcdsaSign512        |                       115 |                      12358 |                  12473 |                       1268 |
| MerkleSign512       |                        20 |                      12471 |                  12491 |                       1286 |
| MappingCheckSign512 |                      4538 |                      11362 |                  15900 |                       4695 |
| BytesCheckSign512   |                      2984 |                      21987 |                  24971 |                      13766 |

### Len=1024,trial=3

| test                 | averageGasUsedForSettings | averageGasUsedForFunctions | averageGasUsedForTotal | averageGasUsedForTotaldiff |
| -------------------- | ------------------------: | -------------------------: | ---------------------: | -------------------------: |
| NonCheckSign1024     |                         0 |                      11057 |                  11057 |                          0 |
| SSTORE2CheckSign1024 |                       866 |                      11364 |                  12230 |                       1173 |
| EcdsaSign1024        |                       100 |                      12198 |                  12298 |                       1241 |
| MerkleSign1024       |                         9 |                      12402 |                  12411 |                       1354 |
| MappingCheckSign1024 |                      4464 |                      11217 |                  15681 |                       4624 |
| BytesCheckSign1024   |                      2929 |                      32092 |                  35021 |                      23964 |
