Option Explicit

If Wscript.Arguments.Count = 0 Then Wscript.Quit 1

'On Error Resume Next

Const msiOpenDatabaseModeReadOnly = 0
Const msiOpenDatabaseModeTransact = 1
Const OFFICEID      = "000000FF1CE}"
Const PRODLEN       = 12
Const HKCR          = &H80000000
Const HKCU          = &H80000001
Const HKLM          = &H80000002

Dim oFso, oReg, oWSh, oMsi, MsiDb, sMsiFile, dbView, record, sProductCode, sWI, fMSP

sMsiFile = Wscript.Arguments(0)
Set oMsi      = CreateObject("WindowsInstaller.Installer")
Set MsiDb = oMsi.OpenDatabase(sMsiFile, msiOpenDatabaseModeReadOnly) : CheckError

sProductCode = GetMsiProductCode
If NOT UCase(Right(sProductCode, PRODLEN)) = OFFICEID Then Wscript.Quit 1
If NOT Mid(sProductCode, 4, 2) = "15" Then Wscript.Quit 1

Set oReg      = GetObject("winmgmts:\\.\root\default:StdRegProv")
Set oWSh      = CreateObject("WScript.Shell")
Set oFso      = CreateObject("Scripting.FileSystemObject")

Dim sPatchCode, sProductCC, sPatchCC, sRegPatch1, sRegPatch2, sRegClasses, sRegCurrent, sPatchesCC, sPatchProperty, foundPatches, arrUpper, arrLower, prfUpper, prfLower

' applied patches to check against
arrUpper = Array()
AddItem arrUpper, "C454E844_4F27_49EA_966D_94E0F834B4BE" : AddItem arrUpper, "50BDB592_FE2C_41ED_A97E_F77B05E1E6C8" ' KB5002151 ace
AddItem arrUpper, "ADDA4CFE_ADAA_4A52_8398_3299C8D8FF0B" : AddItem arrUpper, "14FE6688_22B4_48BB_9B36_473AFEA7960D" ' KB5001937 analys32
AddItem arrUpper, "5C568FE6_A269_4A88_8256_DC1A8B89E622" : AddItem arrUpper, "1FC035BF_53D9_437B_B36E_996C7FB18E30" ' KB3114488 csisyncclient
AddItem arrUpper, "FC017EDD_645B_44D8_9D84_623DE069F1B9" : AddItem arrUpper, "A472CEA9_44BA_4ADD_8AD1_589B2F0240EE" ' KB3023052 fm20
AddItem arrUpper, "6120444C_EB75_452F_A0EA_1ADADC4B4B3F" : AddItem arrUpper, "D335A27A_29AB_42DD_A36A_B986E722B769" ' KB3114946 infopath
AddItem arrUpper, "6120444C_EB75_452F_A0EA_1ADADC4B4B3F" : AddItem arrUpper, "D335A27A_29AB_42DD_A36A_B986E722B769" ' KB3114946 infopath
AddItem arrUpper, "19001452_D3D5_43C6_A605_2E14D508031E" : AddItem arrUpper, "1D6436BE_4BC2_4D21_A4EE_E1D8C895041B" ' KB3127916 ipeditor
AddItem arrUpper, "2FDF7953_75A9_4341_A769_EC0CAA09FFF3" : AddItem arrUpper, "81695FD1_B401_4A23_9F21_DE79A4CAC6C1" ' KB4018378 msptls
AddItem arrUpper, "7669B523_05A9_4A48_92EB_4EE87FE6A8DB" : AddItem arrUpper, "4D2830B1_16F6_4B1A_B8AB_D677755C569C" ' KB5002477 mso
AddItem arrUpper, "F97B139A_D8BF_46FF_A6F6_50710FED8644" : AddItem arrUpper, "1C76EBD9_0A70_4094_A543_00CAA3B62113" ' KB4484289 lync
AddItem arrUpper, "F97B139A_D8BF_46FF_A6F6_50710FED8644" : AddItem arrUpper, "1C76EBD9_0A70_4094_A543_00CAA3B62113" ' KB4484289 lync
AddItem arrUpper, "96903939_431D_4BD1_ADCD_B578900397D7" : AddItem arrUpper, "52EF08F9_F296_48DC_A906_E03225E51C9B" ' KB3115404 outlfltr
AddItem arrUpper, "021993D4_1183_455F_94F7_D5817C1B7B46" : AddItem arrUpper, "3C5BF2C1_87A5_4627_A918_B91F4E87D090" ' KB5002274 vbe7
AddItem arrUpper, "BB92A877_3443_4FAF_B4BB_470B9792AFBE" : AddItem arrUpper, "06F187A1_55FA_4023_BDF5_197A54602E0E" ' KB3114499 wxpcore
AddItem arrUpper, "B2FFC7EA_8F6D_4C1C_8932_D590A7C027E8" : AddItem arrUpper, "093401A3_2F40_4024_9E94_EC06A6FC060F" ' KB5002479 visio
AddItem arrUpper, "C60D0F6F_9E41_4AC8_BAA8_D2D8380F88C4" : AddItem arrUpper, "F9A3EFB4_B842_4A03_A31F_01D52F7E045A" ' KB5002514 outlook
AddItem arrUpper, "17D66622_E769_4D30_ADA5_1735E4DA7050" : AddItem arrUpper, "DADAF304_0F45_47A1_A5E9_ADF952D25D73" ' KB3114721 spd
AddItem arrUpper, "17D66622_E769_4D30_ADA5_1735E4DA7050" : AddItem arrUpper, "DADAF304_0F45_47A1_A5E9_ADF952D25D73" ' KB3114721 spd

