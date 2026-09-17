' 20_format.vbs - typography pass via Word COM (ASCII source, Chinese from payload)
Option Explicit

Const wdAlignLeft = 0
Const wdAlignCenter = 1
Const wdAlignJustify = 3
Const wdLineSingle = 0
Const wdWithInTable = 12

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

' KV parser: value keeps original text (no trim on value)
Function ParseKVKeep(txt)
    Dim d, lines, i, ln, eq
    Set d = CreateObject("Scripting.Dictionary")
    lines = Split(Replace(Replace(txt, vbCrLf, vbLf), vbCr, vbLf), vbLf)
    For i = 0 To UBound(lines)
        ln = lines(i)
        If Len(Trim(ln)) > 0 And Left(Trim(ln), 1) <> "#" Then
            eq = InStr(ln, "=")
            If eq > 0 Then
                d.Add Trim(Left(ln, eq - 1)), Mid(ln, eq + 1)
            End If
        End If
    Next
    Set ParseKVKeep = d
End Function

Dim A
Set A = ParseKVKeep(ReadUtf8(workDir & "\payload\anchors.txt"))

Dim cnFont, enFont, capStyleName
cnFont = A("FONT_CN")
enFont = A("FONT_EN")
capStyleName = A("CAPTION_STYLE")

Dim word, doc
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, False)

Dim statH1, statH2, statH3, statBody, statList, statCaption, statImage, statTocTitle
statH1 = 0 : statH2 = 0 : statH3 = 0 : statBody = 0 : statList = 0 : statCaption = 0 : statImage = 0 : statTocTitle = 0

' ---- 1. style-level setup ----
Sub SetupStyles
    Dim st, pf, ft
    ' Normal
    Set st = doc.Styles(-1)
    Set ft = st.Font
    ft.NameFarEast = cnFont
    ft.Name = enFont
    ft.Size = 12
    Set pf = st.ParagraphFormat
    pf.LineSpacingRule = wdLineSingle
    pf.SpaceBefore = 0
    pf.SpaceAfter = 0
    ' Heading 1
    Set st = doc.Styles(-2)
    Set ft = st.Font
    ft.NameFarEast = cnFont
    ft.Name = enFont
    ft.Size = 16
    ft.Bold = True
    ft.Color = 0
    Set pf = st.ParagraphFormat
    pf.Alignment = wdAlignLeft
    pf.LineSpacingRule = wdLineSingle
    pf.SpaceBefore = 13
    pf.SpaceAfter = 6
    pf.KeepWithNext = True
    ' Heading 2 (not bold per requirement)
    Set st = doc.Styles(-3)
    Set ft = st.Font
    ft.NameFarEast = cnFont
    ft.Name = enFont
    ft.Size = 14
    ft.Bold = False
    ft.Color = 0
    Set pf = st.ParagraphFormat
    pf.Alignment = wdAlignLeft
    pf.LineSpacingRule = wdLineSingle
    pf.SpaceBefore = 10
    pf.SpaceAfter = 5
    pf.KeepWithNext = True
    ' Heading 3
    Set st = doc.Styles(-4)
    Set ft = st.Font
    ft.NameFarEast = cnFont
    ft.Name = enFont
    ft.Size = 12
    ft.Bold = True
    ft.Color = 0
    Set pf = st.ParagraphFormat
    pf.Alignment = wdAlignLeft
    pf.LineSpacingRule = wdLineSingle
    pf.SpaceBefore = 8
    pf.SpaceAfter = 4
    pf.KeepWithNext = True
    ' caption style
    On Error Resume Next
    Set st = doc.Styles(capStyleName)
    If Err.Number = 0 Then
        Set ft = st.Font
        ft.NameFarEast = cnFont
        ft.Name = enFont
        ft.Size = 10.5
        ft.Bold = False
        Set pf = st.ParagraphFormat
        pf.Alignment = wdAlignCenter
        pf.LineSpacingRule = wdLineSingle
        pf.SpaceBefore = 3
        pf.SpaceAfter = 6
    End If
    Err.Clear
    On Error Goto 0
