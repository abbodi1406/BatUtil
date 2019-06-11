@echo off
set lng=microsoft-windows-client-languagepack-package
cd /d %~dp0
call :UupRen 1>nul 2>nul
exit /b

:UupRen
ren 98b6fa7c-85c1-4ede-a05c-aeddbf45c009 %lng%_ar-sa-x86-ar-sa.esd
ren de11f768-c632-444e-98ec-395554993b15 %lng%_bg-bg-x86-bg-bg.esd
ren a5349e18-7aaa-42b3-88cf-b4f215e1963d %lng%_cs-cz-x86-cs-cz.esd
ren b0e6f636-8a5d-471c-9fee-06ca32ae469c %lng%_da-dk-x86-da-dk.esd
ren 55111a4f-7698-401c-be50-72fe019fbe95 %lng%_de-de-x86-de-de.esd
ren cee59fbd-ad2a-4df9-8b94-f26d343e20c5 %lng%_el-gr-x86-el-gr.esd
ren 8c418c0a-7a9d-499f-aa20-7732fda59fef %lng%_en-gb-x86-en-gb.esd
ren 83cf15fc-0826-4472-8cc9-6ef4601cbabd %lng%_en-us-x86-en-us.esd
ren a54b9a7f-dcc4-4da8-a6a1-c906dec00bb1 %lng%_es-es-x86-es-es.esd
ren ebd131fa-3b37-46e8-9360-15cadfa46920 %lng%_es-mx-x86-es-mx.esd
ren 6d3bc804-3f02-4e71-ad0c-ec0aefc5f0e0 %lng%_et-ee-x86-et-ee.esd
ren 3cf99c1d-8aee-4a82-b572-00fb42b43ffe %lng%_fi-fi-x86-fi-fi.esd
ren 6ed5fdbb-3745-4790-8577-26ffcbaffffd %lng%_fr-ca-x86-fr-ca.esd
ren 4021f4bd-f99b-4b9d-a88c-db1e203e0740 %lng%_fr-fr-x86-fr-fr.esd
ren c319300d-1a8a-4b29-b41e-79732b95e2b8 %lng%_he-il-x86-he-il.esd
ren 69b614b6-4c7e-4679-8648-40b4570ba399 %lng%_hr-hr-x86-hr-hr.esd
ren 858a7d6d-73eb-4c01-8a47-46322f50f3c2 %lng%_hu-hu-x86-hu-hu.esd
ren c84dee70-f651-465b-b66c-c1a75eaf601f %lng%_it-it-x86-it-it.esd
ren e3db86e5-187b-4835-a699-34d67674fbea %lng%_ja-jp-x86-ja-jp.esd
ren 02341bde-93f5-492e-acc7-2541911dc53e %lng%_ko-kr-x86-ko-kr.esd
ren b09e8780-7f37-465b-a8a0-9f198b23b3d2 %lng%_lt-lt-x86-lt-lt.esd
ren dd602e7a-b575-4036-980a-d2daa539890b %lng%_lv-lv-x86-lv-lv.esd
ren 6b2820ea-6a77-450c-810e-a5cba001f5e5 %lng%_nb-no-x86-nb-no.esd
ren 44d8e418-86e6-478e-ab3b-52009b71d633 %lng%_nl-nl-x86-nl-nl.esd
ren 54f181a3-dae8-4ee8-8445-c65cf3aef299 %lng%_pl-pl-x86-pl-pl.esd
ren 53c61c1f-27ca-42ed-9b09-3d806d620120 %lng%_pt-br-x86-pt-br.esd
ren bd4d218f-eb1e-4786-85a7-6d5b6775937f %lng%_pt-pt-x86-pt-pt.esd
ren 75dfc388-512e-41c1-886f-84426782dc05 %lng%_ro-ro-x86-ro-ro.esd
ren ada395ea-42e4-4d1b-85b8-5aee2b9788f7 %lng%_ru-ru-x86-ru-ru.esd
ren 3dce005b-bf36-4edb-89e9-4ee16f9b1bcc %lng%_sk-sk-x86-sk-sk.esd
ren a8e7c385-87d6-453c-a020-27454e94809b %lng%_sl-si-x86-sl-si.esd
ren b207a8aa-2bda-424a-8667-b650155e085e %lng%_sr-latn-rs-x86-sr-latn-rs.esd
ren 3f6c7673-d799-4ad1-b2d2-2dbb203d16d2 %lng%_sv-se-x86-sv-se.esd
ren f99488ba-2fc4-49e0-9069-eaaa1844892d %lng%_th-th-x86-th-th.esd
ren 96761323-80d0-4103-841d-488245d0dd21 %lng%_tr-tr-x86-tr-tr.esd
ren 376cb511-d3de-4adc-bcad-3a633a9a3bd1 %lng%_uk-ua-x86-uk-ua.esd
ren f7160f1a-4de2-41a5-80b1-478426770553 %lng%_zh-cn-x86-zh-cn.esd
ren c5da234c-00cb-4d4f-a501-d7fca943fac4 %lng%_zh-tw-x86-zh-tw.esd