' superseded patches to register
arrLower = Array()
AddItem arrLower, "C2EB2330_109A_41ED_BE10_A96B1070A71E" : AddItem arrLower, "F9CEB20C_D32C_4A59_8860_AEF3F8B2CBC6" ' KB5002124 ace
AddItem arrLower, "006C0075_CE09_4BDA_987E_B15954B47972" : AddItem arrLower, "B3694156_80E0_4F95_86B4_DAFCF6571FEE" ' KB3178639 analys32
AddItem arrLower, "2782476F_48B5_4CEC_B3C1_EBF3F701B266" : AddItem arrLower, "2C69D57F_44CD_4EF0_B925_7FFC64B18DD7" ' KB3085482 csisyncclient
AddItem arrLower, "DFA3708C_C837_42C3_85AF_41E39CD1E0E9" : AddItem arrLower, "5E642F23_B29D_4589_80CF_D25E8D90C8DA" ' KB2726958 fm20
AddItem arrLower, "314EBC8D_901C_4A08_AE9B_90C1551B612D" : AddItem arrLower, "6167EE58_7045_4C6C_BB86_02D1E76FE39B" ' KB3114833 infopath
AddItem arrLower, "726AC699_CE52_4AB0_AF87_38FEB14C0B65" : AddItem arrLower, "1FC11BD3_B58F_4CC4_8A27_A6B8FD383607" ' KB3054793 infopath
AddItem arrLower, "618C6154_0B5C_4448_B6AC_615942DDB39D" : AddItem arrLower, "F38B84F1_9F10_42A6_8F04_D6B5727FC4A5" ' KB3162075 ipeditor
AddItem arrLower, "705BE900_4761_4742_BB58_2877F1544459" : AddItem arrLower, "D8AD4AD9_80FA_4D64_A847_B23948D49A6D" ' KB3054816 msptls
AddItem arrLower, "F280CADF_7A75_46B3_9718_F91D533D5EA2" : AddItem arrLower, "DD0EFF73_3EF1_4501_9609_9D799BB20F2F" ' KB3039779 mso
AddItem arrLower, "5A21F2B6_CD93_4163_AF9A_5AD47B0C6836" : AddItem arrLower, "1A0B44D1_9E34_4DB5_92ED_6AA3250032F3" ' KB3039779 lync
AddItem arrLower, "A679D31F_75D5_45CB_B19F_AE9C38527E9F" : AddItem arrLower, "139BBCED_6D79_456F_BD7B_3538F45AF776" ' KB4475519 lync
AddItem arrLower, "B64AFC4A_F842_4444_9DA4_12A798EF5551" : AddItem arrLower, "D387133F_38D2_4B75_AC66_5CB1CCD04186" ' KB2760587 outlfltr
AddItem arrLower, "AAC38199_5AB8_4956_87EC_BA7434C614AC" : AddItem arrLower, "ED1F38E7_E0B6_4CDF_BE63_A0E6DBED9F48" ' KB5002121 vbe7
AddItem arrLower, "89E5A77C_6652_4355_9960_F88F70616738" : AddItem arrLower, "9D27FA6E_0179_4B51_B0EA_4655EF446E90" ' KB3085578 wxpcore
AddItem arrLower, "8276E551_3E74_4C0A_A915_341A08FDFDB1" : AddItem arrLower, "D3B71E17_65DB_4BDD_926A_296D1F0C2352" ' KB5002417 visio
AddItem arrLower, "6F872FBF_158D_4A9E_8496_4ECA97277FD5" : AddItem arrLower, "E5630C0F_C04A_4964_9310_3BB6472060EF" ' KB5002449 outlook
AddItem arrLower, "7783C0FE_91D3_44A5_ABB6_2A5CBDACDA0D" : AddItem arrLower, "44344941_19D2_4DB6_9B95_2ABC89263118" ' KB2863836 spd
AddItem arrLower, "B8F63C4C_4BF2_47EA_8C00_BB83C4D0FA26" : AddItem arrLower, "5414D5E2_E2B0_4B9F_BE46_CDEAC37EB089" ' KB2752096 spdcore

