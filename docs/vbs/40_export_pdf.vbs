' 40_export_pdf.vbs - export work docx to PDF
Option Explicit
Dim fso, workDir
Set fso = CreateObject("Scripting.FileSystemObject")
workDir = fso.GetParentFolderName(WScript.ScriptFullName)

Dim word, doc
Set word = CreateObject("Word.Application")
word.Visible = False
word.DisplayAlerts = 0
Set doc = word.Documents.Open(workDir & "\ssr_report.docx", False, True)
doc.ExportAsFixedFormat workDir & "\ssr_report.pdf", 17, False, 0, 0, 0, 0, 7, True, True, 0, True, True, False
doc.Close False
word.Quit
WScript.Echo "pdf exported"
