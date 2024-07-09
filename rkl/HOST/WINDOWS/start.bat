@echo OFF
set date=%date:~0,10%
set date=%date:-=%
set date=%date:/=%
set time=%time:~0,8%
set time=%time::=%
if "%time:~0,1%"==" " set "time=0%time:~1%"
for /f "delims=" %%i in ('hostname') do set name=%%i
echo 脚本执行中，请稍等片刻......

::加入IP交互脚本
@set fVBSRandom=%random:~-5%
@set fVBS=lwf-SHG-Windows-.%fVBSRandom%.vbs
@rem ---------------------- vbs begin ----------------------
@echo Function regTest(patern, str) >%fVBS%
@echo Dim regEx, retVal >>%fVBS%
@echo Set regEx = New RegExp >>%fVBS%
@echo regEx.Pattern = patern >>%fVBS%
@echo regEx.IgnoreCase = False >>%fVBS%
@echo retVal = regEx.Test(str) >>%fVBS%
@echo If retVal Then >>%fVBS%
@echo regTest = 1 >>%fVBS%
@echo Else >>%fVBS%
@echo regTest = 0 >>%fVBS%
@echo End If >>%fVBS%
@echo End Function >>%fVBS%
@echo Public Function getRealIpAddress() >>%fVBS%
@echo Set obj = WScript.CreateObject("WSCript.Shell") >>%fVBS%
@echo Set result = obj.Exec("ipconfig") >>%fVBS%
@echo strEcho = result.StdOut.ReadAll >>%fVBS%
@echo Dim firstInput >>%fVBS%
@echo Dim tempInputIp >>%fVBS%
@echo Dim devRealIp	>>%fVBS%
@echo	Dim autoSearchIp	>>%fVBS%
@echo Const IPREGEX = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])" >>%fVBS%
@echo firstInput = 0 >>%fVBS%
@echo isCheckip = 1 >>%fVBS%
@echo Set regEx = New RegExp >>%fVBS%
@echo regEx.Pattern = IPREGEX >>%fVBS%
@echo regEx.IgnoreCase = False >>%fVBS%
@echo Set retVala = regEx.Execute(strEcho) >>%fVBS%
@echo If (retVala.Count ^> 0) Then >>%fVBS%
@echo autoSearchIp = retVala.Item(0) >>%fVBS%
@echo End If >>%fVBS%
@echo Do While regTest(IPREGEX, devRealIp) = 0 And isCheckip = 1 >>%fVBS%
@echo isCheckip = 1 >>%fVBS%
@echo If Not firstInput = 1 Then >>%fVBS%
@echo firstInput = 1 >>%fVBS%
@echo	If Len(autoSearchIp) ^> 0 Then >>%fVBS%
@echo	devRealIp = InputBox("自动检测到的IP为:" ^& autoSearchIp ^& Chr(13) ^& Chr(10) ^& ",如准确,请输入-p,否则请输入准确的IP:", "请输入...") >>%fVBS%
@echo	Else >>%fVBS%
@echo	devRealIp = InputBox("请输入待检设备准确的IP:", "请输入...") >>%fVBS%
@echo	End If >>%fVBS%
@echo tempInputIp = devRealIp >>%fVBS%
@echo Else >>%fVBS%
@echo	If Len(autoSearchIp) ^> 0 Then >>%fVBS%
@echo	devRealIp = InputBox("输入正确的IP,自动检测到的IP为:" ^& autoSearchIp ^& ",如准确,请输入-p," ^& Chr(13) ^& Chr(10) ^& "否则请输入准确的IP,上次输入IP为:" ^& tempInputIp, "请输入...") >>%fVBS%
@echo	Else >>%fVBS%
@echo	devRealIp = InputBox("请输入正确的IP,上次输入IP为:" ^& tempInputIp, "请输入...") >>%fVBS%
@echo	End If >>%fVBS%
@echo tempInputIp = devRealIp >>%fVBS%
@echo End If >>%fVBS%
@echo If(Len(devRealIp) = 0) Then >>%fVBS%
@echo getRealIpAddress = 0 >>%fVBS%
@echo Exit Do >>%fVBS%
@echo End If >>%fVBS%
@echo If Trim(devRealIp) = "-p" Then >>%fVBS%
@echo isCheckip = 0 >>%fVBS%
@echo devRealIp = autoSearchIp >>%fVBS%
@echo getRealIpAddress = 1 >>%fVBS%
@echo End If >>%fVBS%
::@echo If regTest(devRealIp ^& "\b", strEcho) = 0 And isCheckip = 1 And Len(autoSearchIp) > 0 Then >>%fVBS%
::@echo MsgBox "无法在回显结果中找到该IP地址：'" ^& devRealIp ^& "',请重新输入！" >>%fVBS%
::@echo devRealIp = 0 >>%fVBS%
::@echo End If >>%fVBS%
@echo Loop >>%fVBS%
@echo getRealIpAddress = devRealIp >>%fVBS%
@echo End Function >>%fVBS%
@echo Dim devRealIp >>%fVBS%
@echo devRealIp = getRealIpAddress >>%fVBS%
@echo If (Not IsNull(devRealIp) And Not IsEmpty(devRealIp) And "0" ^<^> resultStr) Then >>%fVBS%
@echo WScript.Echo devRealIp >>%fVBS%
@echo End If >>%fVBS%
@rem ---------------------- vbs end ----------------------
for /f %%a in ('cscript "%fVBS%" //nologo //e:vbscript') do set "realIp=%%a"
@del %fVBS%
if "%realIp%"=="" exit

if not exist "%~dp0pwdump8.exe" (echo ERROR : pwdump8.exe not exist, please check!!!
pause
exit
)

set result=%~dp0%realIp%_%date%%time%.result
echo equipment_type=HOST_WINDOWS 2>&1 | more > "%result%"
echo #equipment_name# 2>&1 | more >> "%result%"
hostname 2>&1 | more >> "%result%"
echo #equipment_name# 2>&1 | more >> "%result%"
echo #equipment_ip# 2>&1 | more >> "%result%"
echo %realIp% 2>&1 | more >> "%result%"
echo #equipment_ip# 2>&1 | more >> "%result%"

echo cm_item_code=#%%version#%% 2>&1 | more >> "%result%"
echo cm_item_code=#%%passwd#%% 2>&1 | more >> "%result%"

echo #%%version#%% 2>&1 | more >> "%result%"
ver 2>&1 | more >> "%result%"
echo #%%version#%% 2>&1 | more >> "%result%"

echo #%%passwd#%% 2>&1 | more >> "%result%"
wmic useraccount get name,disabled,lockout,LocalAccount 2>&1 | more >> "%result%"
echo wmic useraccount get name,disabled,lockout,LocalAccount 2>&1 | more >> "%result%"
"%~dp0pwdump.exe" -s "%systemroot%\system32\config\sam" "%systemroot%\system32\config\system" 2>&1 | more >> "%result%"
echo #%%passwd#%% 2>&1 | more >> "%result%"