' proofloc2013-kb4011677
prfUpper = Array()
AddItem prfUpper, "19141D5E_18DA_4811_A5F0_5D0820BB2170" : AddItem prfUpper, "8DC2DC41_8D78_4DD8_B888_ABF63DCA964A" ' ar-sa
AddItem prfUpper, "0153CC9C_2E59_4D86_8109_2239A3DEB6A0" : AddItem prfUpper, "1059ADA2_B16E_446E_AF90_10DC4C4922E2" ' bg-bg
AddItem prfUpper, "7B97E15A_C343_4147_A384_A8C3437ACD9E" : AddItem prfUpper, "2DD7AE69_4A23_4BCB_842B_5FEA46F01F8F" ' ca-es
AddItem prfUpper, "50D0E498_DD54_4FA5_8513_59B8A50BC36B" : AddItem prfUpper, "860A280D_3917_49C7_A19A_6B3E4B82548C" ' cs-cz
AddItem prfUpper, "81B08F49_891B_43B9_88C4_DF117103DAE4" : AddItem prfUpper, "5FF40CCC_FFCA_49B5_AB28_8FC9BEA86FB1" ' da-dk
AddItem prfUpper, "07ED17A8_AA59_47D5_AAB5_059AE484B58D" : AddItem prfUpper, "D99D9B41_3929_4B00_BFEF_5FC83D268DD4" ' de-de
AddItem prfUpper, "0E8DFD92_CDE4_4419_8083_C1399D10ACE3" : AddItem prfUpper, "6B02C81A_16A0_493A_9122_B2C80E1DC610" ' el-gr
AddItem prfUpper, "45B5E686_A7A1_457D_B98B_2EE3110B537D" : AddItem prfUpper, "062A9161_3C40_4F8F_B7D6_F9AE23260467" ' en-us
AddItem prfUpper, "166B105A_EC67_4F45_8824_ABAA0E505BD8" : AddItem prfUpper, "CC74E7EA_557F_4D36_8BAC_44A01EB5B7A2" ' es-es
AddItem prfUpper, "CD6AE55D_2F50_4264_B9F7_E4DF2AAA2C0B" : AddItem prfUpper, "68EF38F5_41B2_4F09_8107_60BE46624CAA" ' et-ee
AddItem prfUpper, "25DC2470_480D_45EB_9D44_FB8EA7D71174" : AddItem prfUpper, "0EF4ECB5_D4FC_4D47_A926_4F1C58A9DB93" ' eu-es
AddItem prfUpper, "7D38BB40_2FFE_4272_945C_1364DF9EB023" : AddItem prfUpper, "9A80ABFB_0D20_4FAD_8A6A_AF15B48EBF23" ' fi-fi
AddItem prfUpper, "883F27D7_997E_4440_A22D_48DF1A228D61" : AddItem prfUpper, "47E3610A_BD61_4D60_B408_7794850D6B58" ' fr-fr
AddItem prfUpper, "144DE55E_4EB9_4331_9C2F_EE1202964238" : AddItem prfUpper, "0BDC49CA_1B58_4AA5_A3FA_69AB9A4D4E4A" ' gl-es
AddItem prfUpper, "0FB8827C_C1A1_435C_A9D5_E8C54D01A8FB" : AddItem prfUpper, "0912CF54_4501_42FC_8219_816FB9A96A68" ' he-il
AddItem prfUpper, "6A034576_6302_4238_9F1F_8840328D441F" : AddItem prfUpper, "AEC67B96_E512_4B75_B15A_E4E816C76E4C" ' hi-in
AddItem prfUpper, "53D45033_E231_482D_A592_5CBE5733A4F0" : AddItem prfUpper, "78844FA9_DC66_4146_9120_A63AF93295B7" ' hr-hr
AddItem prfUpper, "131736A1_6BB2_4CA0_A107_2372E2D2B319" : AddItem prfUpper, "DFCFB3DE_5C22_41D0_A8C4_80039E0A832A" ' hu-hu
AddItem prfUpper, "989A5C9A_B963_4C54_A742_4D4C2BCB05BF" : AddItem prfUpper, "96508616_9E14_4132_8870_6D68EAA5E8D8" ' it-it
AddItem prfUpper, "396E52D9_B6A7_43CB_AE0E_B0A9C8D671E4" : AddItem prfUpper, "91FFDA4A_0778_45CF_9FEB_C5A7F0674F20" ' ja-jp
AddItem prfUpper, "6EAA0091_2165_413F_84DE_C347F9173489" : AddItem prfUpper, "53189091_DE70_4D90_8263_FF3FEA198794" ' ko-kr
AddItem prfUpper, "EEFF579A_042A_4F94_8FC6_CA3D9F508E39" : AddItem prfUpper, "38A6E3FB_ED3C_4442_AFF8_BECC71797E7D" ' lt-lt
AddItem prfUpper, "7A508108_EB6B_4772_A803_C2215C6A328A" : AddItem prfUpper, "37376979_D2E2_4FD0_AC09_C4526A95FA67" ' lv-lv
AddItem prfUpper, "BD2A2961_5B01_448D_B3B4_EB4D4235BBF1" : AddItem prfUpper, "1B741646_EA29_430A_A743_82B886AF6339" ' nb-no
AddItem prfUpper, "C0B7757C_0579_4339_B3DB_BF894A4AFFCC" : AddItem prfUpper, "C598C95A_3D76_44BD_9591_C479CA458491" ' nl-nl
AddItem prfUpper, "E635AC38_07FE_400E_8792_CEBC77B9F67C" : AddItem prfUpper, "6B333AD6_2511_410A_9466_AC4FF63019A7" ' nn-no
AddItem prfUpper, "B84B8BC4_D1BF_4013_9264_49890744920A" : AddItem prfUpper, "426160BF_1408_4262_A6C5_B5234E5DAFC1" ' pl-pl
AddItem prfUpper, "E0430EE1_C62D_4AA1_9AD8_075721E75476" : AddItem prfUpper, "1F482AFF_8148_4080_9EC0_1B618BEA5B7B" ' pt-br
AddItem prfUpper, "26ECE823_2B1B_4962_883E_591158DAF0F1" : AddItem prfUpper, "202D9FA8_67FE_4EF5_B59B_B70529250DE4" ' pt-pt
AddItem prfUpper, "F5A11315_1905_4E80_9FFF_577FBBD1ADE4" : AddItem prfUpper, "E04B84D5_7203_4B79_BE86_004E4CCDF45A" ' ro-ro
AddItem prfUpper, "CBA18D8D_4F4D_4AC9_93D2_9AAC2F47FE1E" : AddItem prfUpper, "078A9D59_F817_431C_A4B5_8838E5592914" ' ru-ru
AddItem prfUpper, "DFDA0D2A_9D82_4C7C_B1AC_D114AA207AA4" : AddItem prfUpper, "1D7A083C_53CE_4FF2_B506_5CC7F5D245F0" ' sk-sk
AddItem prfUpper, "A3F4C4ED_5052_409A_A4B7_7CE85EC2C1B0" : AddItem prfUpper, "0224E4A4_2A24_4741_A240_D590A1E9E5A2" ' sl-si
AddItem prfUpper, "1F2F8D08_06E4_44D2_8857_8CFFC075A201" : AddItem prfUpper, "C0242FD5_8BD8_4BDB_A71B_10017BA8E7D6" ' sr-cyrl-cs
AddItem prfUpper, "1B8914FA_9EB2_4025_A3FA_2CBD233205F9" : AddItem prfUpper, "B204704A_4B5B_46F3_9843_793AEB9690FA" ' sr-latn-cs
AddItem prfUpper, "D41258BC_4C7A_41C0_879F_785C2373F547" : AddItem prfUpper, "14F14497_FDAE_46AA_AE9D_813AF9B04C39" ' sv-se
AddItem prfUpper, "AC2AB38C_E137_4506_826D_8D5AD9C777EF" : AddItem prfUpper, "C40D38C6_F8BB_451B_B364_7F81D62DA2CC" ' th-th
AddItem prfUpper, "CDBF6CC2_2FD4_4930_94F8_D4D5B4D9CCCE" : AddItem prfUpper, "BA819FB7_EE86_4CAD_84B7_BAB35F61AF89" ' tr-tr
AddItem prfUpper, "329A9AC9_2FBE_4CF3_B0F2_AE6D13756D02" : AddItem prfUpper, "999332BD_D46A_4652_B7A3_3D9B721ED543" ' uk-ua
AddItem prfUpper, "8C2F6BFE_7279_485F_BF55_8E1C6A11D03B" : AddItem prfUpper, "67E0BEFF_54BA_4886_9523_991F64D32794" ' zh-cn
AddItem prfUpper, "837DDB22_B162_4E10_9972_47F05C4D4454" : AddItem prfUpper, "10513116_E0C3_42B7_88AD_7675CF0F87BF" ' zh-tw

