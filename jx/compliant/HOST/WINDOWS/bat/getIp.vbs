Function regTest(patern, str) 
    Dim regEx, retVal 
    Set regEx = New RegExp 
    regEx.Pattern = patern 
    regEx.IgnoreCase = False 
    retVal = regEx.Test(str) 
    If retVal Then 
        regTest = 1 
    Else 
        regTest = 0 
    End If 
End Function 
Public Function getRealIpAddress() 
    Set obj = WScript.CreateObject("WSCript.Shell") 
    Set result = obj.Exec("ipconfig") 
    strEcho = result.StdOut.ReadAll 
    Dim firstInput 
    Dim tempInputIp 
    Dim devRealIp	
    Dim autoSearchIp	
    Const IPREGEX = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])" 
    firstInput = 0 
    isCheckip = 1 
    Set regEx = New RegExp 
    regEx.Pattern = IPREGEX 
    regEx.IgnoreCase = False 
    Set retVala = regEx.Execute(strEcho) 
    If (retVala.Count > 0) Then 
        autoSearchIp = retVala.Item(0) 
    End If 
    Do While regTest(IPREGEX, devRealIp) = 0 And isCheckip = 1 
        isCheckip = 1 
        If Not firstInput = 1 Then 
            firstInput = 1 
            If Len(autoSearchIp) > 0 Then 
                devRealIp = InputBox("自动检测到的IP为:" & autoSearchIp & Chr(13) & Chr(10) & ",如准确,请输入-p,否则请输入准确的IP:", "请输入...") 
            Else 
                devRealIp = InputBox("请输入待检设备准确的IP:", "请输入...") 
            End If 
            tempInputIp = devRealIp 
        Else 
            If Len(autoSearchIp) > 0 Then 
                devRealIp = InputBox("输入正确的IP,自动检测到的IP为:" & autoSearchIp & ",如准确,请输入-p," & Chr(13) & Chr(10) & "否则请输入准确的IP,上次输入IP为:" & tempInputIp, "请输入...") 
            Else 
                devRealIp = InputBox("请输入正确的IP,上次输入IP为:" & tempInputIp, "请输入...") 
            End If 
            tempInputIp = devRealIp 
        End If 
        If(Len(devRealIp) = 0) Then 
            getRealIpAddress = 0 
            Exit Do 
        End If 
        If Trim(devRealIp) = "-p" Then 
            isCheckip = 0 
            devRealIp = autoSearchIp 
            getRealIpAddress = 1 
        End If 
    Loop 
    getRealIpAddress = devRealIp 
End Function 
Dim devRealIp 
devRealIp = getRealIpAddress 
If (Not IsNull(devRealIp) And Not IsEmpty(devRealIp) And "0" <> resultStr) Then 
    WScript.Echo devRealIp 
End If 
