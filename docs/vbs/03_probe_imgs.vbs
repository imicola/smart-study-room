Option Explicit
Dim fso, workDir
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)
Dim logS
Set logS = CreateObject("ADODB.Stream")
logS.Type = 2
logS.Charset = "utf-8"
logS.Open
Dim word, doc, p, cnt
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, True)
logS.WriteText "InlineShapes total=" & doc.InlineShapes.Count & " shapes=" & doc.Shapes.Count & vbCrLf
cnt = 0
For Each p In doc.Paragraphs
    If p.Range.InlineShapes.Count > 0 Then
        cnt = cnt + 1
        Dim t
        t = Replace(p.Range.Text, vbCr, "")
        logS.WriteText "IMG" & cnt & " style=[" & p.Style.NameLocal & "] txt=[" & Left(t, 40) & "] n=" & p.Range.InlineShapes.Count & vbCrLf
    End If
Next
logS.WriteText "paras with images=" & cnt & vbCrLf
doc.Close False
word.Quit
logS.SaveToFile workDir & "\imgprobe.txt", 2
logS.Close
WScript.Echo "ok"