' proofloc2013-kb2880463
prfLower = Array()
AddItem prfLower, "94F7D101_73DB_4F69_9C13_A42D2403CE54" : AddItem prfLower, "525FB4E9_F7A2_4F58_B5F4_AAFB8C2D9AA6" ' ar-sa
AddItem prfLower, "BF5FB4D5_E631_492E_8C1F_D11CEBFF3FD3" : AddItem prfLower, "27823779_0D35_4212_85A2_EF2C7F5C5FF0" ' bg-bg
AddItem prfLower, "569C9773_18B6_4B59_9962_17403C0B6EBB" : AddItem prfLower, "A73C467D_E307_4C56_9A1A_294EE0E52E4F" ' ca-es
AddItem prfLower, "B9E66FD2_CAB3_49B0_BACF_2AE664680E23" : AddItem prfLower, "D04DB6E2_8A1E_4DCA_B6F8_33961766A90E" ' cs-cz
AddItem prfLower, "92677A89_E097_4B26_A55F_436C00F689C5" : AddItem prfLower, "847114EC_59EC_410D_8AF1_AD1088764DB3" ' da-dk
AddItem prfLower, "6FB49454_8737_4621_8E03_EE660F672557" : AddItem prfLower, "F00C18C4_4CE6_489F_8993_A791FD96FD02" ' de-de
AddItem prfLower, "6FE1BC81_6EB9_4C3D_8EC5_F47DA7FC98FF" : AddItem prfLower, "E806D359_D227_4312_846D_62B96FBC2A22" ' el-gr
AddItem prfLower, "C3B48231_4B0E_4AE9_9671_729335B80171" : AddItem prfLower, "50B38E0B_474B_435D_97C2_153D5737152C" ' en-us
AddItem prfLower, "FC91A339_D005_4119_91DD_99B85AA6AA30" : AddItem prfLower, "34971488_D8F8_4267_82E3_5F6ADCD0D3EC" ' es-es
AddItem prfLower, "02DA8FFD_DD12_4629_A6BC_B30A34ADB680" : AddItem prfLower, "FA05F924_6A0E_47F9_8790_20D48552FBEB" ' et-ee
AddItem prfLower, "CED8B983_4FE4_4E07_AE03_1CD60E287152" : AddItem prfLower, "9360DBB1_6499_4560_B98D_C5390FCD15E0" ' eu-es
AddItem prfLower, "B64C5B22_BB59_4818_8AF2_1CA9CF3AA672" : AddItem prfLower, "3A098248_3B84_4717_B1AC_9C6D37C755B8" ' fi-fi
AddItem prfLower, "7EBC6B8B_ED01_4BDB_9E32_D9DBD416832C" : AddItem prfLower, "0B4E9896_B091_41D8_9325_28B99C2D2E4D" ' fr-fr
AddItem prfLower, "8250BA61_2942_4A82_A438_CCA6B29C1AE9" : AddItem prfLower, "00511261_7E78_4266_9779_D52DE449C8C3" ' gl-es
AddItem prfLower, "95BB4366_FD82_43BE_9FC8_BF1789E2C8EF" : AddItem prfLower, "4DD4B7ED_C7DA_4CE8_AC52_35DA30CB2836" ' he-il
AddItem prfLower, "9CEADB2C_801F_4426_842E_D881F3C7746A" : AddItem prfLower, "7D6FD389_090E_41F6_9E29_2B08769E791E" ' hi-in
AddItem prfLower, "A3153BD5_EC5C_408D_9D5C_9244F8AF9251" : AddItem prfLower, "AA8CDF04_CB48_4C0D_BCB7_D4E612C1B3A2" ' hr-hr
AddItem prfLower, "4B0E52B8_5379_4F1F_9441_A37DC695259A" : AddItem prfLower, "24C166F5_687F_4551_9D8E_75818E943AD0" ' hu-hu
AddItem prfLower, "317B5B6F_A818_4676_B1CB_AD45E4407173" : AddItem prfLower, "27F43437_8308_496F_97B4_DF0308161E74" ' it-it
AddItem prfLower, "FBCA170F_CFDD_41E1_8011_78CD259A0AE8" : AddItem prfLower, "10E88B67_CE45_4392_998E_A8C6DE87716B" ' ja-jp
AddItem prfLower, "5D0924EA_A419_4605_9E82_49AEC67A16AF" : AddItem prfLower, "CCEF41A7_665D_4B65_923E_C1B98AA94238" ' ko-kr
AddItem prfLower, "66A12457_BED8_40DA_829C_14C48ADC54B2" : AddItem prfLower, "1BDEA061_BAA1_40F6_998F_FB5801D1239F" ' lt-lt
AddItem prfLower, "0F931EFB_990D_45AD_B003_DBF764039C03" : AddItem prfLower, "ECFFD2EC_FEF8_48B6_AF07_8DF49BD76520" ' lv-lv
AddItem prfLower, "A97FB3FA_8FC5_4E9F_AA38_6ACDD88F8AC6" : AddItem prfLower, "7C8745F1_7A81_4A7B_95D0_5FFA06D344A0" ' nb-no
AddItem prfLower, "3E1EE159_6854_4009_9036_9895AB59FD1D" : AddItem prfLower, "5BF29EAD_918C_45EB_AE9D_6202E3772532" ' nl-nl
AddItem prfLower, "1C195832_6A5B_4E4C_9089_7FF1777142DC" : AddItem prfLower, "4DF45E8D_DD89_46A7_8E12_A233A0B02E15" ' nn-no
AddItem prfLower, "28DA51E5_EB83_4DFE_814B_BBB4F1495A33" : AddItem prfLower, "FD3031FB_775B_43F7_9302_9D93508C2403" ' pl-pl
AddItem prfLower, "E311D00D_8F0F_4B0F_9099_C883D5549C2F" : AddItem prfLower, "E1F65D72_A232_4646_81FE_A628C83EC4C9" ' pt-br
AddItem prfLower, "9D6F680E_8330_435D_AD1D_13A3E41CD08E" : AddItem prfLower, "8DF848A5_A780_4B4F_9795_4FA05B683D21" ' pt-pt
AddItem prfLower, "C29847C2_4C86_4B33_9178_D06D0BF8B238" : AddItem prfLower, "859A6BC6_411A_4218_93A9_C150925C664F" ' ro-ro
AddItem prfLower, "007368D3_5AC8_451F_A80A_D5CA01645DFD" : AddItem prfLower, "19D58795_2E25_4A61_9BE6_C5251128E6F8" ' ru-ru
AddItem prfLower, "D8134FA3_EEE1_4D5E_B7DC_B0C08B6D4EA4" : AddItem prfLower, "240F1F66_7709_4362_A382_C7DAE1A93487" ' sk-sk
AddItem prfLower, "5BF85A63_D322_4A40_B418_02BC39C9CE6F" : AddItem prfLower, "DF90F7D7_C474_43E4_A733_AE5FFA94E8F9" ' sl-si
AddItem prfLower, "1CCD5E24_A9FE_4DF2_B047_941B45E5A6DE" : AddItem prfLower, "44C595EB_2727_424D_B3E5_29F4A5F52C37" ' sr-cyrl-cs
AddItem prfLower, "E4125F77_AFAA_428C_A3CA_17E7C7096A0E" : AddItem prfLower, "E3BE0027_55EE_4DEC_8DAB_9233C2136A84" ' sr-latn-cs
AddItem prfLower, "C108321D_0776_465C_8B82_1377267B5279" : AddItem prfLower, "1D9D541F_9D6C_4EE2_A5CD_7798F186535F" ' sv-se
AddItem prfLower, "8EAF0B0D_570C_4DDA_B489_BE33AE6C7C00" : AddItem prfLower, "DCACAD9F_C1C7_4D9D_A91A_024D9DFFCA26" ' th-th
AddItem prfLower, "CF267C83_8424_4857_8116_761F15B01A09" : AddItem prfLower, "DA6EBEE1_039A_491B_972B_A37E64745E33" ' tr-tr
AddItem prfLower, "C5090535_A260_4EF3_9CC9_BDFB4A08738E" : AddItem prfLower, "16A767D2_5C03_43FF_BF0E_A397875B0553" ' uk-ua
AddItem prfLower, "F7237AB5_0B12_4037_B684_03FDBB07C46D" : AddItem prfLower, "25FC73D2_37A1_4BCF_B27B_D281991BF69B" ' zh-cn
AddItem prfLower, "53060F96_9EA3_4779_862D_153D2AC2B0ED" : AddItem prfLower, "77A64944_DB1A_4CA6_9B88_03193F2EC2CB" ' zh-tw

