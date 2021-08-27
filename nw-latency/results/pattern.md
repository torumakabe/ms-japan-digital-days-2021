## Pattern

1. AN_disable -> AN_disable TCP (Same Zone), Server-1 -> Server-0
2. AN_disable -> AN_enable TCP (Same Zone), Server-1 -> Server-2
3. AN_enable -> AN_disable TCP (Same Zone), Server-3 -> Server-0
4. AN_enable -> AN_enable TCP (Same Zone), Server-3 -> Server-2
5. AN_enable -> AN_enable TCP (Same Zone, Same PPG), Server-4 -> Server-2
6. AN_enable -> AN_enable TCP (Zone 1 and 2), Server-5 -> Server-2
7. AN_enable -> AN_enable TCP (Zone 1 and 3), Server-6 -> Server-2
8. AN_enable -> AN_enable TCP (Zone 2 and 3), Server-5 -> Server-6

## Server List

0. "Zone":"1", "AN_enable":false, "PPG_enable"false
1. "Zone":"1", "AN_enable":false, "PPG_enable"false
2. "Zone":"1", "AN_enable":true, "PPG_enable":true
3. "Zone":"1", "AN_enable":true, "PPG_enable":false
4. "Zone":"1", "AN_enable":true, "PPG_enable":true
5. "Zone":"2", "AN_enable":true, "PPG_enable":false
6. "Zone":"3", "AN_enable":true, "PPG_enable":false

## Private IP List

private_ips = {
  "0" = "10.0.0.10"
  "1" = "10.0.0.7"
  "2" = "10.0.0.5"
  "3" = "10.0.0.8"
  "4" = "10.0.0.6"
  "5" = "10.0.0.4"
  "6" = "10.0.0.9"
}
