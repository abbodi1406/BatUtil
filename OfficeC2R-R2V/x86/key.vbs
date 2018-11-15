Dim edition
edition = WScript.Arguments(0)
Set keys = CreateObject ("Scripting.Dictionary")

'Office 2019
keys.Add "0bc88885-718c-491d-921f-6f214349e79c", "VQ9DP-NVHPH-T9HJC-J9PDT-KTQRG" 'Professional Plus C2R-P
keys.Add "fc7c4d0c-2e85-4bb9-afd4-01ed1476b5e9", "XM2V9-DN9HH-QB449-XDGKC-W2RMW" 'Project Professional C2R-P
keys.Add "500f6619-ef93-4b75-bcb4-82819998a3ca", "N2CG9-YD3YK-936X4-3WR82-Q3X4H" 'Visio Professional C2R-P
keys.Add "85dd8b5f-eaa4-4af3-a628-cce9e77c9a03", "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP" 'Professional Plus
keys.Add "6912a74b-a5fb-401a-bfdb-2e3ab46f4b02", "6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK" 'Standard
keys.Add "2ca2bf3f-949e-446a-82c7-e25a15ec78c4", "B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B" 'Project Professional
keys.Add "1777f0e3-7392-4198-97ea-8ae4de6f6381", "C4F7P-NCP8C-6CQPT-MQHV9-JXD2M" 'Project Standard
keys.Add "5b5cf08f-b81a-431d-b080-3450d8620565", "9BGNQ-K37YR-RQHF2-38RQ3-7VCBB" 'Visio Professional
keys.Add "e06d7df3-aad0-419d-8dfb-0ac37e2bdf39", "7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2" 'Visio Standard
keys.Add "9e9bceeb-e736-4f26-88de-763f87dcc485", "9N9PT-27V4Y-VJ2PD-YXFMF-YTFQT" 'Access
keys.Add "237854e9-79fc-4497-a0c1-a70969691c6b", "TMJWT-YYNMB-3BKTF-644FC-RVXBD" 'Excel
keys.Add "c8f8a301-19f5-4132-96ce-2de9d4adbd33", "7HD7K-N4PVK-BHBCQ-YWQRW-XW4VK" 'Outlook
keys.Add "3131fd61-5e4f-4308-8d6d-62be1987c92c", "RRNCX-C64HY-W2MM7-MCH9G-TJHMQ" 'PowerPoint
keys.Add "9d3e4cca-e172-46f1-a2f4-1d2107051444", "G2KWX-3NW6P-PY93R-JXK2T-C9Y9V" 'Publisher
keys.Add "734c6c6e-b0ba-4298-a891-671772b2bd1b", "NCJ33-JHBBY-HTK98-MYCV8-HMKHJ" 'Skype for Business
keys.Add "059834fe-a8ea-4bff-b67b-4d006b5447d3", "PBX3G-NWMT6-Q7XBW-PYJGG-WXD33" 'Word

'Office 2016
keys.Add "829b8110-0e6f-4349-bca4-42803577788d", "WGT24-HCNMF-FQ7XH-6M8K7-DRTW9" 'Project Professional C2R-P
keys.Add "cbbaca45-556a-4416-ad03-bda598eaa7c8", "D8NRQ-JTYM3-7J2DX-646CT-6836M" 'Project Standard C2R-P
keys.Add "b234abe3-0857-4f9c-b05a-4dc314f85557", "69WXN-MBYV6-22PQG-3WGHK-RM6XC" 'Visio Professional C2R-P
keys.Add "361fe620-64f4-41b5-ba77-84f8e079b1f7", "NY48V-PPYYH-3F4PX-XJRKJ-W4423" 'Visio Standard C2R-P
keys.Add "e914ea6e-a5fa-4439-a394-a9bb3293ca09", "DMTCJ-KNRKX-26982-JYCKT-P7KB6" 'MondoR
keys.Add "9caabccb-61b1-4b4b-8bec-d10a3c3ac2ce", "HFTND-W9MK4-8B7MJ-B6C4G-XQBR2" 'Mondo
keys.Add "d450596f-894d-49e0-966a-fd39ed4c4c64", "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99" 'Professional Plus
keys.Add "dedfa23d-6ed1-45a6-85dc-63cae0546de6", "JNRGM-WHDWX-FJJG3-K47QV-DRTFM" 'Standard
keys.Add "4f414197-0fc2-4c01-b68a-86cbb9ac254c", "YG9NW-3K39V-2T3HJ-93F3Q-G83KT" 'Project Professional
keys.Add "da7ddabc-3fbe-4447-9e01-6ab7440b4cd4", "GNFHQ-F6YQM-KQDGJ-327XX-KQBVC" 'Project Standard
keys.Add "6bf301c1-b94a-43e9-ba31-d494598c47fb", "PD3PC-RHNGV-FXJ29-8JK7D-RJRJK" 'Visio Professional
keys.Add "aa2a7821-1827-4c2c-8f1d-4513a34dda97", "7WHWN-4T7MP-G96JF-G33KR-W8GF4" 'Visio Standard
keys.Add "67c0fc0c-deba-401b-bf8b-9c8ad8395804", "GNH9Y-D2J4T-FJHGG-QRVH7-QPFDW" 'Access
keys.Add "c3e65d36-141f-4d2f-a303-a842ee756a29", "9C2PK-NWTVB-JMPW8-BFT28-7FTBF" 'Excel
keys.Add "d8cace59-33d2-4ac7-9b1b-9b72339c51c8", "DR92N-9HTF2-97XKM-XW2WJ-XW3J6" 'OneNote
keys.Add "ec9d9265-9d1e-4ed0-838a-cdc20f2551a1", "R69KK-NTPKF-7M3Q4-QYBHW-6MT9B" 'Outlook
keys.Add "d70b1bba-b893-4544-96e2-b7a318091c33", "J7MQP-HNJ4Y-WJ7YM-PFYGF-BY6C6" 'Powerpoint
keys.Add "041a06cb-c5b8-4772-809f-416d03d16654", "F47MM-N3XJP-TQXJ9-BP99D-8K837" 'Publisher
keys.Add "83e04ee1-fa8d-436d-8994-d31a862cab77", "869NQ-FJ69K-466HW-QYCP2-DDBV6" 'Skype for Business
keys.Add "bb11badf-d8aa-470e-9311-20eaf80fe5cc", "WXY84-JN2Q9-RBCCQ-3Q3J3-3PFJ6" 'Word

if keys.Exists(edition) then
WScript.Echo keys.Item(edition)
End If
