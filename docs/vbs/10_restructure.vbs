' 10_restructure.vbs - content restructuring of the report via Word COM
' All Chinese strings are loaded from UTF-8 payload files (script source is ASCII).
Option Explicit

Const wdStyleNormal = -1
Const wdStyleHeading2 = -3
Const wdStyleHeading3 = -4

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
    txt = Replace(txt, vbCrLf, vbLf)
    txt = Replace(txt, vbCr, vbLf)
    SplitLines = Split(txt, vbLf)
End Function

Function ParseKV(txt)
    Dim d, lines, i, ln, eq
    Set d = CreateObject("Scripting.Dictionary")
    lines = SplitLines(txt)
    For i = 0 To UBound(lines)
        ln = Trim(lines(i))
        If Len(ln) > 0 And Left(ln, 1) <> "#" Then
            eq = InStr(ln, "=")
            If eq > 0 Then
                d.Add Trim(Left(ln, eq - 1)), Trim(Mid(ln, eq + 1))
            End If
        End If
    Next
    Set ParseKV = d
End Function

' ---- table specs storage ----
' tableSpecs(id) = Array(rowsArr, mode) where rowsArr is a 2D array of strings
' for TABLE mode rowsArr(i)(0)="H"/"R", rowsArr(i)(1)=array of cells
' for CELLS mode rowsArr(i)=array(key, col, text)
Dim tableSpecs, tableMarkers
Set tableSpecs = CreateObject("Scripting.Dictionary")
Set tableMarkers = CreateObject("Scripting.Dictionary")

Sub ParseTableSpecs(txt)
    Dim lines, i, ln, curId, parts, j
    Dim curRows(), n
    Dim curMode
    Dim cells()
    curId = ""
    lines = SplitLines(txt)
    For i = 0 To UBound(lines)
        ln = lines(i)
        If Left(ln, 7) = "[TABLE:" And Right(ln, 1) = "]" Then
            If curId <> "" Then CommitSpec curId, curRows, n, curMode
            curId = Mid(ln, 8, Len(ln) - 8)
            n = 0
            ReDim curRows(9)
            curMode = "TABLE"
        ElseIf curId <> "" And Left(ln, 7) = "MARKER=" Then
            tableMarkers.Add curId, Mid(ln, 8)
        ElseIf curId <> "" And Len(Trim(ln)) > 0 Then
            If Trim(ln) = "CELLS" Then
                curMode = "CELLS"
            ElseIf InStr(ln, "|") > 0 Then
                parts = Split(ln, "|")
                If curMode = "CELLS" Then
                    If n > UBound(curRows) Then ReDim Preserve curRows(n * 2 + 9)
                    curRows(n) = parts
                    n = n + 1
                Else
                    ReDim cells(UBound(parts) - 1)
                    For j = 1 To UBound(parts)
                        cells(j - 1) = parts(j)
                    Next
                    If n > UBound(curRows) Then ReDim Preserve curRows(n * 2 + 9)
                    curRows(n) = Array(parts(0), cells)
                    n = n + 1
                End If
            ElseIf Left(Trim(ln), 1) = "[" And Right(Trim(ln), 1) = "]" Then
                ' unused close branch
            End If
        End If
    Next
    If curId <> "" Then CommitSpec curId, curRows, n, curMode
End Sub

Sub CommitSpec(curId, curRows, n, curMode)
    Dim out(), i
    If n = 0 Then
        tableSpecs.Add curId, Array(Array(), curMode)
    Else
        ReDim out(n - 1)
        For i = 0 To n - 1
            out(i) = curRows(i)
        Next
        tableSpecs.Add curId, Array(out, curMode)
    End If
End Sub

' ---- Word globals ----
Dim word, doc
Dim capStyleName, capStyle
Dim phPrefix
Dim emissionPos

Function FindParaByPrefix(prefix)
    Dim p, t, sn
    For Each p In doc.Paragraphs
        sn = p.Style.NameLocal
        If Left(sn, 3) <> "TOC" And Left(sn, 2) <> "目录" And Left(sn, 2) <> "toc" Then
            t = p.Range.Text
            If Len(t) >= Len(prefix) Then
                If Left(t, Len(prefix)) = prefix Then
                    Set FindParaByPrefix = p
                    Exit Function
                End If
            End If
        End If
    Next
    Set FindParaByPrefix = Nothing
End Function

Sub InsertPara(ByRef pos, text, styleId)
    Dim r
    Set r = doc.Range(pos, pos)
    r.InsertAfter text & vbCr
    r.Style = styleId
    pos = r.End
End Sub

