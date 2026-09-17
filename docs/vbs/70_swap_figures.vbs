' 70_swap_figures.vbs - replace embedded figures with user-provided PNGs
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

Dim A, lines, i, ln, eq
Set A = CreateObject("Scripting.Dictionary")
lines = Split(Replace(Replace(ReadUtf8(workDir & "\payload\swapfigs.txt"), vbCrLf, vbLf), vbCr, vbLf), vbLf)
For i = 0 To UBound(lines)
    ln = lines(i)
    If InStr(ln, "=") > 0 Then
        eq = InStr(ln, "=")
        A.Add Trim(Left(ln, eq - 1)), Mid(ln, eq + 1)
    End If
Next

Dim anchors
Set anchors = CreateObject("Scripting.Dictionary")
lines = Split(Replace(Replace(ReadUtf8(workDir & "\payload\anchors.txt"), vbCrLf, vbLf), vbCr, vbLf), vbLf)
For i = 0 To UBound(lines)
    ln = lines(i)
    If InStr(ln, "=") > 0 Then
        eq = InStr(ln, "=")
        anchors.Add Trim(Left(ln, eq - 1)), Mid(ln, eq + 1)
    End If
Next
Dim figPrefix
figPrefix = anchors("FIG_PREFIX")

' extract "图 N-N" key from text, empty if none
Function ExtractKey(t)
    Dim pos, rest, sp
    ExtractKey = ""
    pos = InStr(t, figPrefix)
    If pos > 0 Then
        rest = Mid(t, pos + Len(figPrefix))
        sp = InStr(rest, " ")
        If sp > 0 Then
            ExtractKey = figPrefix & Left(rest, sp - 1)
        End If
    End If
End Function

Dim word, doc
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, False)

Function KeyOfShape(sh)
    Dim p, t, k
    KeyOfShape = ""
    Set p = sh.Range.Paragraphs(1)
    t = p.Range.Text
    k = ExtractKey(t)
    If k = "" Then
        ' caption may be in the next paragraph (old-style layout)
        On Error Resume Next
        Dim np
        Set np = doc.Range(p.Range.End, p.Range.End).Paragraphs(1)
        If Err.Number = 0 Then
            k = ExtractKey(np.Range.Text)
        End If
        Err.Clear
        On Error Goto 0
    End If
    KeyOfShape = k
End Function

Dim total, swapped, skipped
total = doc.InlineShapes.Count
swapped = 0 : skipped = 0
Dim j, sh, key, pos
For j = total To 1 Step -1
    Set sh = doc.InlineShapes(j)
    key = KeyOfShape(sh)
    If key <> "" And A.Exists(key) Then
        pos = sh.Range.Start
        sh.Range.Delete
        doc.InlineShapes.AddPicture A(key), False, True, doc.Range(pos, pos)
        W "swapped " & key
        swapped = swapped + 1
    Else
        skipped = skipped + 1
    End If
Next
W "total=" & total & " swapped=" & swapped & " skipped=" & skipped

doc.Save
doc.Close False
word.Quit

logS.SaveToFile workDir & "\swap_log.txt", 2
logS.Close
WScript.Echo "swap done: " & swapped