ren 57668ecc-3669-4a50-af85-0b5ea81042e6 %lng%_ar-sa-amd64-ar-sa.esd
ren cbebad32-0507-4298-99fb-e7297234f71b %lng%_bg-bg-amd64-bg-bg.esd
ren a7dcde89-f40c-4295-a853-f594c4447f78 %lng%_cs-cz-amd64-cs-cz.esd
ren 9dbc394e-9b09-4a35-b305-7ebe1600a18b %lng%_da-dk-amd64-da-dk.esd
ren 7d7c2ea5-09a3-4bc1-a331-761c95e3e1ce %lng%_de-de-amd64-de-de.esd
ren 25669a42-5a8a-4eaf-9b0b-db2add82c8ca %lng%_el-gr-amd64-el-gr.esd
ren e2d95f07-cc89-402a-8dcc-636d0eb5e3d0 %lng%_en-gb-amd64-en-gb.esd
ren 1a23f9ab-a8d8-4f44-aa5f-dafc20b4f690 %lng%_en-us-amd64-en-us.esd
ren 9799a9d4-b480-4127-916a-72178de73680 %lng%_es-es-amd64-es-es.esd
ren 4e5dc0ad-6aef-4688-a9c7-bf8ec604398e %lng%_es-mx-amd64-es-mx.esd
ren 5e2eeeb5-b82d-47f0-9e7f-fee537bbf098 %lng%_et-ee-amd64-et-ee.esd
ren d0b14f33-7035-4262-852c-58df0d9414dc %lng%_fi-fi-amd64-fi-fi.esd
ren 4c3429db-5ac3-41a4-b036-92ba3391fcac %lng%_fr-ca-amd64-fr-ca.esd
ren 2fc95bf2-b549-4e9d-8092-b6cba3c406d7 %lng%_fr-fr-amd64-fr-fr.esd
ren bfd5f517-077b-447f-b077-e98b78cb05f1 %lng%_he-il-amd64-he-il.esd
ren 255eb142-efc6-470d-a10e-498ff098fd23 %lng%_hr-hr-amd64-hr-hr.esd
ren dcda9cac-ddbe-4c9a-bd2d-0619eededa36 %lng%_hu-hu-amd64-hu-hu.esd
ren 747c957a-4842-49fa-9c76-5937fb8111bb %lng%_it-it-amd64-it-it.esd
ren 55677355-988a-4a6c-9db5-ef6835e24488 %lng%_ja-jp-amd64-ja-jp.esd
ren 53a66d57-739b-4d54-8990-c54387a504ac %lng%_ko-kr-amd64-ko-kr.esd
ren d85e6a8d-b704-4980-a7fa-bf983ff6a5af %lng%_lt-lt-amd64-lt-lt.esd
ren d99e151e-71be-4317-a17e-4427e698191f %lng%_lv-lv-amd64-lv-lv.esd
ren 2e18d1f2-e620-4468-881f-fd665bd0d5d0 %lng%_nb-no-amd64-nb-no.esd
ren 2278673e-575d-4cec-ba4f-35fe81024fe9 %lng%_nl-nl-amd64-nl-nl.esd
ren 61dcd152-5a34-4d8e-9011-6dc41ed4ad78 %lng%_pl-pl-amd64-pl-pl.esd
ren c39e21de-fa48-4aa8-94d4-56407aacb26c %lng%_pt-br-amd64-pt-br.esd
ren 93ccaa7d-2c3e-4ad0-8579-7e69099d1163 %lng%_pt-pt-amd64-pt-pt.esd
ren 8cbf23ae-8bb7-4c3d-a279-fd0d84b5fed7 %lng%_ro-ro-amd64-ro-ro.esd
ren f737fa63-19dc-4867-92f6-4fefbe31f5aa %lng%_ru-ru-amd64-ru-ru.esd
ren 0ceb2850-e425-418a-b654-12d2c705fbbf %lng%_sk-sk-amd64-sk-sk.esd
ren bb33212c-09a3-4669-aecc-0eff0bcb8dee %lng%_sl-si-amd64-sl-si.esd
ren f0eba783-f966-4aab-91b6-cc9009749fd1 %lng%_sr-latn-rs-amd64-sr-latn-rs.esd
ren 0cea6986-f004-4c96-9abc-581f9a41b60e %lng%_sv-se-amd64-sv-se.esd
ren e2399010-b2d7-485e-8a7a-6435ee0392c1 %lng%_th-th-amd64-th-th.esd
ren 99cb64c8-a4d8-4756-94c7-938f1317fb68 %lng%_tr-tr-amd64-tr-tr.esd
ren 152ee8d0-f96f-4298-8f41-64c44b6d3600 %lng%_uk-ua-amd64-uk-ua.esd
ren 3ebf460e-4377-40b6-a6f0-01bc6c9e5dc0 %lng%_zh-cn-amd64-zh-cn.esd
ren a055149c-d670-424b-bc0e-eaa8eecab5d9 %lng%_zh-tw-amd64-zh-tw.esd
exit /b