Sub InsertFigure(ByRef pos, figFile, caption)
    Dim r, pr, ish
    Set r = doc.Range(pos, pos)
    r.InsertAfter vbCr
    r.Style = wdStyleNormal
    Set pr = doc.Range(pos, pos)
    Set ish = doc.InlineShapes.AddPicture(workDir & "\figs\" & figFile, False, True, pr)
    ' picture occupies 1 char at pos, its paragraph mark at pos+1
    pos = pos + 2
    InsertPara pos, caption, capStyle
End Sub

Sub InsertPlaceholder(ByRef pos, key, caption)
    Dim startPos, r2
    startPos = pos
    InsertPara pos, phPrefix & caption, wdStyleNormal
    Set r2 = doc.Range(startPos, pos - 1)
    r2.Font.Color = 192
    r2.Font.Bold = True
End Sub

Sub BuildTableAt(ByRef pos, specId)
    Dim spec, rows, nRows, nCols, i, j, hdr, cells, r, t
    Dim row, rowCells
    spec = tableSpecs(specId)
    If spec(1) = "CELLS" Then
        W "  BuildTableAt: spec " & specId & " is CELLS type, skipped"
        Exit Sub
    End If
    rows = spec(0)
    nRows = UBound(rows) + 1
    nCols = -1
    For i = 0 To nRows - 1
        row = rows(i)
        rowCells = row(1)
        If UBound(rowCells) + 1 > nCols Then nCols = UBound(rowCells) + 1
    Next
    Set r = doc.Range(pos, pos)
    r.InsertAfter vbCr
    Set t = doc.Tables.Add(doc.Range(pos, pos), nRows, nCols)
    t.Borders.Enable = True
    For i = 0 To nRows - 1
        row = rows(i)
        hdr = (row(0) = "H")
        rowCells = row(1)
        For j = 0 To UBound(rowCells)
            If Len(rowCells(j)) > 0 Then
                t.Cell(i + 1, j + 1).Range.Text = rowCells(j)
            End If
        Next
        If hdr Then
            t.Rows(i + 1).Range.Bold = True
        End If
    Next
    W "  built table " & specId & " rows=" & nRows & " cols=" & nCols
    pos = t.Range.End
End Sub

Sub EmitLines(txt, label)
    Dim lines, i, ln, parts, pos
    lines = SplitLines(txt)
    pos = emissionPos
    For i = 0 To UBound(lines)
        ln = lines(i)
        If Len(Trim(ln)) > 0 Then
            parts = Split(ln, "|", 2)
            Select Case parts(0)
                Case "H2"
                    InsertPara pos, parts(1), wdStyleHeading2
                Case "H3"
                    InsertPara pos, parts(1), wdStyleHeading3
                Case "P"
                    InsertPara pos, parts(1), wdStyleNormal
                Case "FIG"
                    Dim f3
                    f3 = Split(ln, "|")
                    InsertFigure pos, f3(1), f3(2)
                Case "PH"
                    Dim p3
                    p3 = Split(ln, "|")
                    InsertPlaceholder pos, p3(1), p3(2)
                Case "TABLE"
                    Dim t3
                    t3 = Split(ln, "|")
                    BuildTableAt pos, t3(1)
                Case Else
                    W "  WARN unknown line type in " & label & ": " & parts(0)
            End Select
        End If
    Next
    emissionPos = pos
End Sub

Sub DeleteZone(startPara, endPara, includeStart)
    Dim s, e
    If includeStart Then
        s = startPara.Range.Start
    Else
        s = startPara.Range.End
    End If
    e = endPara.Range.Start
    W "  delete zone [" & s & "," & e & ")"
    doc.Range(s, e).Delete
    emissionPos = s
End Sub

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

Sub RebuildTable(marker, specId)
    Dim tbl, tStart, pos, txtRng
    Set tbl = FindTableByMarker(marker)
    If tbl Is Nothing Then
        W "  ERROR table not found by marker for " & specId
        Exit Sub
    End If
    tStart = tbl.Range.Start
    Set txtRng = tbl.ConvertToText(1)
    txtRng.Delete
    pos = tStart
    BuildTableAt pos, specId
End Sub

Sub ApplyCellSpecs(marker, specId)
    Dim tbl, rows, i, key, colNum, val, r, c1
    Dim rowI
    Set tbl = FindTableByMarker(marker)
    If tbl Is Nothing Then
        W "  ERROR table not found for cells " & specId
        Exit Sub
    End If
    Dim specArr
    specArr = tableSpecs(specId)
    rows = specArr(0)
    For i = 0 To UBound(rows)
        rowI = rows(i)
        key = rowI(0)
        colNum = CLng(rowI(1))
        val = rowI(2)
        For r = 2 To tbl.Rows.Count
            c1 = tbl.Cell(r, 1).Range.Text
            c1 = Replace(Replace(c1, vbCr, ""), vbCrLf, "")
            If Left(c1, Len(key)) = key Then
                tbl.Cell(r, colNum).Range.Text = val
                W "  cell set row=" & r & " col=" & colNum & " key-ok"
                Exit For
            End If
        Next
    Next
End Sub

Function ReplaceAll(findTxt, replTxt)
    Dim rng
    Set rng = doc.Content
    rng.Find.ClearFormatting
    rng.Find.Replacement.ClearFormatting
    ReplaceAll = rng.Find.Execute(findTxt, True, False, False, False, False, True, 1, False, replTxt, 2)
End Function

Sub ApplyReplaceFile(path, label)
    Dim lines, i, parts, cnt
    lines = SplitLines(ReadUtf8(path))
    cnt = 0
    For i = 0 To UBound(lines)
        If Len(Trim(lines(i))) > 0 And Left(Trim(lines(i)), 1) <> "#" Then
            parts = Split(lines(i), vbTab)
            If UBound(parts) >= 1 Then
                If ReplaceAll(parts(0), parts(1)) Then
                    cnt = cnt + 1
                Else
                    W "  WARN replace NOT FOUND [" & label & "]: " & parts(0)
                End If
            End If
        End If
    Next
    W label & ": applied " & cnt & " replacements"
End Sub

' ================= main =================
Dim anchors
Set anchors = ParseKV(ReadUtf8(workDir & "\payload\anchors.txt"))
capStyleName = anchors("CAPTION_STYLE")
phPrefix = anchors("PH_PREFIX")
ParseTableSpecs ReadUtf8(workDir & "\payload\tables.txt")

Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, False)

