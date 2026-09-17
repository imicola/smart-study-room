' 30_insert_figures.vbs - replace placeholder paragraphs with rendered PNG figures
' Run AFTER the user renders the mermaid sources into PNGs under docs/diagrams.
Option Explicit

Dim fso, workDir
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)

Dim logS
Set logS = CreateObject("ADODB.Stream")
logS.Type = 2
logS.Charset = "utf-8"
logS.Open

Sub W(s)
    logS.WriteText s & vbCrLf
End Sub

Function ReadUtf8(path)
    Dim st
    Set st = CreateObject("ADODB.Stream")
    st.Type = 2
    st.Charset = "utf-8"
    st.Open
    st.LoadFromFile path
    ReadUtf8 = st.ReadText(-1)
    st.Close
End Function

Dim A
Set A = CreateObject("Scripting.Dictionary")
Dim lines, i, eq, ln
lines = Split(Replace(Replace(ReadUtf8(workDir & "\payload\figs.txt"), vbCrLf, vbLf), vbCr, vbLf), vbLf)
For i = 0 To UBound(lines)
    ln = lines(i)
    If InStr(ln, "=") > 0 Then
        eq = InStr(ln, "=")
        A.Add Trim(Left(ln, eq - 1)), Mid(ln, eq + 1)
    End If
Next

Dim baseDir
baseDir = A("BASE")
If Right(baseDir, 1) <> "\" Then baseDir = baseDir & "\"

Dim phPrefix, capStyleName
phPrefix = "PLACEHOLDER_NOT_SET"
capStyleName = "CAPTION_NOT_SET"
' read these two from anchors.txt
Dim al
Set al = CreateObject("Scripting.Dictionary")
lines = Split(Replace(Replace(ReadUtf8(workDir & "\payload\anchors.txt"), vbCrLf, vbLf), vbCr, vbLf), vbLf)
For i = 0 To UBound(lines)
    ln = lines(i)
    If InStr(ln, "=") > 0 Then
        eq = InStr(ln, "=")
        al.Add Trim(Left(ln, eq - 1)), Mid(ln, eq + 1)
    End If
Next
phPrefix = al("PH_PREFIX")
capStyleName = al("CAPTION_STYLE")

Dim word, doc
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, False)

Dim capStyle
On Error Resume Next
Set capStyle = doc.Styles(capStyleName)
If Err.Number <> 0 Then
    Err.Clear
    Set capStyle = doc.Styles.Add(capStyleName, 1)
End If
On Error Goto 0

Dim doneCnt, missFile, missMap
doneCnt = 0 : missFile = 0 : missMap = 0

Dim guard
guard = 0
Do
    guard = guard + 1
    If guard > 60 Then Exit Do
    Dim p, found
    found = False
    For Each p In doc.Paragraphs
        If p.Range.Information(12) = False Then
            If Left(p.Range.Text, Len(phPrefix)) = phPrefix Then
                found = True
                Exit For
            End If
        End If
    Next
    If Not found Then Exit Do

    Dim fullTxt, capTxt, sp, key, png, pngPath
    fullTxt = Replace(p.Range.Text, vbCr, "")
    capTxt = Mid(fullTxt, Len(phPrefix) + 1)
    sp = InStr(capTxt, " ")
    If sp > 0 Then
        key = Left(capTxt, sp - 1)
    Else
        key = capTxt
    End If
    If Not A.Exists(key) Then
        W "NO MAP for key: " & key & " caption: " & capTxt
        missMap = missMap + 1
        ' mark paragraph as unresolved and continue (skip it next loop by removing prefix)
        p.Range.Text = "[UNRESOLVED " & key & "] " & capTxt & vbCr
    Else
        png = A(key)
        pngPath = baseDir & png
        If fso.FileExists(pngPath) Then
            Dim pos, r, ish
            pos = p.Range.Start
            p.Range.Text = vbCr
            Set r = doc.Range(pos, pos)
            Set ish = doc.InlineShapes.AddPicture(pngPath, False, True, r)
            doc.Range(pos, pos + 1).Paragraphs(1).Format.Alignment = 1
            ' caption paragraph after picture
            Dim cr
            Set cr = doc.Range(pos + 1, pos + 1)
            cr.InsertAfter capTxt & vbCr
            cr.Style = capStyle
            W "inserted " & key & " <- " & png
            doneCnt = doneCnt + 1
        Else
            W "FILE MISSING " & pngPath
            missFile = missFile + 1
            p.Range.Text = "[WAITING " & key & "] " & capTxt & vbCr
        End If
    End If
Loop

W "inserted=" & doneCnt & " missingFile=" & missFile & " noMap=" & missMap

If doneCnt > 0 Then
    doc.Save
End If
doc.Close False
word.Quit

logS.SaveToFile workDir & "\insert_figures_log.txt", 2
logS.Close
WScript.Echo "insert figures done: " & doneCnt & " inserted, " & missFile & " missing"
