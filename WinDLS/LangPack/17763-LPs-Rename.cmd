@echo off
set lng=microsoft-windows-client-languagepack-package
cd /d %~dp0
call :UupRen 1>nul 2>nul
exit /b

:UupRen
ren ecd3d429-9fd3-4de1-9876-3d82542c1525 %lng%_ar-sa-x86-ar-sa.esd
ren ecd8ebc5-d5f9-4221-a56a-fe85695bc888 %lng%_bg-bg-x86-bg-bg.esd
ren e34dee99-91d9-45aa-a42c-fa79608c9f9f %lng%_cs-cz-x86-cs-cz.esd
ren 9676cd27-5709-447b-982e-04c99e9cc3ee %lng%_da-dk-x86-da-dk.esd
ren 991f5f1b-a642-439a-b479-5993917a3855 %lng%_de-de-x86-de-de.esd
ren 2a2564a5-1ffb-4ff7-a7c4-c285081a672b %lng%_el-gr-x86-el-gr.esd
ren d6ddc2a3-bc7a-4316-afc4-50373773f8d2 %lng%_en-gb-x86-en-gb.esd
ren a690cf34-6b72-4ad0-8d14-5bc56225acb3 %lng%_en-us-x86-en-us.esd
ren d219f765-4c87-4461-b5d5-0f8d3541835f %lng%_es-es-x86-es-es.esd
ren 9f7dfbf4-ddf2-44c0-a50b-90f9048a607d %lng%_es-mx-x86-es-mx.esd
ren e35b0582-416b-4f09-943e-9179ce9abb5b %lng%_et-ee-x86-et-ee.esd
ren 63c6c28d-952a-428e-bc6c-2dd0cf91c30b %lng%_fi-fi-x86-fi-fi.esd
ren 9748f2f4-c23c-48de-bc5f-6fdc7951e7cc %lng%_fr-ca-x86-fr-ca.esd
ren 7757ac7e-5e49-4a90-93de-509e784fbd32 %lng%_fr-fr-x86-fr-fr.esd
ren e221ce9f-e565-4bf2-b9c9-bc88f3e08e97 %lng%_he-il-x86-he-il.esd
ren 4ef0fbcf-abfb-4845-8aaf-3f80dd65f6f9 %lng%_hr-hr-x86-hr-hr.esd
ren 59cd354e-561c-4855-85d0-cb62c43afed2 %lng%_hu-hu-x86-hu-hu.esd
ren a8dc5284-2606-47dc-a8bd-e1e9b2418790 %lng%_it-it-x86-it-it.esd
ren a8b12667-7fd1-47dc-9500-a1dbddab9d9a %lng%_ja-jp-x86-ja-jp.esd
ren d125bb06-0b75-4c06-9971-e21346d56e33 %lng%_ko-kr-x86-ko-kr.esd
ren 952e843a-f454-4d11-a46f-8a2ad34fcf87 %lng%_lt-lt-x86-lt-lt.esd
ren 2216d4ae-1c1f-4508-a921-14cc8c2aff3c %lng%_lv-lv-x86-lv-lv.esd
ren b0db93b2-3297-43a8-b3ad-0ce4db116685 %lng%_nb-no-x86-nb-no.esd
ren b6574b58-0c64-45b0-a92b-9595152bc559 %lng%_nl-nl-x86-nl-nl.esd
ren fa60c5d1-4656-4304-bb37-337672ccdcd7 %lng%_pl-pl-x86-pl-pl.esd
ren c93256c6-fa06-41d0-b0f6-525cfb0fca45 %lng%_pt-br-x86-pt-br.esd
ren 67ecf198-dd80-4ff7-8879-959bf0f8161e %lng%_pt-pt-x86-pt-pt.esd
ren 57c3c4c8-90a9-4228-8005-a984af3e2bc2 %lng%_ro-ro-x86-ro-ro.esd
ren 8f5fb892-d9ac-404d-b338-71265de93e57 %lng%_ru-ru-x86-ru-ru.esd
ren 9c0170c5-00d5-42a2-8f05-c1724b29f41b %lng%_sk-sk-x86-sk-sk.esd
ren e81ee36e-f84d-4827-b818-67ad2614a1a4 %lng%_sl-si-x86-sl-si.esd
ren 7979f33e-db84-4805-b42e-f00adb858be6 %lng%_sr-latn-rs-x86-sr-latn-rs.esd
ren b722f625-db29-4cf2-be73-f4fea128e1de %lng%_sv-se-x86-sv-se.esd
ren b0723cae-0f11-45be-b945-d4f18ece9983 %lng%_th-th-x86-th-th.esd
ren 30f1d788-7fce-4455-b6c8-a013c1af25b1 %lng%_tr-tr-x86-tr-tr.esd
ren 3afedc8c-2f1a-4250-b2e3-499808651121 %lng%_uk-ua-x86-uk-ua.esd
ren 31fe6fe4-cf07-4f1a-abfc-055b1192ba21 %lng%_zh-cn-x86-zh-cn.esd
ren fe93dee2-cf27-4826-a333-8112c503d90a %lng%_zh-tw-x86-zh-tw.esd