sPatchesCC = Array()
sProductCC = ""
sProductCC = GetCompressedGuid(sProductCode)
'sRegClasses = "Installer\Products\"&sProductCC&"\Patches"
sRegCurrent = "Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\"&sProductCC&"\Patches"

sWI = oWSh.ExpandEnvironmentStrings("%SYSTEMROOT%\Installer") & "\"
fMSP = LCase(Mid(sProductCC,5,2) & Mid(sProductCC,9,3) & Mid(sProductCC,13,3)) & ".msp"

oReg.CreateKey HKLM, sRegCurrent

foundPatches = False
Set dbView = MsiDb.OpenView("SELECT `Property` FROM `Property`") : CheckError
dbView.Execute : CheckError
Do
	Set record = dbView.Fetch : CheckError
	If record Is Nothing Then Exit Do
	sPatchProperty = ""
	sPatchProperty = record.StringData(1)
	If InStr(1, sPatchProperty, "Patch._", vbTextCompare) > 0 Then
		foundPatches = True
		AddPatch Mid(sPatchProperty, 8, 36)
		AddExtra Mid(sPatchProperty, 8, 36)
		If Mid(sProductCode, 11, 4) = "001F" Then AddProof Mid(sPatchProperty, 8, 36)
	End If
Loop
dbView.Close

