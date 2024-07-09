#$language = "VBScript"
#$interface = "1.0"

' 读取文件内容
Public Function readFile(strName)
    srcFileName = strName
    resFileName = Replace(srcFileName, "scenario.bms", "res.txt")
    Dim sysFileObject
    Set sysFileObject = CreateObject("Scripting.FileSystemObject")
    If Not sysFileObject.FileExists(srcFileName) Then 
        MsgBox srcFileName & " not exist!"
        Exit Function 
    End If
    readFile = loadFile(srcFileName)
End Function

Function loadFile(filePath)
    On Error Resume Next		'打开异常捕获
    Set asm = CreateObject("Adodb.Stream")
    asm.Type = 2
    asm.mode = 3
    asm.charset = "utf-8"
    asm.Open
    asm.LoadFromFile filePath
    loadFile = asm.readtext
    asm.close
    If Err.number <> 0 Then	
        Dim sfo, fi
        Set sfo = CreateObject("Scripting.FileSystemObject")
        Set fi = sfo.OpenTextFile(filePath, 1)   	
        loadFile = fi.ReadAll
        fi.Close
    End If
    
    On Error Goto 0				'关闭异常捕获
End Function


'利用正则匹配字符串
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


' 把指定的日期格式转换为：YYMMDDhhmmss
Function dateFormat(dateTime)
    Dim y, m, d, h, mm, s
    
    y = Year(datetime)
    m = Month(datetime)
    d = Day(datetime)
    h = Hour(datetime)
    mm = Minute(datetime)
    s = Second(datetime)
    
    If Len(m) = 1 Then
        m = "0" & m
    End If
    If Len(d) = 1 Then
        d = "0" & d
    End If
    If Len(h) = 1 Then
        h = "0" & h
    End If
    If Len(mm) = 1 Then
        mm = "0" & mm
    End If
    If Len(s) = 1 Then
        s = "0" & s
    End If
    
    dateFormat = y & m & d & h & mm & s
    
End Function


