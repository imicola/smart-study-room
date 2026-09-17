' 55_fix2.vbs - final shading removal (cell-level) + FR column width tweak
Option Explicit

Const wdColorNone = -16777216
Const wdTextureNone = 0
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

Dim A, lines, i, ln, eq
Set A = CreateObject("Scripting.Dictionary")
lines = Split(Replace(Replace(ReadUtf8(workDir & "\payload\anchors.txt"), vbCrLf, vbLf), vbCr, vbLf), vbLf)
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

' ---- clear shading at table, row, cell level on all non-cover tables ----
Dim t, r, c, cntTables
cntTables = 0
For Each t In doc.Tables
    If Not (t.Rows.Count = 1 And t.Columns.Count = 1) Then
        cntTables = cntTables + 1
        On Error Resume Next
        t.Shading.Texture = wdTextureNone
        t.Shading.BackgroundPatternColor = wdColorNone
        t.Shading.ForegroundPatternColor = wdColorNone
        Dim rr
        For Each rr In t.Rows
            rr.Shading.Texture = wdTextureNone
            rr.Shading.BackgroundPatternColor = wdColorNone
            rr.Shading.ForegroundPatternColor = wdColorNone
        Next
        Dim cc
        For Each cc In t.Columns
            cc.Shading.Texture = wdTextureNone
            cc.Shading.BackgroundPatternColor = wdColorNone
            cc.Shading.ForegroundPatternColor = wdColorNone
        Next
        Dim cellObj
        For Each cellObj In t.Range.Cells
            cellObj.Shading.Texture = wdTextureNone
            cellObj.Shading.BackgroundPatternColor = wdColorNone
            cellObj.Shading.ForegroundPatternColor = wdColorNone
        Next
        Err.Clear
        On Error Goto 0
    End If
Next
W "shading cleared on " & cntTables & " tables (cell level)"

' ---- FR table column widths ----
Dim frTbl, cIdx
Set frTbl = FindTableByMarker(A("FIXM_FR"))
If Not frTbl Is Nothing Then
    Dim widths
    widths = Array(1.4, 2.3, 2.5, 1.4, 1.3, 6.0)
    On Error Resume Next
    frTbl.AutoFitBehavior wdAutoFitFixed
    For cIdx = 1 To frTbl.Columns.Count
        frTbl.Columns(cIdx).Width = widths(cIdx - 1) * 28.3465
    Next
    W "fr widths set"
    Err.Clear
    On Error Goto 0
Else
    W "WARN fr table not found"
End If

doc.Save
doc.Close False
word.Quit

logS.SaveToFile workDir & "\fix2_log.txt", 2
logS.Close
WScript.Echo "fix2 done"
