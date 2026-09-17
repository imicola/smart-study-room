' Dump full paragraph texts and full table cell texts to UTF-8 file
Option Explicit

Dim fso, workDir
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)

Dim logStream
Set logStream = CreateObject("ADODB.Stream")
logStream.Type = 2
logStream.Charset = "utf-8"
logStream.Open

Sub W(s)
    logStream.WriteText s & vbCrLf
End Sub

Dim word, doc
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, False)

' full paragraph dump from 100 on (cover = table content before)
Dim i, p, txt
i = 0
For Each p In doc.Paragraphs
    i = i + 1
    If i >= 70 Then
        txt = p.Range.Text
        txt = Replace(txt, vbCr, "")
        txt = Replace(txt, vbCrLf, "")
        If Len(txt) > 0 Then
            W "P" & i & vbTab & p.Style.NameLocal & vbTab & txt
        Else
            W "P" & i & vbTab & p.Style.NameLocal & vbTab & "[EMPTY]"
        End If
    End If
Next

' full table dump
Dim t, r, c, cellTxt
i = 0
For Each t In doc.Tables
    i = i + 1
    W "=== TABLE " & i & " rows=" & t.Rows.Count & " cols=" & t.Columns.Count & " ==="
    For r = 1 To t.Rows.Count
        Dim rowParts
        rowParts = ""
        For c = 1 To t.Columns.Count
            cellTxt = ""
            On Error Resume Next
            cellTxt = t.Cell(r, c).Range.Text
            If Err.Number <> 0 Then cellTxt = "[MERGED]"
            Err.Clear
            On Error Goto 0
            cellTxt = Replace(cellTxt, vbCr, "")
            cellTxt = Replace(cellTxt, vbCrLf, "")
            If c > 1 Then rowParts = rowParts & " ||| "
            rowParts = rowParts & cellTxt
        Next
        W "T" & i & "R" & r & vbTab & rowParts
    Next
Next

' sections page setup
Dim s
For Each s In doc.Sections
    W "SEC pageW=" & s.PageSetup.PageWidth & " mL=" & s.PageSetup.LeftMargin & _
      " mR=" & s.PageSetup.RightMargin & " mT=" & s.PageSetup.TopMargin & " mB=" & s.PageSetup.BottomMargin
Next

doc.Close False
word.Quit

logStream.SaveToFile workDir & "\dump.txt", 2
logStream.Close
WScript.Echo "dump done"
