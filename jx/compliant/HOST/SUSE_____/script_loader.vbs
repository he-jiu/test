#$language = "VBScript"
#$interface = "1.0"

' ===============================================================
' Description: ����VBS��SecureCRT�����ű������������޸ľ�̬����
' Author:
' Version: 1.0
' ===============================================================

' ָ����Գ�ʱ����λ����
Const ECHO_TIMEOUT = 2

' ָ�����more��ʾ��
Const MORE_PROMPT = "--More--"

' ָ�����more��ҳָ�vbCr(�س�)��vbCrLf(�س�����)
Dim MORE_NEXT_CMD
MORE_NEXT_CMD = vbCr

' �Զ�����IP����ƥ�����ͣ�4��6
Const IP_FIRST_MATCH = 4

' �ű��ļ���
Const SCRIPT_FILE_NAME = "scenario.bms"

' ��Ž���ļ�����
Const RESULT_FOLDER = "result"

' ����ļ���չ��
Const RESULT_FILE_EXTENSION = ".result"

' �п�ʼ��ʶ
Const LINE_START_SIGN = "#piece#"

' Ŀ��IP��ʶ
Const DEST_IP_FLAG = "#equipment_ip#"

' IPV4����
Const IPREGEX_V4 = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])"

' IPV6����
Const IPREGEX_V6 = "\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*"

' �Թ�IP����ʶ
Const PASS_IP_SIGN = "-p"

' �ļ���������ʾ��Ϣ
Const NOT_EXIST = "�����ڣ�"

' CRT���ô�����ʾ��Ϣ
Dim CRT_CONFIG_MSG
CRT_CONFIG_MSG = "��ȡIP��������SecureCRT���ã�" & vbCrLf & "(1) �Ựѡ��->����->�ն�->Linux" & vbCrLf & "(2) �Ựѡ��->���->�ַ�����->UTF-8" & vbCrLf & "(3) �ļ�->�رջỰ��־���Ựԭʼ��־"

' �Ի�����ʾ����
Const DIALOG_PROMPT_TITLE = "������..."

' δ����IPʱ��������ʾ��Ϣ
Const LOOP0_MATCHED_IP = "�Զ���⵽��IPΪ��{MATCHED_IP}����׼ȷ��������{PASS_IP_SIGN}������������׼ȷ��IP��"
Const LOOP0_NONE_IP = "����������豸׼ȷ��IP��"

' ����IPʱ��������ʾ��Ϣ
Const LOOPN_MATCHED_IP = "��������ȷ��IP���Զ���⵽��IPΪ��{MATCHED_IP}����׼ȷ��������{PASS_IP_SIGN}������������׼ȷ��IP���ϴ�����IPΪ��{LAST_INPUT_IP}"
Const LOOPN_NONE_IP = "��������ȷ��IP���ϴ�����IPΪ��{LAST_INPUT_IP}"

' ��������ʾ��Ϣ
Const CHECK_OVER_MSG = "��������"


' �滻CRT��ǩ���������ַ�
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

' ��ȡ�ļ�����
Public Function readFileContent(fileName)
	Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
	If Not fileSystemObject.FileExists(fileName) Then 
		MsgBox fileName & NOT_EXIST
		Exit Function
    End If
    ' ���쳣����
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
    ' �ر��쳣����
	On Error Goto 0
End Function

' ��������ƥ���ַ���
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

' �����������IP���ص�һ��ƥ���ַ
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

' ��ȡ��ǰʱ�䣬��ʽΪ��YYMMDDhhmmss
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