End Sub

SetupStyles
W "styles configured"

' ---- helpers ----
Function IsCaptionText(t)
    Dim pfx
    pfx = A("FIG_PREFIX")
    If Left(t, Len(pfx)) = pfx And Len(t) > Len(pfx) + 1 Then
        IsCaptionText = True
    Else
        IsCaptionText = False
    End If
End Function

Sub SetFont(r, sz, bold, doBold)
    r.Font.NameFarEast = cnFont
    r.Font.Name = enFont
    r.Font.Size = sz
    If doBold Then r.Font.Bold = bold
End Sub

Sub FormatHeading(p, lvl)
    Dim r, sz, isBold
    Set r = p.Range
    If lvl = 1 Then sz = 16 : isBold = True
    If lvl = 2 Then sz = 14 : isBold = False
    If lvl = 3 Then sz = 12 : isBold = True
    SetFont r, sz, isBold, True
    r.Font.Color = 0
    With p.Format
        .Alignment = wdAlignLeft
        .LineSpacingRule = wdLineSingle
        .CharacterUnitFirstLineIndent = 0
        .FirstLineIndent = 0
        .CharacterUnitLeftIndent = 0
        .LeftIndent = 0
        If lvl = 1 Then .SpaceBefore = 13 : .SpaceAfter = 6
        If lvl = 2 Then .SpaceBefore = 10 : .SpaceAfter = 5
        If lvl = 3 Then .SpaceBefore = 8 : .SpaceAfter = 4
        .KeepWithNext = True
    End With
End Sub

Sub FormatBodyPara(p, isList)
    Dim r
    Set r = p.Range
    SetFont r, 12, False, False
    With p.Format
        .Alignment = wdAlignJustify
        .LineSpacingRule = wdLineSingle
        .SpaceBefore = 0
        .SpaceAfter = 0
        If isList Or Len(Replace(Replace(p.Range.Text, vbCr, ""), " ", "")) = 0 Then
            .CharacterUnitFirstLineIndent = 0
            .FirstLineIndent = 0
        Else
            .CharacterUnitFirstLineIndent = 2
            .FirstLineIndent = 0
        End If
    End With
End Sub

Sub FormatCaptionPara(p)
    Dim r
    Set r = p.Range
    SetFont r, 10.5, False, False
    With p.Format
        .Alignment = wdAlignCenter
        .LineSpacingRule = wdLineSingle
        .SpaceBefore = 3
        .SpaceAfter = 6
        .CharacterUnitFirstLineIndent = 0
        .FirstLineIndent = 0
    End With
End Sub

Sub FormatImagePara(p)
    With p.Format
        .Alignment = wdAlignCenter
        .LineSpacingRule = wdLineSingle
        .SpaceBefore = 3
        .SpaceAfter = 0
        .CharacterUnitFirstLineIndent = 0
        .FirstLineIndent = 0
    End With
End Sub

' ---- 2. paragraph sweep ----
Dim p, sn, t
For Each p In doc.Paragraphs
    If p.Range.Information(wdWithInTable) Then
        ' handled in table pass
    Else
        sn = p.Style.NameLocal
        t = p.Range.Text
        If Left(sn, 3) = "TOC" Or Left(sn, 2) = A("TOC_PREFIX_CN") Then
            ' skip TOC entries
        ElseIf sn = A("STYLE_H1") Then
            FormatHeading p, 1
            statH1 = statH1 + 1
        ElseIf sn = A("STYLE_H2") Then
            FormatHeading p, 2
            statH2 = statH2 + 1
        ElseIf sn = A("STYLE_H3") Then
            FormatHeading p, 3
            statH3 = statH3 + 1
        ElseIf sn = capStyleName Or IsCaptionText(t) Then
            FormatCaptionPara p
            statCaption = statCaption + 1
        ElseIf Trim(Replace(t, vbCr, "")) = A("TOC_TITLE") Then
            SetFont p.Range, 16, True, True
            p.Format.Alignment = wdAlignCenter
            p.Format.CharacterUnitFirstLineIndent = 0
            p.Format.FirstLineIndent = 0
            statTocTitle = statTocTitle + 1
        ElseIf p.Range.InlineShapes.Count > 0 Then
            FormatImagePara p
            statImage = statImage + 1
        ElseIf sn = A("STYLE_LIST") Then
            FormatBodyPara p, True
            statList = statList + 1
        Else
            FormatBodyPara p, False
            statBody = statBody + 1
        End If
    End If
