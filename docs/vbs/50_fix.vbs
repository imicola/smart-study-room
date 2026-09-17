' 50_fix.vbs - post-QA repair pass (renumber, borders, column widths, text color)
Option Explicit

Const wdColorAutomatic = 9999999
Const wdAutoFitFixed = 0

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

Function SplitLines(txt)
    SplitLines = Split(Replace(Replace(txt, vbCrLf, vbLf), vbCr, vbLf), vbLf)
End Function

Dim A
Set A = CreateObject("Scripting.Dictionary")
Dim lines, i, ln, eq
lines = SplitLines(ReadUtf8(workDir & "\payload\anchors.txt"))
For i = 0 To UBound(lines)
    ln = lines(i)
    If InStr(ln, "=") > 0 Then
        eq = InStr(ln, "=")
        A.Add Trim(Left(ln, eq - 1)), Mid(ln, eq + 1)
    End If
Next

Dim word, doc
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, False)

Function ReplaceAll(findTxt, replTxt)
    Dim rng
    Set rng = doc.Content
    rng.Find.ClearFormatting
    rng.Find.Replacement.ClearFormatting
    ReplaceAll = rng.Find.Execute(findTxt, True, False, False, False, False, True, 1, False, replTxt, 2)
End Function

Function FindTableByMarker(marker)
    Dim t
    For Each t In doc.Tables
        If InStr(1, t.Range.Text, marker) > 0 Then
            Set FindTableByMarker = t
            Exit Function
        End If
    Next
    Set FindTableByMarker = Nothing
End Function

' ---- 1. renumber fix ----
W "step1: renumber fix"
Dim fl, parts, cnt
fl = SplitLines(ReadUtf8(workDir & "\payload\fixrenumber.txt"))
cnt = 0
For i = 0 To UBound(fl)
    If Len(Trim(fl(i))) > 0 Then
        parts = Split(fl(i), vbTab)
        If UBound(parts) >= 1 Then
            If ReplaceAll(parts(0), parts(1)) Then
                cnt = cnt + 1
            Else
                W "  WARN not found: " & parts(0)
            End If
        End If
    End If
Next
W "  renumber applied " & cnt

' ---- 2. plan table borders + clear shading everywhere ----
W "step2: borders and shading"
Dim planTbl
Set planTbl = FindTableByMarker(A("FIXM_PLAN"))
If Not planTbl Is Nothing Then
    planTbl.Borders.Enable = True
    W "  plan table borders enabled"
Else
    W "  WARN plan table not found"
End If

Dim t
For Each t In doc.Tables
    On Error Resume Next
    If Not (t.Rows.Count = 1 And t.Columns.Count = 1) Then
        t.Shading.BackgroundPatternColor = wdColorAutomatic
        Dim rr
        For Each rr In t.Rows
            rr.Shading.BackgroundPatternColor = wdColorAutomatic
        Next
    End If
    Err.Clear
    On Error Goto 0
Next
W "  shading cleared on all tables"

' ---- 3. column widths ----
Sub SetColWidths(marker, widthsCm)
    Dim tbl, c
    Set tbl = FindTableByMarker(marker)
    If tbl Is Nothing Then
        W "  WARN table not found for widths: " & marker
        Exit Sub
    End If
    On Error Resume Next
    tbl.AutoFitBehavior wdAutoFitFixed
    For c = 1 To tbl.Columns.Count
        If c <= UBound(widthsCm) + 1 Then
            tbl.Columns(c).Width = widthsCm(c - 1) * 28.3465
        End If
    Next
    W "  widths set for table [" & marker & "]"
    Err.Clear
    On Error Goto 0
End Sub

W "step3: column widths"
SetColWidths A("FIXM_WORKLOAD"), Array(1.0, 1.5, 2.3, 3.3, 4.4, 1.2, 1.4)
SetColWidths A("FIXM_FR"), Array(1.5, 2.4, 2.6, 1.3, 1.1, 6.0)
SetColWidths A("FIXM_DD"), Array(2.2, 1.5, 4.8, 3.4, 2.2, 1.2)

' ---- 4. body text color to automatic black (skip placeholders) ----
W "step4: text color"
Dim p, phPrefix, sn, fixed
phPrefix = A("PH_PREFIX")
fixed = 0
For Each p In doc.Paragraphs
    If p.Range.Information(12) = False Then
        sn = p.Style.NameLocal
        If Left(sn, 3) <> "TOC" And Left(sn, 2) <> A("TOC_PREFIX_CN") Then
            If Left(p.Range.Text, Len(phPrefix)) <> phPrefix Then
                On Error Resume Next
                p.Range.Font.Color = wdColorAutomatic
                fixed = fixed + 1
                Err.Clear
                On Error Goto 0
            End If
        End If
    End If
Next
W "  color reset on " & fixed & " paragraphs"

' ---- 5. TOC update ----
On Error Resume Next
doc.TablesOfContents(1).Update
W "toc updated err=" & Err.Number
Err.Clear
On Error Goto 0

doc.Save
doc.Close False
word.Quit

logS.SaveToFile workDir & "\fix_log.txt", 2
logS.Close
WScript.Echo "fix done"
