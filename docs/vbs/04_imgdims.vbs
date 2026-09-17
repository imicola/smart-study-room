Option Explicit
Dim fso, workDir
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)
Dim logS
Set logS = CreateObject("ADODB.Stream")
logS.Type = 2
logS.Charset = "utf-8"
logS.Open
Dim word, doc, sh, i
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, True)
i = 0
For Each sh In doc.InlineShapes
    i = i + 1
    Dim li, fi, al
    On Error Resume Next
    li = sh.Range.Paragraphs(1).Format.LeftIndent
    fi = sh.Range.Paragraphs(1).Format.FirstLineIndent
    al = sh.Range.Paragraphs(1).Format.Alignment
    logS.WriteText "IS" & i & " W=" & CLng(sh.Width) & " H=" & CLng(sh.Height) & " leftIndent=" & CLng(li) & " firstLine=" & CLng(fi) & " align=" & al & " style=[" & sh.Range.Paragraphs(1).Style.NameLocal & "]" & vbCrLf
    Err.Clear
    On Error Goto 0
Next
doc.Close False
word.Quit
logS.SaveToFile workDir & "\imgdims.txt", 2
logS.Close
WScript.Echo "ok"