If foundPatches Then
	Wscript.Echo "Processing: " & sMsiFile
'	oReg.CreateKey HKCR, sRegClasses
'	oReg.SetMultiStringValue HKCR, sRegClasses , "Patches", sPatchesCC
	oReg.SetMultiStringValue HKLM, sRegCurrent , "AllPatches", sPatchesCC
	If Not oFso.FileExists(sWI & fMSP) Then
		If oFso.FileExists(sWI & "fffff.msp") Then
			oFso.CopyFile sWI & "fffff.msp", sWI & fMSP, True
		End If
	End If
End If

Wscript.Quit 0

Sub AddPatch(sPatchProperty)
	sPatchCode = ""
	sPatchCode = "{" & Replace(sPatchProperty, "_", "-") & "}"
	sPatchCC = ""
	sPatchCC = GetCompressedGuid(sPatchCode)
	sRegPatch1 = sRegCurrent&"\"&sPatchCC
	sRegPatch2 = "Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches\"&sPatchCC
	AddItem sPatchesCC, sPatchCC

	oReg.CreateKey HKLM, sRegPatch1
	oReg.CreateKey HKLM, sRegPatch2
	oReg.SetDWordValue  HKLM, sRegPatch1, "State", 1
	oReg.SetDWordValue  HKLM, sRegPatch1, "Uninstallable", 1
	oReg.SetDWordValue  HKLM, sRegPatch1, "MSI3", 1
	oReg.SetDWordValue  HKLM, sRegPatch1, "PatchType", 0
	oReg.SetDWordValue  HKLM, sRegPatch1, "LUAEnabled", 0
	oReg.SetStringValue HKLM, sRegPatch2, "LocalPackage", sWI & fMSP