' 任务处理器
Class TaskHandler
    Public currScreen
    Public currSession
    Public currTabcap
    Public currPath	
    Public devRealIp	'设备真实IP
    Public prompt
    Public spacePageOver
    
    '执行任务
    Public Function execTask(file)	
        
        Dim fileSystemObject
        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        
        ' 清空日志文件
        If currSession.Logging = True Then
            currSession.Log False
        End If
        
        If fileSystemObject.FileExists(currSession.LogFileName) = True Then
            fileSystemObject.DeleteFile currSession.LogFileName
        End If 
        
        '创建结果文件
        Dim resFile
        Dim resFileName
        resFileName = currPath & "\result\" & "temp_" & dateFormat(Now()) & ".result"
        
        fileSystemObject.CreateTextFile resFileName , True
        Set resFile = fileSystemObject.OpenTextFile(resFileName, 2)
        
        '定义操作变量
        Dim strLines
        strLines = Split(file, Chr(10))
        currScreen.Synchronous = True
        
        ' 获取提示符信息
        prompt = currScreen.Get(currScreen.CurrentRow,1,currScreen.CurrentRow,currScreen.CurrentColumn)
        prompt = Trim(prompt)
        
        Dim isMore, strResult
        Dim taskFlag
        taskFlag = 0
        
        isError = 0
		spacePageOver = 0
        
        '逐行执行脚本命令
        For Each strLine In strLines
            If Len(strLine) > 0 Then							' 去除命令尾部的换行符
                If Right(strLine, 1) = Chr(13) Then
                    strLine = Left(strLine, Len(strLine)-1)
                End If
            End If
            
            ' 判断是否为标示符
            If Left(strLine,7) = "#piece#" Then					' 如果为标识符,直接写入
                If(taskFlag = 1) Then							'判断是否是一个命令结束，把结果写入
                    currScreen.WaitForString "!@#$",1           
                    currSession.Log False
                    
                    strEcho = loadFile(currSession.LogFileName)
                    If checkSpecial(strLine,strEcho,strEchoFormat) = 0 Then	'如果终止操作，删除result结果文件
                        isError = 1
                        resFile.Close
                        fileSystemObject.DeleteFile(resFileName)
                        Exit For
                    End If
                    If Not Len(strEchoFormat) = 0 Then
                        strResult = strResult & strEchoFormat
                    Else
                        strResult = strResult & strEcho
                    End If
                    
                    taskFlag = 0
                End If
                
                strResult = strResult & Right(strLine, Len(strLine)-6) & vbCrLf
                
                If Len(strResult) > 0 Then
                    On Error Resume Next
                    Err.Clear
                    resFile.Write strResult
                    If Err.number <> 0 Then					
                        resFile.Write Err.Description & vbCrLf
                        If Len(Right(strLine, Len(strLine)-6))>0 Then
                            resFile.Write Right(strLine, Len(strLine)-6) & vbCrLf
                        End If
                    End If
                    On Error Goto 0
                End If
                strResult = Space(0)	' 清空结果字符串
            Else						' 要发送的脚本
                If(taskFlag = 0) Then	' 一个命令开始，开始记录结果
                    taskFlag = 1
                    currSession.Log True
                End If	
                
                If Len(strLine)>0 Then
                    currScreen.Send strLine
                    isMore = currScreen.WaitForString(strLine, 2)
                    currScreen.Send Chr(10)&Chr(13) 
                    currScreen.WaitForCursor
                    Dim matchIndex
					Dim tempPrompt
                    Do
						currScreen.ReadString prompt, "Input 'n': next page, others: exit", "Press Enter to continue or <ctrl-z> to abort", "> }:", "--More--", "--- More ---", "<--- More --->", "---- More ----", "--- more ---", "---more---", "---(more", "--- More", "--- more", "--More-- or (q)uit", "--More or (q)uit current module or <ctrl-z> to abort", 1
						matchIndex = currScreen.MatchIndex
						If matchIndex = 0 Then
							If spacePageOver = 1 Then
								spacePageOver = 0
								currScreen.Send Chr(13)
							End If
							tempPrompt = currScreen.Get(currScreen.CurrentRow,1,currScreen.CurrentRow,currScreen.CurrentColumn)
							tempPrompt = Trim(tempPrompt)
							If StrComp(prompt,tempPrompt)=0 Then	
								Exit Do
							Else
								If tempPrompt = ">" Or (Right(tempPrompt,1) = ">" And InStr(tempPrompt, "<") = 0) Then
									Exit Do
								End If
								
							End If
						ElseIf matchIndex = 1 Then
							Exit Do
						ElseIf matchIndex = 2 Then
							currScreen.Send "n"
						ElseIf matchIndex = 3 Or matchIndex = 4 Then
							currScreen.Send Chr(13)
						Else
							spacePageOver = 1
							currScreen.Send Chr(32)
						End If
					Loop
                End If
            End If
        Next
        If(isError = 0) Then
			resFile.Close
			changeResultName resFileName
		End If
    End Function
    
    '处理任务
    Public Function process(currCrt)
        Set currSession = currCrt.Session
        Set currScreen = currCrt.Screen
        currTabcap = currCrt.Caption
        
        If Not currSession.Connected = True Then
            MsgBox "SecureCRT连接异常，请检查！"
            Exit Function
        End If
        
        Dim fileSystemObject
        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        currPath = fileSystemObject.getFolder(".").Path		' 获取当前文件路径
        
        Dim logFilePath
        logFilePath = currSession.LogFileName
        currSession.LogFileName = currPath & "\" & currTabcap & ".log"	' 创建日志文件
        
        If(fileSystemObject.FolderExists(currPath & "\result") = False) Then	' 创建结果文件目录
            fileSystemObject.createFolder(currPath & "\result")
        End If
        
        Dim file
        file = readFile(currPath & "\scenario.bms")		' 读取脚本文件				
        execTask(file)  ' 执行任务
        
        '删除日志文件
        If currSession.Logging = True Then
            currSession.Log False
        End If
        If fileSystemObject.FileExists(currSession.LogFileName) = True Then
            fileSystemObject.DeleteFile currSession.LogFileName
        End If
        
    End Function
    
    '特殊处理
    Function checkSpecial(strLine,strEcho,strEchoFormat)
        checkSpecial = 1
        strEchoFormat = Space(0)
        '对设备IP特殊处理
        If(regTest("#equipment_ip#", strLine) = 1) Then
            '提示用户输入IP
            If getRealIpAddress(strEcho) = 1 Then
                strEchoFormat = devRealIp & vbCrLf
            Else
                devRealIp = 0
                checkSpecial = 0
                Exit Function 
            End If
        End If
    End Function
    
    
    '取真实IP地址
    Public Function getRealIpAddress(strEcho)
        Dim firstInput	'第一次输入IP标识
        Dim tempInputIp	'输入的临时IP 做为上次输入的提示
        Dim autoSearchIp	'自动检测到的IP
        Const IPREGEX = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])"
        firstInput = 0
        getRealIpAddress = 1
        If Not devRealIp = 0 Then
            Exit Function
        End If
        If Len(strEcho) = 0 Then 
            Dim configPrompt
            configPrompt = "读取IP错误,请检查SecureCRT设置:" & Chr(13) & "(1)会话选项->仿真->终端->Linux;" & Chr(13) & "(2)会话选项->外观->字符编码->UTF-8;" & Chr(13) & "(3)文件->关闭会话日志及会话原始日志."
            MsgBox configPrompt
            getRealIpAddress = 0
            Exit Function
        End If
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
                    promptContext = "自动检测到的IP为:" & autoSearchIp & ",如准确,请输入-p," & Chr(13) & Chr(10) & "否则请输入准确的IP:"
                Else
                    promptContext = "请输入待检设备准确的IP:"
                End If
                devRealIp = crt.Dialog.Prompt(promptContext, "请输入...", "", False)
                tempInputIp = devRealIp
            Else
                If Len(autoSearchIp) > 0 Then
                    promptContext = "输入正确的IP,自动检测到的IP为:" & autoSearchIp & ",如准确,请输入-p," & Chr(13) & Chr(10) & "否则请输入准确的IP,上次输入IP为:" & tempInputIp & ""
                Else
                    promptContext = "请输入正确的IP,上次输入IP为:" & tempInputIp & ""
                End If
                devRealIp = crt.Dialog.Prompt(promptContext, "请输入...", "", False)
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
            '			If regTest(devRealIp & "\b", strEcho) = 0 And isCheckip = 1 And Len(autoSearchIp) > 0 Then 
            '				msgbox "无法在回显结果中找到该IP地址：'" & devRealIp & "',请重新输入！"
            '				devRealIp = 0
            '			End If
        Loop
    End Function
    
    '修改结果文件名格式为 IP_时间.result
    Public Function changeResultName(resFileName)
        Dim fileSystemObject
        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        If (fileSystemObject.FileExists(resFileName) = True) Then
            Dim newResFileName
            newResFileName = currPath & "\result\" & devRealIp & "_" & dateFormat(Now()) & ".result"
            fileSystemObject.MoveFile resFileName, newResFileName
        End If
    End Function
    
End Class

'主函数
Sub main
    Dim tabCount
    tabCount = crt.GetTabCount
    For i=1 To tabCount
        Dim taskHandler
        Set taskHandler = New TaskHandler
        crt.GetTab(i).Screen.Synchronous = True
        crt.GetTab(i).Screen.IgnoreEscape = True
        taskHandler.process crt.GetTab(i)
    Next
    MsgBox "执行结束！"
End Sub
