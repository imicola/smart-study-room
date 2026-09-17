Option Explicit
Dim fso, workDir
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)
Dim logS
Set logS = CreateObject("ADODB.Stream")
logS.Type = 2
logS.Charset = "utf-8"
logS.Open
Dim word, doc, t, i
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, True)
i = 0
For Each t In doc.Tables
    i = i + 1
    Dim r1
    r1 = t.Rows(1).Range.Text
    r1 = Replace(r1, vbCr, "/")
    r1 = Replace(r1, Chr(7), "|")
    logS.WriteText "T" & i & " nest=" & t.NestingLevel & " rows=" & t.Rows.Count & " cols=" & t.Columns.Count & " R1=[" & Left(r1, 60) & "]" & vbCrLf
Next
doc.Close False
word.Quit
logS.SaveToFile workDir & "\tables_now.txt", 2
logS.Close
WScript.Echo "ok"