On Error Resume Next
Set capStyle = doc.Styles(capStyleName)
If Err.Number <> 0 Then
    Err.Clear
    Set capStyle = doc.Styles.Add(capStyleName, 1)
    W "created caption style"
End If
On Error Goto 0

W "step1: zone 3.1"
Dim pGiant, pEnd31
Set pGiant = FindParaByPrefix(anchors("H3_GIANT"))
Set pEnd31 = FindParaByPrefix(anchors("P_31END"))
If pGiant Is Nothing Or pEnd31 Is Nothing Then
    W "  ERROR anchors for zone 3.1 not found"
Else
    DeleteZone pGiant, pEnd31, True
    EmitLines ReadUtf8(workDir & "\payload\sec31.txt"), "sec31"
End If

W "step2: zone 1.5"
Dim p15, p2
Set p15 = FindParaByPrefix(anchors("H2_15"))
Set p2 = FindParaByPrefix(anchors("H1_2"))
If p15 Is Nothing Or p2 Is Nothing Then
    W "  ERROR anchors for zone 1.5 not found"
Else
    DeleteZone p15, p2, False
    EmitLines ReadUtf8(workDir & "\payload\sec15.txt"), "sec15"
End If

W "step3: zone 3.4"
Dim p34, p35
Set p34 = FindParaByPrefix(anchors("H2_34OLD"))
Set p35 = FindParaByPrefix(anchors("H2_35OLD"))
If p34 Is Nothing Or p35 Is Nothing Then
    W "  ERROR anchors for zone 3.4 not found"
Else
    DeleteZone p34, p35, True
    EmitLines ReadUtf8(workDir & "\payload\sec34.txt"), "sec34"
End If

W "step4: table rebuilds"
Dim specIds, si
specIds = Array("T_PREFACE", "T_FR", "T_USECASE", "T_DFD", "T_DD", "T_TESTPLAN", "T_TECH", "T_WORKLOAD")
For Each si In specIds
    RebuildTable tableMarkers(si), si
Next

W "step5: plan table cells"
ApplyCellSpecs tableMarkers("T_PLAN"), "T_PLAN"

W "step6: renumber"
ApplyReplaceFile workDir & "\payload\renumber.txt", "renumber"

W "step7: replaces"
ApplyReplaceFile workDir & "\payload\replaces.txt", "replaces"

W "saving"
doc.Save
Dim finalCount
finalCount = doc.Paragraphs.Count
doc.Close False
word.Quit

W "DONE paragraphs=" & finalCount & " tables=" & 0
logS.SaveToFile workDir & "\restructure_log.txt", 2
logS.Close
WScript.Echo "restructure done"
