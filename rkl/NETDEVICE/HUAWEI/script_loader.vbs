#$language = "VBScript"
#$interface = "1.0"

' ��ȡ�ļ�����
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
    On Error Resume Next		'���쳣����
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
    
    On Error Goto 0				'�ر��쳣����
End Function


'��������ƥ���ַ���
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


' ��ָ�������ڸ�ʽת��Ϊ��YYMMDDhhmmss
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


' ��������
Class TaskHandler
    Public currScreen
    Public currSession
    Public currTabcap
    Public currPath	
    Public devRealIp	'�豸��ʵIP
    Public prompt
    Public spacePageOver
    
    'ִ������
    Public Function execTask(file)	
        
        Dim fileSystemObject
        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        
        ' �����־�ļ�
        If currSession.Logging = True Then
            currSession.Log False
        End If
        
        If fileSystemObject.FileExists(currSession.LogFileName) = True Then
            fileSystemObject.DeleteFile currSession.LogFileName
        End If 
        
        '��������ļ�
        Dim resFile
        Dim resFileName
        resFileName = currPath & "\result\" & "temp_" & dateFormat(Now()) & ".result"
        
        fileSystemObject.CreateTextFile resFileName , True
        Set resFile = fileSystemObject.OpenTextFile(resFileName, 2)
        
        '�����������
        Dim strLines
        strLines = Split(file, Chr(10))
        currScreen.Synchronous = True
        
        ' ��ȡ��ʾ����Ϣ
        prompt = currScreen.Get(currScreen.CurrentRow,1,currScreen.CurrentRow,currScreen.CurrentColumn)
        prompt = Trim(prompt)
        
        Dim isMore, strResult
        Dim taskFlag
        taskFlag = 0
        
        isError = 0
		spacePageOver = 0
        
        '����ִ�нű�����
        For Each strLine In strLines
            If Len(strLine) > 0 Then							' ȥ������β���Ļ��з�
                If Right(strLine, 1) = Chr(13) Then
                    strLine = Left(strLine, Len(strLine)-1)
                End If
            End If
            
            ' �ж��Ƿ�Ϊ��ʾ��
            If Left(strLine,7) = "#piece#" Then					' ���Ϊ��ʶ��,ֱ��д��
                If(taskFlag = 1) Then							'�ж��Ƿ���һ������������ѽ��д��
                    currScreen.WaitForString "!@#$",1           
                    currSession.Log False
                    
                    strEcho = loadFile(currSession.LogFileName)
                    If checkSpecial(strLine,strEcho,strEchoFormat) = 0 Then	'�����ֹ������ɾ��result����ļ�
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
                strResult = Space(0)	' ��ս���ַ���
            Else						' Ҫ���͵Ľű�
                If(taskFlag = 0) Then	' һ�����ʼ����ʼ��¼���
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
    
    '��������
    Public Function process(currCrt)
        Set currSession = currCrt.Session
        Set currScreen = currCrt.Screen
        currTabcap = currCrt.Caption
        
        If Not currSession.Connected = True Then
            MsgBox "SecureCRT�����쳣�����飡"
            Exit Function
        End If
        
        Dim fileSystemObject
        Set fileSystemObject = CreateObject("Scripting.FileSystemObject")
        currPath = fileSystemObject.getFolder(".").Path		' ��ȡ��ǰ�ļ�·��
        
        Dim logFilePath
        logFilePath = currSession.LogFileName
        currSession.LogFileName = currPath & "\" & currTabcap & ".log"	' ������־�ļ�
        
        If(fileSystemObject.FolderExists(currPath & "\result") = False) Then	' ��������ļ�Ŀ¼
            fileSystemObject.createFolder(currPath & "\result")
        End If
        
        Dim file
        file = readFile(currPath & "\scenario.bms")		' ��ȡ�ű��ļ�				
        execTask(file)  ' ִ������
        
        'ɾ����־�ļ�
        If currSession.Logging = True Then
            currSession.Log False
        End If
        If fileSystemObject.FileExists(currSession.LogFileName) = True Then
            fileSystemObject.DeleteFile currSession.LogFileName
        End If
        
    End Function
    
    '���⴦��
    Function checkSpecial(strLine,strEcho,strEchoFormat)
        checkSpecial = 1
        strEchoFormat = Space(0)
        '���豸IP���⴦��
        If(regTest("#equipment_ip#", strLine) = 1) Then
            '��ʾ�û�����IP
            If getRealIpAddress(strEcho) = 1 Then
                strEchoFormat = devRealIp & vbCrLf
            Else
                devRealIp = 0
                checkSpecial = 0
                Exit Function 
            End If
        End If
    End Function
    
    
    'ȡ��ʵIP��ַ
    Public Function getRealIpAddress(strEcho)
        Dim firstInput	'��һ������IP��ʶ
        Dim tempInputIp	'�������ʱIP ��Ϊ�ϴ��������ʾ
        Dim autoSearchIp	'�Զ���⵽��IP
        Const IPREGEX = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])"
        firstInput = 0
        getRealIpAddress = 1
        If Not devRealIp = 0 Then
            Exit Function
        End If
        If Len(strEcho) = 0 Then 
            Dim configPrompt
            configPrompt = "��ȡIP����,����SecureCRT����:" & Chr(13) & "(1)�Ựѡ��->����->�ն�->Linux;" & Chr(13) & "(2)�Ựѡ��->���->�ַ�����->UTF-8;" & Chr(13) & "(3)�ļ�->�رջỰ��־���Ựԭʼ��־."
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
                    promptContext = "�Զ���⵽��IPΪ:" & autoSearchIp & ",��׼ȷ,������-p," & Chr(13) & Chr(10) & "����������׼ȷ��IP:"
                Else
                    promptContext = "����������豸׼ȷ��IP:"
                End If
                devRealIp = crt.Dialog.Prompt(promptContext, "������...", "", False)
                tempInputIp = devRealIp
            Else
                If Len(autoSearchIp) > 0 Then
                    promptContext = "������ȷ��IP,�Զ���⵽��IPΪ:" & autoSearchIp & ",��׼ȷ,������-p," & Chr(13) & Chr(10) & "����������׼ȷ��IP,�ϴ�����IPΪ:" & tempInputIp & ""
                Else
                    promptContext = "��������ȷ��IP,�ϴ�����IPΪ:" & tempInputIp & ""
                End If
                devRealIp = crt.Dialog.Prompt(promptContext, "������...", "", False)
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
            '				msgbox "�޷��ڻ��Խ�����ҵ���IP��ַ��'" & devRealIp & "',���������룡"
            '				devRealIp = 0
            '			End If
        Loop
    End Function
    
    '�޸Ľ���ļ�����ʽΪ IP_ʱ��.result
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

'������
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
    MsgBox "ִ�н�����"
End Sub