Next
W "paragraphs: H1=" & statH1 & " H2=" & statH2 & " H3=" & statH3 & _
  " body=" & statBody & " list=" & statList & " caption=" & statCaption & _
  " image=" & statImage & " toctitle=" & statTocTitle

' ---- 3. table pass ----
Dim tbl, r, c, cr, cellText
Dim statTables
statTables = 0
For Each tbl In doc.Tables
    If tbl.Rows.Count = 1 And tbl.Columns.Count = 1 Then
        ' cover table, skip
    Else
        statTables = statTables + 1
        For r = 1 To tbl.Rows.Count
            For c = 1 To tbl.Columns.Count
                On Error Resume Next
                Set cr = tbl.Cell(r, c).Range
                If Err.Number = 0 Then
                    SetFont cr, 10.5, True, (r = 1)
                    cellText = Replace(cr.Text, vbCr, "")
                    If r = 1 Then
                        cr.ParagraphFormat.Alignment = wdAlignCenter
                    Else
                        If Len(cellText) <= 8 Then
                            cr.ParagraphFormat.Alignment = wdAlignCenter
                        Else
                            cr.ParagraphFormat.Alignment = wdAlignLeft
                        End If
                    End If
                    cr.ParagraphFormat.LineSpacingRule = wdLineSingle
                    cr.ParagraphFormat.SpaceBefore = 0
                    cr.ParagraphFormat.SpaceAfter = 0
                    cr.ParagraphFormat.CharacterUnitFirstLineIndent = 0
                    cr.ParagraphFormat.FirstLineIndent = 0
                    tbl.Cell(r, c).VerticalAlignment = 1
                End If
                Err.Clear
                On Error Goto 0
            Next
        Next
        On Error Resume Next
        tbl.Rows(1).HeadingFormat = True
        tbl.Rows.AllowBreakAcrossPages = False
        tbl.PreferredWidthType = 2
        tbl.PreferredWidth = 100
        Err.Clear
        On Error Goto 0
    End If
Next
W "tables formatted: " & statTables

' ---- 4. inline shapes sizing ----
Dim ps, usableW, usableH, sh
Set ps = doc.Sections(2).PageSetup
usableW = ps.PageWidth - ps.LeftMargin - ps.RightMargin
usableH = ps.PageHeight - ps.TopMargin - ps.BottomMargin
Dim statScaled
statScaled = 0
For Each sh In doc.InlineShapes
    On Error Resume Next
    sh.LockAspectRatio = True
    If sh.Width > usableW Then
        sh.Width = usableW
        statScaled = statScaled + 1
    End If
    If sh.Height > usableH * 0.85 Then
        Dim ratio
        ratio = (usableH * 0.85) / sh.Height
        sh.Height = usableH * 0.85
        sh.Width = sh.Width * ratio
        statScaled = statScaled + 1
    End If
    Err.Clear
    On Error Goto 0
Next
W "shapes scaled: " & statScaled & " usableW=" & CLng(usableW) & " usableH=" & CLng(usableH)

' ---- 5. TOC / fields update ----
On Error Resume Next
doc.TablesOfContents(1).Update
W "toc updated err=" & Err.Number
Err.Clear
doc.Fields.Update
W "fields updated err=" & Err.Number
Err.Clear
On Error Goto 0

doc.Save
doc.Close False
word.Quit

logS.SaveToFile workDir & "\format_log.txt", 2
logS.Close
WScript.Echo "format done"
