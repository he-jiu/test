#$language = "VBScript"
#$interface = "1.0"

' ===============================================================
' Description: 基于VBS的SecureCRT引导脚本，需根据情况修改静态常量
' Author:
' Version: 1.0
' ===============================================================

' 指令回显超时，单位：秒
Const ECHO_TIMEOUT = 2

' 指令回显more提示符
Const MORE_PROMPT = "--More--"

' 指令回显more翻页指令，vbCr(回车)或vbCrLf(回车换行)
Dim MORE_NEXT_CMD
MORE_NEXT_CMD = vbCr

' 自动解析IP优先匹配类型：4或6
Const IP_FIRST_MATCH = 4

' 脚本文件名
Const SCRIPT_FILE_NAME = "scenario.bms"

' 存放结果文件夹名
Const RESULT_FOLDER = "result"

' 结果文件扩展名
Const RESULT_FILE_EXTENSION = ".result"

' 行开始标识
Const LINE_START_SIGN = "#piece#"

' 目的IP标识
Const DEST_IP_FLAG = "#equipment_ip#"

' IPV4正则
Const IPREGEX_V4 = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])"

' IPV6正则
Const IPREGEX_V6 = "\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*"

' 略过IP检测标识
Const PASS_IP_SIGN = "-p"

' 文件不存在提示信息
Const NOT_EXIST = "不存在！"

' CRT配置错误提示信息
Dim CRT_CONFIG_MSG
CRT_CONFIG_MSG = "读取IP错误，请检查SecureCRT设置：" & vbCrLf & "(1) 会话选项->仿真->终端->Linux" & vbCrLf & "(2) 会话选项->外观->字符编码->UTF-8" & vbCrLf & "(3) 文件->关闭会话日志及会话原始日志"

' 对话框提示标题
Const DIALOG_PROMPT_TITLE = "请输入..."

' 未输入IP时检测错误提示信息
Const LOOP0_MATCHED_IP = "自动检测到的IP为：{MATCHED_IP}，如准确，请输入{PASS_IP_SIGN}，否则请输入准确的IP："
Const LOOP0_NONE_IP = "请输入待检设备准确的IP："

' 输入IP时检测错误提示信息
Const LOOPN_MATCHED_IP = "请输入正确的IP，自动检测到的IP为：{MATCHED_IP}，如准确，请输入{PASS_IP_SIGN}，否则请输入准确的IP，上次输入IP为：{LAST_INPUT_IP}"
Const LOOPN_NONE_IP = "请输入正确的IP，上次输入IP为：{LAST_INPUT_IP}"

' 检查结束提示消息
Const CHECK_OVER_MSG = "检查结束！"