ren 338f3acb-e824-466c-a055-f1ea5c761035 %lng%_ar-sa-amd64-ar-sa.esd
ren 8c378739-1c8f-493b-a483-a5d1a6d2df2d %lng%_bg-bg-amd64-bg-bg.esd
ren 4daf8ce8-27a9-405e-9d26-80fe5ec3243d %lng%_cs-cz-amd64-cs-cz.esd
ren b42777b3-a281-45a3-8e46-d000d67e6f28 %lng%_da-dk-amd64-da-dk.esd
ren 533c7dbc-ddb0-4adc-986c-484bb24c2638 %lng%_de-de-amd64-de-de.esd
ren 0a349eaf-a483-4286-94d7-1f1d86969460 %lng%_el-gr-amd64-el-gr.esd
ren 23e260bd-aa38-4a37-8951-07770d7df41c %lng%_en-gb-amd64-en-gb.esd
ren aed2e643-3286-4f5a-834c-13f621bf76ed %lng%_en-us-amd64-en-us.esd
ren 52d4ec55-b747-4b3c-a959-285a74183647 %lng%_es-es-amd64-es-es.esd
ren 427650d7-5d32-49fa-a4cf-137e0c07ce05 %lng%_es-mx-amd64-es-mx.esd
ren 7e78bc32-6075-4d1f-ace2-62bba20409fc %lng%_et-ee-amd64-et-ee.esd
ren 63cbfa0a-a269-4aa3-ba6e-638dd56448dd %lng%_fi-fi-amd64-fi-fi.esd
ren ece1b624-f15f-4b0c-b613-b169c00a29a8 %lng%_fr-ca-amd64-fr-ca.esd
ren caa44afb-4d68-497d-912c-111d09502a00 %lng%_fr-fr-amd64-fr-fr.esd
ren ab80f208-d056-41c9-9cf4-5514a5da7d6c %lng%_he-il-amd64-he-il.esd
ren 886e6a63-8936-4342-b6f6-7e1b86389063 %lng%_hr-hr-amd64-hr-hr.esd
ren 70d97940-e183-47a7-83f5-b95e4d7425e0 %lng%_hu-hu-amd64-hu-hu.esd
ren add33bad-877f-46e0-8c12-16420567d947 %lng%_it-it-amd64-it-it.esd
ren 5d111451-cacc-4181-9cb5-89b03ae1576b %lng%_ja-jp-amd64-ja-jp.esd
ren d93692d2-6582-441f-8797-888b66b419ed %lng%_ko-kr-amd64-ko-kr.esd
ren f2fc18f8-befc-423c-8578-3581a3498577 %lng%_lt-lt-amd64-lt-lt.esd
ren ddb1f03a-71a3-48ec-b8b0-778300037a36 %lng%_lv-lv-amd64-lv-lv.esd
ren f9df3896-2e4f-4b08-9147-7361d1117c1e %lng%_nb-no-amd64-nb-no.esd
ren 698eb502-271f-4c06-bea3-0e272a63c898 %lng%_nl-nl-amd64-nl-nl.esd
ren 32ce5489-4604-4021-bf94-43ae8decc3d8 %lng%_pl-pl-amd64-pl-pl.esd
ren 952674cf-fc30-4ecf-b041-f8c156e8a7eb %lng%_pt-br-amd64-pt-br.esd
ren ebc7e6ce-7992-4325-871c-ff09d46bbf10 %lng%_pt-pt-amd64-pt-pt.esd
ren a400e8e8-beee-4619-89a5-d5c046626dde %lng%_ro-ro-amd64-ro-ro.esd
ren 5e0e5a18-8a06-48c4-9557-aebef1d93d06 %lng%_ru-ru-amd64-ru-ru.esd
ren f246436a-d85d-4300-8ed3-dc1ed54ee89a %lng%_sk-sk-amd64-sk-sk.esd
ren be58ca62-85ff-486f-af60-99f8c0b0d909 %lng%_sl-si-amd64-sl-si.esd
ren fdc40839-95ab-455d-9f7f-22256c5f76ab %lng%_sr-latn-rs-amd64-sr-latn-rs.esd
ren 4a25cbe8-9195-4aa4-8268-4d1e47ff3d4b %lng%_sv-se-amd64-sv-se.esd
ren 3409961f-f428-4afb-8291-80507d904f0f %lng%_th-th-amd64-th-th.esd
ren d07a2115-88a5-4ab2-81e6-7f5b8ed42270 %lng%_tr-tr-amd64-tr-tr.esd
ren ae2411bd-ba9f-466e-8f57-4d29129d8828 %lng%_uk-ua-amd64-uk-ua.esd
ren f39f7244-974b-4dae-adf8-23ead3318486 %lng%_zh-cn-amd64-zh-cn.esd
ren d1dfae64-915f-454c-a004-2aaf78929db9 %lng%_zh-tw-amd64-zh-tw.esd
exit /b
