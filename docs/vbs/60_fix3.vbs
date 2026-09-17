' 60_fix3.vbs - zero indents on caption paragraphs (fix right-overflow of new figures)
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

' fix caption style itself
On Error Resume Next
Dim capSt
Set capSt = doc.Styles(A("CAPTION_STYLE"))
If Err.Number = 0 Then
    capSt.ParagraphFormat.LeftIndent = 0
    capSt.ParagraphFormat.FirstLineIndent = 0
    capSt.ParagraphFormat.RightIndent = 0
    W "caption style indents zeroed"
End If
Err.Clear
On Error Goto 0

' fix every caption-styled or caption-text paragraph
Dim p, t, fixed, phPrefix
phPrefix = A("PH_PREFIX")
fixed = 0
For Each p In doc.Paragraphs
    If p.Range.Information(12) = False Then
        t = p.Range.Text
        If p.Style.NameLocal = A("CAPTION_STYLE") Or (Left(t, 2) = Left(A("FIG_PREFIX"), 2) & " ") Or Left(t, 2) = A("FIG_PREFIX") Then
            If Left(t, Len(phPrefix)) <> phPrefix Then
                p.Format.LeftIndent = 0
                p.Format.CharacterUnitLeftIndent = 0
                p.Format.FirstLineIndent = 0
                p.Format.CharacterUnitFirstLineIndent = 0
                p.Format.RightIndent = 0
                p.Format.Alignment = 1
                fixed = fixed + 1
            End If
        End If
    End If
Next
W "caption paragraphs fixed: " & fixed

On Error Resume Next
doc.TablesOfContents(1).Update
W "toc updated err=" & Err.Number
Err.Clear
On Error Goto 0

doc.Save
doc.Close False
word.Quit

logS.SaveToFile workDir & "\fix3_log.txt", 2
logS.Close
WScript.Echo "fix3 done"