End Sub

Sub AddExtra(sPatchProperty)
	Dim i
	For i = 0 To UBound(arrUpper)
	  If UCase(sPatchProperty) = arrUpper(i) Then AddPatch arrLower(i)
	Next
End Sub

Sub AddProof(sPatchProperty)
	Dim i
	For i = 0 To UBound(prfUpper)
	  If UCase(sPatchProperty) = prfUpper(i) Then AddPatch prfLower(i)
	Next
End Sub

Sub AddItem(arr, val)
	ReDim Preserve arr(UBound(arr) + 1)
	arr(UBound(arr)) = val
End Sub

Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not oMsi Is Nothing Then
		Set errRec = oMsi.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Fail message
End Sub

Sub Fail(message)
	Wscript.Echo message
	Wscript.Quit 2
End Sub

Function GetMsiProductCode
	GetMsiProductCode = ""
	Dim qView
	Set qView = MsiDb.OpenView("SELECT `Value` FROM Property WHERE `Property` = 'ProductCode'") : CheckError
	qView.Execute : CheckError
	Set record = qView.Fetch : CheckError
	GetMsiProductCode = record.StringData(1)
	qView.Close
End Function

Function GetCompressedGuid(sGuid)
	If NOT Len(sGuid) = 38 Then Exit Function
	Dim sCompGUID
	Dim i
	sCompGUID = StrReverse(Mid(sGuid, 2, 8))  & _
				StrReverse(Mid(sGuid, 11, 4)) & _
				StrReverse(Mid(sGuid, 16, 4)) 
	For i = 21 To 24
		If i Mod 2 Then
			sCompGUID = sCompGUID & Mid(sGuid, (i + 1), 1)
		Else
			sCompGUID = sCompGUID & Mid(sGuid, (i - 1), 1)
		End If
	Next
	For i = 26 To 37
		If i Mod 2 Then
			sCompGUID = sCompGUID & Mid(sGuid, (i - 1), 1)
		Else
			sCompGUID = sCompGUID & Mid(sGuid, (i + 1), 1)
		End If
	Next
	GetCompressedGuid = sCompGUID
End Function
