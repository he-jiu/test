#$language = "VBScript"
#$interface = "1.0"

' 读取文件内容
public Function readFile(strName)
	srcFileName = strName
	resFileName = Replace(srcFileName, "scenario.bms", "res.txt")
	Dim sysFileObject
	Set sysFileObject = CreateObject("Scripting.FileSystemObject")
	If Not sysFileObject.FileExists(srcFileName) Then 
		Msgbox srcFileName & " not exist!"
		Exit Function 
	End If
	readFile = loadFile(srcFileName)
End Function

Function loadFile(filePath)
	On Error Resume next		'打开异常捕获
	Set asm = CreateObject("Adodb.Stream")
	asm.Type = 2
	asm.mode = 3
	asm.charset = "utf-8"
	asm.Open
	asm.LoadFromFile filePath
	loadFile = asm.readtext
	asm.close
	If Err.number <> 0 then	
		Dim sfo, fi
		Set sfo = CreateObject("Scripting.FileSystemObject")
		Set fi = sfo.OpenTextFile(filePath, 1)   	
		loadFile = fi.ReadAll
		fi.Close
	End If
	
	On Error goto 0				'关闭异常捕获
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
	public currScreen
	public currSession
	public currTabcap
	public currPath	
	Public devRealIp	'设备真实IP
	
	'执行任务
	public Function execTask(file)	
		
		Dim fileSystemObject
		Set fileSystemObject = CreateObject("Scripting.FileSystemObject")

		' 清空日志文件
		If currSession.Logging = True then
				currSession.Log False
		End If
		
		If fileSystemObject.FileExists(currSession.LogFileName) = True then
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
		Dim prompt
		prompt = currScreen.Get(currScreen.CurrentRow,1,currScreen.CurrentRow,currScreen.CurrentColumn)
		prompt = Trim(prompt)
		
		Dim isMore, strResult
		Dim taskFlag
		taskFlag = 0
		
		Dim iniFilePath

		'逐行执行脚本命令
		For each strLine in strLines
			If Len(strLine) > 0 Then							' 去除命令尾部的换行符
				If Right(strLine, 1) = Chr(13) Then
					strLine = Left(strLine, Len(strLine)-1)
				End If
			End If

			' 判断是否为标示符
			If Left(strLine,7) = "#piece#" Then					' 如果为标识符,直接写入
				If(taskFlag = 1) then							'判断是否是一个命令结束，把结果写入
					currScreen.WaitForString "!@#$",1           
					currSession.Log False
					
					strEcho = loadFile(currSession.LogFileName)
					if checkSpecial(strLine,strEcho,strEchoFormat) = 0 Then	'如果终止操作，删除result结果文件
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

				strResult = strResult & Right(strLine, Len(strLine)-6) & vbcrlf
				
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
												
				'登录数据库
				If(regTest("mysql -u -p", strLine) >0) Then
					Dim loginType, logoncmd, strpwd
					Do while(Len(loginType) = 0)
						loginType = crt.Dialog.Prompt("请选择登录MYSQL方式：" & Chr(13) & Chr(10) & "1、mysql -u<user> -p<password>" & Chr(13) & Chr(10) & "2、mysql -h<hostname> -P<port> -u<user> -p<password>" & Chr(13) & Chr(10) & "3、mysql -u<user> -p<password> -S mysql.sock" & Chr(13) & Chr(10) &"请输入1或2或3：", "choose", "", False)
					Loop
					If (loginType = "1") Then
						Do while(Len(logoncmd) = 0)
							logoncmd = crt.Dialog.Prompt("输入数据库用户名（如：root):", "Logon", "", FALSE)
						Loop
						currScreen.Send "./mysql -u" & logoncmd & " -p"	
						currScreen.Send chr(13)
						nResult = currScreen.WaitForString(":", 1)
						Do while(Len(strpwd) = 0)
							strpwd = crt.Dialog.Prompt("输入" & logoncmd & "用户的密码:", "Logon", "", True)
						Loop
						currScreen.Send strpwd
						currScreen.Send chr(13)
					ElseIf (loginType = "2") Then
						Dim hostName, port
						Do while(Len(hostName) = 0)
							hostName = crt.Dialog.Prompt("输入数据库主机名:", "Logon", "", FALSE)
						Loop
						Do while(Len(port) = 0)
							port = crt.Dialog.Prompt("输入数据库端口号:", "Logon", "", FALSE)
						Loop
						Do while(Len(logoncmd) = 0)
							logoncmd = crt.Dialog.Prompt("输入数据库用户名（如：root):", "Logon", "", FALSE)
						Loop
						currScreen.Send "./mysql -h" & hostName & " -P" & port & " -u" & logoncmd & " -p"
						currScreen.Send chr(13)
						nResult = currScreen.WaitForString(":", 1)
						Do while(Len(strpwd) = 0)
							strpwd = crt.Dialog.Prompt("输入" & logoncmd & "用户的密码:", "Logon", "", True)
						Loop
						currScreen.Send strpwd
						currScreen.Send chr(13)
					ElseIf (loginType = "3") Then
						Dim sock
						Do while(Len(logoncmd) = 0)
							logoncmd = crt.Dialog.Prompt("输入数据库用户名（如：root):", "Logon", "", FALSE)
						Loop
						Do while(Len(strpwd) = 0)
							strpwd = crt.Dialog.Prompt("输入" & logoncmd & "用户的密码:", "Logon", "", True)
						Loop
						Do while(Len(sock) = 0)
							sock = crt.Dialog.Prompt("输入sock文件路径（如/var/lib/mysql/mysql.sock）:", "Logon", "", FALSE)
						Loop
						currScreen.Send "./mysql -u" & logoncmd & " -p"	& strpwd & " -S " & sock
						currScreen.Send chr(13)
					End If					
					nResult = currScreen.WaitForString(">", 1)
					strLine = ""									
				End If
				'进入数据库安装路径
				If(regTest("INSTALL_PATH", strLine) = 1) Then
					Dim path
					Do while(Len(path) = 0)
						path = crt.Dialog.Prompt("输入数据库安装路径（如：/usr/local/mysql）:", "Path", "", FALSE)
					Loop
					If(Right(path,1) = Chr(47) Or Right(path,1) = Chr(92)) Then												'47 /  92 \
						path = Left(path,Len(path)-1)
					End If
					strLine = Replace (strLine, "$INSTALL_PATH", path)
					currScreen.Send	strLine
					currScreen.Send chr(13)
					currScreen.WaitForString "!@#$", 1
					prompt = currScreen.Get(currScreen.CurrentRow,1,currScreen.CurrentRow,currScreen.CurrentColumn)
					prompt = Trim(prompt)
					strLine = ""
				End If
				'设置数据库的CNF文件路径
				If(regTest("set\sINIFILE_PATH", strLine) = 1) Then
					Do while(Len(iniFilePath) = 0)
						iniFilePath = crt.Dialog.Prompt("输入数据库cnf路径（如：/usr/local/mysql/my.cnf）:", "Path", "", FALSE)
					Loop
					If(Right(iniFilePath,1) = Chr(47) Or Right(iniFilePath,1) = Chr(92)) Then												'47 /  92 \
						iniFilePath = Left(iniFilePath,Len(iniFilePath)-1)
					End If
					strLine = ""
				End If
				
				If Len(strLine)>0 Then
					strLine = Replace (strLine, "$INIFILE_PATH", iniFilePath)
					currScreen.Send strLine
					isMore = currScreen.WaitForString(strLine, 1)
					currScreen.Send Chr(13) 
					isMore = currScreen.WaitForStrings(">", prompt, "---- More ----", 10)
			    	If isMore = 3 Then
						Do While isMore = 3
							currScreen.Send Chr(13)
							isMore = currScreen.WaitForStrings(">", prompt, "---- More ----", 10)
						Loop
					End If
				End If
			End If
		Next
		resFile.Close
		changeResultName resFileName
	End Function

	'处理任务
	public Function process(currCrt)
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
		
		If(fileSystemObject.FolderExists(currPath & "\result") = False) then	' 创建结果文件目录
			fileSystemObject.createFolder(currPath & "\result")
		End If
		
		Dim file
		file = readFile(currPath & "\scenario.bms")		' 读取脚本文件				
		execTask(file)  ' 执行任务

		'删除日志文件
		If currSession.Logging = True then
				currSession.Log False
		End If
		If fileSystemObject.FileExists(currSession.LogFileName) = True then
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
				strEchoFormat = devRealIp & vbcrlf
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
	For i=1 to tabCount
		Dim taskHandler
		Set taskHandler = new TaskHandler
		crt.GetTab(i).Screen.Synchronous = True
		crt.GetTab(i).Screen.IgnoreEscape = True
		taskHandler.process crt.GetTab(i)
	Next
	MsgBox "执行结束！"
End Sub