' ������
Class Executor
    Private currentScreen, currentSession, currentTitle, currentPath
    Private fileSystemObject
	Private destRealIp	' �豸׼ȷIP
	
	' ִ��
	Public Sub exec(currentTab)
		Set currentSession = currentTab.Session
        Set currentScreen = currentTab.Screen
        
		If Not currentSession.Connected = True Then
			MsgBox "SecureCRT��ǰ��ǩҳ�����쳣�����飡"
			Exit Sub
        End If

        ' ȥ�������ַ�
        currentTitle = replaceTitle(currentTab.Caption)

        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        
        ' ��ǰ�ļ�·��
		currentPath = fileSystemObject.getFolder(".").Path
        
        ' ��־�ļ�����
		currentSession.LogFileName = currentPath & "\" & currentTitle & "_" & currentDatetime() & ".log"
        
        ' ��������ļ�Ŀ¼
		If(fileSystemObject.FolderExists(currentPath & "\" & RESULT_FOLDER) = False) Then
			fileSystemObject.createFolder(currentPath & "\" & RESULT_FOLDER)
        End If
        
        ' ִ������
		execScript readFileContent(currentPath & "\" & SCRIPT_FILE_NAME)
		
		'ɾ����־�ļ�
		If currentSession.Logging = True Then
			currentSession.Log False
		End If
		If fileSystemObject.FileExists(currentSession.LogFileName) = True Then
			fileSystemObject.DeleteFile currentSession.LogFileName
		End If		
    End Sub
    
    'ִ�нű�
	Private Sub execScript(scriptContent)		
		' �����־�ļ�
		If currentSession.Logging = True Then
			currentSession.Log False
		End If
		If fileSystemObject.FileExists(currentSession.LogFileName) = True Then
			fileSystemObject.DeleteFile currentSession.LogFileName
		End If 
		
		' ��������ļ�
		Dim resultFile
        resultFile = currentPath & "\" & RESULT_FOLDER & "\" &  currentTitle & "_" & currentDatetime() & RESULT_FILE_EXTENSION		
		fileSystemObject.CreateTextFile resultFile , True
		Set resultFileObject = fileSystemObject.OpenTextFile(resultFile, 2)
		
		' ��ȡ��ʾ����Ϣ
		Dim prompt
		prompt = Trim(currentScreen.Get(currentScreen.CurrentRow, 1, currentScreen.CurrentRow, currentScreen.CurrentColumn))
		
        currentScreen.Synchronous = True

        Dim execFlag
        ' ����ִ�б�ʶ����
        execFlag = 0
        ' ����ִ�нű�����
        For Each line In Split(scriptContent, vbLf)
            If execScriptLine(line, execFlag, resultFile, resultFileObject, prompt) > 0 Then
                Exit For
            End If
		Next
		resultFileObject.Close
' �ļ��޸�����
		resultFileN = currentPath & "\" & RESULT_FOLDER & "\" & destRealIp & "_" &  currentDatetime() & RESULT_FILE_EXTENSION
    ' Set fileSystemObjectN = CreateObject("Scripting.FileSystemObject")
		fileSystemObject.MoveFile resultFile, resultFileN
	End Sub
    
    ' ִ�нű���
    Private Function execScriptLine(line, execFlag, resultFile, resultFileObject, prompt)
        Dim echoMore, lineResult
        If Len(line) > 0 And Right(line, 1) = vbCr Then
            ' ȥ��ĩβ���з�
            line = Left(line, Len(line)-1)
        End If
        If Left(line, Len(LINE_START_SIGN)) = LINE_START_SIGN Then
            ' ����Ա�ʶ����ͷ
            If execFlag = 1 Then
                ' �����������������ȡ��־����
                currentScreen.WaitForString prompt, ECHO_TIMEOUT
                currentSession.Log False		
                echo = readFileContent(currentSession.LogFileName)
                if processEcho(line, echo, echoFormat) = 0 Then
                    ' �Ի��Խ������⴦���緵��0���ʾ��ֹ����
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
                ' �����д�����ļ�
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
            ' ������Ա�ʶ����ͷ����Ϊһ�������ʼ���򿪼�¼��־����
            If execFlag = 0 Then
                execFlag = 1
                currentSession.Log True
            End If            
            If Len(line) > 0 Then
                ' ������������
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

	' �Ի��Խ������⴦��
	Private Function processEcho(line, echo, echoFormat)
        echoFormat = Space(0)
		' ���豸IP���⴦��
		If(regexTest(DEST_IP_FLAG, line) = 1) Then
			' ��ȡ��ʵIP
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
		
	' ��ȡ��ʵIP
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

'������
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