' 替换CRT标签名内特殊字符
Public Function replaceTitle(currentTitle)
    currentTitle = replace(currentTitle, "/", "")
    currentTitle = replace(currentTitle, "\", "")
    currentTitle = replace(currentTitle, ":", "")
    currentTitle = replace(currentTitle, "*", "")
    currentTitle = replace(currentTitle, "?", "")
    currentTitle = replace(currentTitle, """", "")
    currentTitle = replace(currentTitle, "<", "")
    currentTitle = replace(currentTitle, ">", "")
    currentTitle = replace(currentTitle, "|", "")
    replaceTitle = currentTitle
End Function

' 读取文件内容
Public Function readFileContent(fileName)
	Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
	If Not fileSystemObject.FileExists(fileName) Then 
		MsgBox fileName & NOT_EXIST
		Exit Function
    End If
    ' 打开异常捕获
    On Error Resume Next		
	Set asm = CreateObject("Adodb.Stream")
	asm.Type = 2
	asm.mode = 3
	asm.charset = "utf-8"
	asm.Open
	asm.LoadFromFile fileName
	readFileContent = asm.readtext
	asm.close
	If Err.number <> 0 Then	
		Set fi = fileSystemObject.OpenTextFile(fileName, 1)   	
		readFileContent = fi.ReadAll
		fi.Close
    End If
    ' 关闭异常捕获
	On Error Goto 0
End Function

' 根据正则匹配字符串
Function regexTest(patern, str)
	Dim regEx, retVal		
	Set regEx = New RegExp		
	regEx.Pattern = patern        
	regEx.IgnoreCase = False		
	retVal = regEx.Test(str)	
	If retVal Then
		regexTest = 1
	Else
		regexTest = 0
	End If
End Function

' 根据正则解析IP返回第一个匹配地址
Function regexMatchFirstIp(echo)
    Set regex = New RegExp
    If IP_FIRST_MATCH = 4 Then
        regex.Pattern = IPREGEX_V4
    Else
        regex.Pattern = IPREGEX_V6
    End If
    regex.IgnoreCase = False
    Set retVala = regex.Execute(echo)
    If (retVala.Count > 0) Then
        regexMatchFirstIp = retVala.Item(0)				
    End If
End Function

' 获取当前时间，格式为：YYMMDDhhmmss
Function currentDatetime()
    Dim current, y, m, d, h, mm, s
    current = Now()
	y = Year(current)
	m = Month(current)
	d = Day(current)
	h = Hour(current)
	mm = Minute(current)
	s = Second(current)
	
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
	currentDatetime = y & m & d & h & mm & s	
End Function

' 处理类
Class Executor
    Private currentScreen, currentSession, currentTitle, currentPath
    Private fileSystemObject
	Private destRealIp	' 设备准确IP
	
	' 执行
	Public Sub exec(currentTab)
		Set currentSession = currentTab.Session
        Set currentScreen = currentTab.Screen
        
		If Not currentSession.Connected = True Then
			MsgBox "SecureCRT当前标签页连接异常，请检查！"
			Exit Sub
        End If

        ' 去除特殊字符
        currentTitle = replaceTitle(currentTab.Caption)

        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        
        ' 当前文件路径
		currentPath = fileSystemObject.getFolder(".").Path
        
        ' 日志文件命名
		currentSession.LogFileName = currentPath & "\" & currentTitle & "_" & currentDatetime() & ".log"
        
        ' 创建结果文件目录
		If(fileSystemObject.FolderExists(currentPath & "\" & RESULT_FOLDER) = False) Then
			fileSystemObject.createFolder(currentPath & "\" & RESULT_FOLDER)
        End If
        
        ' 执行任务
		execScript readFileContent(currentPath & "\" & SCRIPT_FILE_NAME)
		
		'删除日志文件
		If currentSession.Logging = True Then
			currentSession.Log False
		End If
		If fileSystemObject.FileExists(currentSession.LogFileName) = True Then
			fileSystemObject.DeleteFile currentSession.LogFileName
		End If		
    End Sub
    
    '执行脚本
	Private Sub execScript(scriptContent)		
		' 清空日志文件
		If currentSession.Logging = True Then
			currentSession.Log False
		End If
		If fileSystemObject.FileExists(currentSession.LogFileName) = True Then
			fileSystemObject.DeleteFile currentSession.LogFileName
		End If 
		
		' 创建结果文件
		Dim resultFile
        resultFile = currentPath & "\" & RESULT_FOLDER & "\" &  currentTitle & "_" & currentDatetime() & RESULT_FILE_EXTENSION		
		fileSystemObject.CreateTextFile resultFile , True
		Set resultFileObject = fileSystemObject.OpenTextFile(resultFile, 2)
		
		' 获取提示符信息
		Dim prompt
		prompt = Trim(currentScreen.Get(currentScreen.CurrentRow, 1, currentScreen.CurrentRow, currentScreen.CurrentColumn))
		
        currentScreen.Synchronous = True

        Dim execFlag
        ' 命令执行标识变量
        execFlag = 0
        ' 逐行执行脚本命令
        For Each line In Split(scriptContent, vbLf)
            If execScriptLine(line, execFlag, resultFile, resultFileObject, prompt) > 0 Then
                Exit For
            End If
		Next
		resultFileObject.Close
' 文件修改名称
		resultFileN = currentPath & "\" & RESULT_FOLDER & "\" & destRealIp & "_" &  currentDatetime() & RESULT_FILE_EXTENSION
    ' Set fileSystemObjectN = CreateObject("Scripting.FileSystemObject")
		fileSystemObject.MoveFile resultFile, resultFileN
	End Sub
    
    ' 执行脚本行
    Private Function execScriptLine(line, execFlag, resultFile, resultFileObject, prompt)
        Dim echoMore, lineResult
        If Len(line) > 0 And Right(line, 1) = vbCr Then
            ' 去除末尾换行符
            line = Left(line, Len(line)-1)
        End If
        If Left(line, Len(LINE_START_SIGN)) = LINE_START_SIGN Then
            ' 如果以标识符开头
            If execFlag = 1 Then
                ' 如果是命令结束，则读取日志内容
                currentScreen.WaitForString prompt, ECHO_TIMEOUT
                currentSession.Log False		
                echo = readFileContent(currentSession.LogFileName)
                if processEcho(line, echo, echoFormat) = 0 Then
                    ' 对回显进行特殊处理，如返回0则表示终止操作
                    resultFileObject.Close
                    fileSystemObject.DeleteFile(resultFile)
                    execScriptLine = 1
                    Exit Function
                End If
                If Not Len(echoFormat) = 0 Then
                    lineResult = lineResult & echoFormat
                Else
                    lineResult = lineResult & echo
                End If
                execFlag = 0
            End If           
            lineResult = lineResult & Right(line, Len(line) - Len(LINE_START_SIGN)) & vbCrLf           
            If Len(lineResult) > 0 Then
                ' 将结果写入结果文件
                On Error Resume Next
                Err.Clear
                resultFileObject.Write lineResult
                If Err.number <> 0 Then					
                    resultFileObject.Write Err.Description & vbCrLf
                    If Len(Right(line, Len(line) - Len(LINE_START_SIGN))) > 0 Then
                        resultFileObject.Write Right(line, Len(line) - Len(LINE_START_SIGN)) & vbCrLf
                    End If
                End If
                On Error Goto 0
            End If
        Else
            ' 如果不以标识符开头，则为一行新命令开始，打开记录日志开关
            If execFlag = 0 Then
                execFlag = 1
                currentSession.Log True
            End If            
            If Len(line) > 0 Then
                ' 发送命令内容
                currentScreen.Send line
                currentScreen.WaitForString line, ECHO_TIMEOUT		
                currentScreen.Send vbCrLf
                echoMore = currentScreen.WaitForStrings(prompt, MORE_PROMPT, ECHO_TIMEOUT)
                If echoMore = 2 Then
                    Do While echoMore = 2
                        currentScreen.Send MORE_NEXT_CMD
                        echoMore = currentScreen.WaitForStrings(prompt, MORE_PROMPT, ECHO_TIMEOUT)
                    Loop
                End If
            End If
        End If
    End Function

	' 对回显进行特殊处理
	Private Function processEcho(line, echo, echoFormat)
        echoFormat = Space(0)
		' 对设备IP特殊处理
		If(regexTest(DEST_IP_FLAG, line) = 1) Then
			' 获取真实IP
			If analysisRealIp(echo) = 1 Then
				echoFormat = destRealIp & vbCrLf
			Else
				destRealIp = 0
				processEcho = 0
				Exit Function 
			End If
        End If
        processEcho = 1
	End Function
		
	' 获取真实IP
    Private Function analysisRealIp(echo)
        analysisRealIp = 1
		If Len(echo) = 0 Then 
            MsgBox CRT_CONFIG_MSG
            analysisRealIp = 0
			Exit Function
        End If
        Dim firstLoop, matchedIp, message
		matchedIp = regexMatchFirstIp(echo)
		Do While regexTest(IPREGEX_V4, destRealIp) = 0 And regexTest(IPREGEX_V6, destRealIp) = 0
			If Not firstLoop = 1 Then
				firstLoop = 1
                If Len(matchedIp) > 0 Then                   
                    message = Replace(LOOP0_MATCHED_IP, "{MATCHED_IP}", matchedIp)
                    message = Replace(message, "{PASS_IP_SIGN}", PASS_IP_SIGN)
                Else
                	message = LOOP0_NONE_IP
                End If
                destRealIp = crt.Dialog.Prompt(message, DIALOG_PROMPT_TITLE, "", False)
			Else
                If Len(matchedIp) > 0 Then
                    message = Replace(LOOPN_MATCHED_IP, "{MATCHED_IP}", matchedIp)
                    message = Replace(message, "{PASS_IP_SIGN}", PASS_IP_SIGN)
                    message = Replace(message, "{LAST_INPUT_IP}", destRealIp)
                Else
                    message = Replace(LOOPN_NONE_IP, "{LAST_INPUT_IP}", destRealIp)
                End If
                destRealIp = crt.Dialog.Prompt(message, DIALOG_PROMPT_TITLE, "", False)
            End If
			If Len(destRealIp) = 0 Then
				analysisRealIp = 0
				Exit Do 
            End If
			If Trim(destRealIp) = PASS_IP_SIGN Then
				destRealIp = Trim(matchedIp)
                analysisRealIp = 1
                Exit Do 
			End If
		Loop
	End Function
	
End Class

'主函数
Sub main
	For i = 1 To crt.GetTabCount
		Dim executor
		Set executor = New Executor
		crt.GetTab(i).Screen.Synchronous = True
		crt.GetTab(i).Screen.IgnoreEscape = True
		executor.exec crt.GetTab(i)
	Next
	MsgBox CHECK_OVER_MSG
End Sub
