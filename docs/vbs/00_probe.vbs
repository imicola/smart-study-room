' Probe script: inventory of the report document (read-only, ASCII only)
' Logs are written as UTF-8. Never quits an attached Word instance.
Option Explicit

Dim fso, workDir, logPath
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)
logPath = workDir & "\probe_log.txt"

Dim logStream
Set logStream = CreateObject("ADODB.Stream")
logStream.Type = 2
logStream.Charset = "utf-8"
logStream.Open

Sub W(s)
    logStream.WriteText s & vbCrLf
End Sub

' ---- 1. attach to running Word instance (if any) and list open docs ----
On Error Resume Next
Dim wordAtt
Set wordAtt = GetObject(, "Word.Application")
If Err.Number <> 0 Then
    W "[attach] no running Word instance"
    Err.Clear
Else
    W "[attach] running Word found, version=" & wordAtt.Version & ", docs=" & wordAtt.Documents.Count
    Dim d
    For Each d In wordAtt.Documents
        W "[open-doc] name=" & d.Name & " | saved=" & d.Saved & " | path=" & d.FullName
    Next
End If
On Error Goto 0

' ---- 2. open work copy read-only in our own hidden instance ----
Dim word
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0

Dim doc
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, True)

W "[doc] paragraphs=" & doc.Paragraphs.Count & " tables=" & doc.Tables.Count & _
  " inlineshapes=" & doc.InlineShapes.Count & " sections=" & doc.Sections.Count & _
  " toc=" & doc.TablesOfContents.Count

Dim ps
Set ps = doc.Sections(1).PageSetup
W "[page-sec1] pageW=" & ps.PageWidth & " pageH=" & ps.PageHeight & _
  " mL=" & ps.LeftMargin & " mR=" & ps.RightMargin & " mT=" & ps.TopMargin & " mB=" & ps.BottomMargin

' ---- 3. paragraph inventory ----
Dim i, p, sName, oLvl, txt
i = 0
For Each p In doc.Paragraphs
    i = i + 1
    sName = p.Style.NameLocal
    oLvl = p.Format.OutlineLevel
    txt = p.Range.Text
    If Len(txt) > 60 Then txt = Left(txt, 60)
    txt = Replace(txt, vbCrLf, "\n")
    txt = Replace(txt, vbCr, "\r")
    W "P" & i & vbTab & "style=[" & sName & "]" & vbTab & "ol=" & oLvl & vbTab & Left(txt, 70)
Next

' ---- 4. table inventory ----
Dim t, r1c1, r1c2
i = 0
For Each t In doc.Tables
    i = i + 1
    r1c1 = "" : r1c2 = ""
    On Error Resume Next
    r1c1 = t.Cell(1,1).Range.Text
    r1c2 = t.Cell(1,2).Range.Text
    Err.Clear
    On Error Goto 0
    r1c1 = Replace(r1c1, vbCr, "")
    r1c2 = Replace(r1c2, vbCr, "")
    W "T" & i & vbTab & "rows=" & t.Rows.Count & " cols=" & t.Columns.Count & _
      vbTab & "c11=[" & Left(r1c1, 20) & "] c12=[" & Left(r1c2, 20) & "]"
Next

' ---- 5. inline shapes inventory ----
i = 0
Dim sh
For Each sh In doc.InlineShapes
    i = i + 1
    W "IS" & i & vbTab & "type=" & sh.Type & " W=" & CLng(sh.Width) & " H=" & CLng(sh.Height)
Next

doc.Close False
word.Quit

logStream.SaveToFile logPath, 2
logStream.Close
WScript.Echo "probe done -> " & logPath
