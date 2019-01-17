VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisWorkbook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

Public MasterSheet As Worksheet
Public SpecialStatusSheet As Worksheet
Public CompletedSheet As Worksheet
Public ShippedSheet As Worksheet
Public SerialAssetSheet As Worksheet
Dim FirstSave As Boolean

Private Sub Workbook_Open()
    'Called when the file (workbook) is opened.

    Dim Sheet As Worksheet                  'This will be set to the worksheet within the loop.
    Dim CurrentUsers() As Variant           'This will be set to a list of users who have this workbook open NOT in Read-Only mode.
    
    Application.ScreenUpdating = False
    For Each Sheet In ThisWorkbook.Worksheets
        'When we activate each sheet we are triggering the sheet's activation event (if it has one).
        Call UnhideAllColumns(Sheet)
        Call UnhideAllRows(Sheet)
        Sheet.Activate
    Next
    Application.ScreenUpdating = True

    'This is required to ensure that the global worksheet variables are assigned correctly by ensuring each sheet's activation event fires.
    For Each Sheet In ThisWorkbook.Worksheets
        Sheet.Activate
        'Here we specifically set the active cell to the first empty cell in column 1 (A), for each sheet.
        Sheet.Range("A" & Sheet.UsedRange.Rows.Count).End(xlUp).Offset(1, 0).Activate
    Next

    'Then I force the Master sheet to be the active sheet as this is the most useful sheet.
    ThisWorkbook.MasterSheet.Activate
    ThisWorkbook.MasterSheet.Range("A" & ThisWorkbook.MasterSheet.UsedRange.Rows.Count).End(xlUp).Offset(1, 0).Activate
    
    
    'If the user isn't restricted to read-only then we see if we need to warn them about multiple active users modifying the file.
    If ThisWorkbook.ReadOnly = False Then
        'Here we resize the CurrentUsers array to accomodate the number of users currently working with this file.
        ReDim CurrentUsers(UBound(ThisWorkbook.UserStatus, 1))
        'If there is more than 1 person using this file we inform any additional users of this.
        If UBound(CurrentUsers, 1) > CLng(1) Then
            MsgBox "NOTICE: This file has " & (UBound(CurrentUsers) - CLng(1)) & " other user(s) working within it at this time. Be aware of the potential to modify cells someone else may be using.", vbInformation, "Multiple Users Notice"
        End If
    End If

End Sub

Private Sub Workbook_BeforeClose(Cancel As Boolean)
    'Called before the workbook closes, as stated.
    
    Call AutoFilterCheck
    If ActiveFilterCheck() Then Call ClearAllFilters

End Sub

Private Sub Workbook_BeforeSave(ByVal SaveAsUI As Boolean, Cancel As Boolean)
    'Called before saving, as stated.
    
    Call AutoFilterCheck
    If ActiveFilterCheck() Then Call ClearAllFilters
    
End Sub

Private Sub Workbook_AfterSave(ByVal Success As Boolean)
    'When called will enable workbook sharing if FirstSave is True.
    
    If FirstSave = True Then
        Application.DisplayAlerts = False
        Application.EnableEvents = False
        ThisWorkbook.SaveAs ThisWorkbook.Name, AccessMode:=xlShared, ConflictResolution:=xlUserResolution
        FirstSave = False
        Application.EnableEvents = True
        Application.DisplayAlerts = True
        MsgBox "Workbook sharing is now enabled.", vbOKOnly, "Workbook Sharing Enabled"
    End If

End Sub

Private Sub UnhideAllColumns(ByRef Sheet As Worksheet)
    'When called will un-hide every column on every sheet.
    
    Dim Col As Range        'This will be set to the column within the loop.
    Dim UsedCells As Range  'This will contain all the rows and columns that are being used only.
    
    Set UsedCells = Sheet.UsedRange
    'Here we loop through every column in this sheet and un-hide (show) the column if hidden.
    For Each Col In UsedCells.Columns
        If Col.Hidden = True Then Col.Hidden = False
    Next
    
    
End Sub

Private Sub UnhideAllRows(ByRef Sheet As Worksheet)
    'When called will un-hide every row on every sheet.
    
    Dim Ro As Range         'This will be set to the row within the loop.
    Dim UsedCells As Range  'This will contain all the rows and columns that are being used only.
    
    Set UsedCells = Sheet.UsedRange
    'Here we loop through every row in this sheet and un-hide (show) the row if hidden.
    For Each Ro In UsedCells.Rows
        If Ro.Hidden = True Then Ro.Hidden = False
    Next
    
End Sub

Private Function ActiveFilterCheck() As Boolean
    'Specifically we check every sheet for an active filter, and if found it will return true.

    Dim Sheet As Worksheet              'This will be set to the worksheet within the loop.
    
    For Each Sheet In ThisWorkbook.Worksheets
        If Sheet.AutoFilterMode And Sheet.FilterMode Then
            ActiveFilterCheck = True
            Exit Function
        ElseIf Sheet.AutoFilterMode And Sheet.FilterMode = False Then
            ActiveFilterCheck = False
        End If
    Next
    
End Function

Private Sub AutoFilterCheck()
    'When called will be sure that every sheet has AutoFilter turned on for the header.
    
    Dim Sheet As Worksheet              'This will be set to the worksheet within the loop.
    Dim FilterRange As Range            'This will be set to the AutoFilter range if AutoFilter is enabled.
    
    For Each Sheet In ThisWorkbook.Worksheets
        If Sheet.AutoFilter Is Nothing Then Sheet.Cells(1, 1).AutoFilter
    Next
    
End Sub

Public Sub CreateCellComment(ByRef TargetCell As Range, ByRef Append As Boolean)
    'When called this creates a comment on the referenced cell with the text of the referenced cell's value.
    
    'If TargetCell.Value = Empty Then Exit Sub
    If Append Then
        If TargetCell.Comment Is Nothing Then
            'If we want to append, but don't have anything to append to, we simply create a new comment.
            TargetCell.AddComment.Text (TargetCell.Text)
        Else
            'Otherwise we append.
            TargetCell.Comment.Text Chr(10) & TargetCell.Text, CInt(Len(TargetCell.Comment.Text)) + 2, False
        End If
    Else
        'First we clear any previous comments to prevent any creation conflicts.
        TargetCell.ClearComments
        TargetCell.AddComment.Text (TargetCell.Text)
    End If
    'Finally we AutoSize our new comment.
    TargetCell.Comment.Shape.TextFrame.AutoSize = True
    
End Sub

Public Function SheetColumnLookup(ByRef TargetHeader As String, ByRef Whole As Boolean, ByRef Sheet As Worksheet, ByRef SupressError As Boolean) As Integer
    'Checks for a header in row 1 with the (optionally whole) value matching the given string. If errors are supressed no error messages are shown.
    'If found it returns the column number.
    'If not found it returns 0.
    
    Dim HeaderRange As Range            'This will be set to row 1 of a sheet, as it is assumed that this is the header row.
    Dim FirstFindAddress As String             'This will be set to the value of the first cell we find for comparison.
    
    If Whole Then
        Set HeaderRange = Sheet.UsedRange.Rows(1).Find(TargetHeader, LookAt:=xlWhole)
    ElseIf Not Whole Then
        Set HeaderRange = Sheet.UsedRange.Rows(1).Find(TargetHeader, LookAt:=xlPart)
    End If
    If Not HeaderRange Is Nothing Then
        FirstFindAddress = HeaderRange.Address
        Set HeaderRange = HeaderRange.FindNext(HeaderRange)
        If HeaderRange.Address <> FirstFindAddress Then
            MsgBox "More than one column header is labeled as " & TargetHeader & ". Please correct the column headers and try again.", vbExclamation, "Multiple Results For " & TargetHeader & " Column"
            SheetColumnLookup = 0
            Exit Function
        Else
            SheetColumnLookup = HeaderRange.Column
            Exit Function
        End If
    ElseIf HeaderRange Is Nothing And SupressError = False Then
        MsgBox "Unable to find a column header in row 1 with the value of " & TargetHeader & " on the " & Sheet.Name & " sheet." & Chr(10) & "Please create a column header with " & TargetHeader & " in the name.", vbCritical, "Specific Header Not Found"
        Exit Function
    End If

End Function

Public Sub SetDate(ByRef SerialCell As Range)
    'Sets the current date for the SerialCell row.
    'NOTE: It may not work if the Date column is missing initially, but is then found on a later serial submission. Maybe. Test it.
    
    Dim Sheet As Worksheet      'This will be set to the SerialCell's worksheet.
    Dim DateColumn As Integer   'This will be set to the column index of the "Date" column.
    Dim DateDif As Long         'This will be the difference in days between the current date, if any, and today's date.
    
    Set Sheet = SerialCell.Worksheet
    DateColumn = SheetColumnLookup("Date", False, Sheet, False)
    'If we can't find the date column then we quietly give up, as this information isn't critically important.
    If DateColumn = 0 Then Exit Sub
    With Sheet.Cells(SerialCell.Row, DateColumn)
        'We have to disable events and re-enable them later on to prevent an infinite loop.
        Application.EnableEvents = False
        'If the date cell was messed with but there isn't a serial number then we simply leave it empty.
        If SerialCell.Value = Empty Then
            .Value = Empty
            Application.EnableEvents = True
            Exit Sub
        End If
        'If there was something entered into the date cell, and it is in fact a date, then we measure the difference
        'in the number of days between today and the provided date, and only accepts older dates.
        If .Value <> Empty And IsDate(.Value) Then
            DateDif = DateDiff("d", .Value, Date)
            If DateDif <= 0 Then .Value = Date
        Else
            .Value = Date
        End If
        Application.EnableEvents = True
    End With
    
End Sub

Public Function SheetSerialRowLookup(ByRef Serial As String, ByRef Sheet As Worksheet) As Integer
    'Searches the given sheet for the given serial number and if found returns the row of found serial number.

    Dim SerialColumn As Integer     'This will be set to the index of the "Unit Serial" or "Serial" column.
    Dim SerialRange As Range        'This will be set to the cells with the matching serial number.
    Dim LatestFindRow As String     'This will be set to the row number of each found instance of Serial.
    Dim Cel As Range                'This will be set to each cell within a column within a for each loop below.
    
    'Here we check for a specific type of serial column that could be found.
    SerialColumn = SheetColumnLookup("Unit Serial", False, Sheet, True)
    If SerialColumn = 0 Then
        'If we can't find our more specific variant we then broaden our search.
        SerialColumn = SheetColumnLookup("Serial", False, Sheet, False)
    End If
    'If we can't find the serial column on Sheet then we give up and let the SheetColumnLookup() function inform the user.
    If SerialColumn = 0 Then Exit Function
    'Here we create our range of serial cells to search through (SerialRange).
    Set SerialRange = Sheet.UsedRange.Columns(SerialColumn).Cells
    LatestFindRow = 0
    'If we find a match we record the row so we can later compare it against further matches and determine the latest version
    'of the serial number if we have a serial number present multiple times within SerialRange.
    For Each Cel In SerialRange
        If Cel.Value = Serial Then
            If Cel.Row > LatestFindRow Then
                LatestFindRow = Cel.Row
            End If
        End If
    Next
    'Once we've found the latest version of Serial then we return the row of that cell on Sheet.
    SheetSerialRowLookup = LatestFindRow
    Exit Function
    
End Function

Public Sub SetStatus(ByRef SerialCell As Range)
    'Sets the status cell of the given serial cell to "SCANNED" by default and then calls StatusCheck() to be sure.

    Dim SerialRow As Integer    'This will be set to the row number of the SerialCell's serial number on the MasterSheet.
    Dim StatusColumn As Integer 'This will be ser to the column index of the "Status" column of the MasterSheet.

    'If the given cell is empty (meaning the cell was cleared and the clearing called this event) we use the comment text
    'to find the serial that was there and submit the serial number to the master sheet for status update.
    If SerialCell.Value = Empty Then
        'If the SerialCell is empty then we use the comment text to search the MasterSheet.
        If Not SerialCell.Comment Is Nothing Then
            SerialRow = SheetSerialRowLookup(SerialCell.Comment.Text, ThisWorkbook.MasterSheet)
        Else
            'If SerialCell's value is Empty and there isn't a comment to reference we give up.
            Exit Sub
        End If
    ElseIf SerialCell.Value <> Empty Then
        'If the SerialCell isn't empty then we use the SerialCell's value to search the MasterSheet.
        SerialRow = SheetSerialRowLookup(SerialCell.Value, ThisWorkbook.MasterSheet)
    End If
    StatusColumn = ThisWorkbook.SheetColumnLookup("Status", False, ThisWorkbook.MasterSheet, False)
    'If 0 we exit and wait for the Master to update this entry remotely, as it is currently not on the Master.
    If SerialRow = 0 Then Exit Sub
    'If 0 we exit. The SheetColumnLookup() function will display an error message to the user.
    If StatusColumn = 0 Then Exit Sub
    'Here we assume the default status of "SCANNED", and then call StatusCheck() to update the status if not so.
    'We temporarily disable events to prevent the chance of causing an infinite loop or needlessly recurring code when cahnging cell values.
    Application.EnableEvents = False
    ThisWorkbook.MasterSheet.Cells(SerialRow, StatusColumn).Value = "SCANNED"
    Application.EnableEvents = True
    Call StatusCheck(SerialCell)

End Sub

Sub StatusCheck(ByRef SerialCell As Range)
    'Updates the status cell of SerialCell on the Master by searching through the other sheets.
    'The search starts at the final possible status and works its way back.

    Dim ShippedStatus As String     'This will be set to the status of the serial on the ShippedSheet, if found.
    Dim CompletedStatus As String   'This will be set to the status of the serial on the CompletedSheet, if found.
    Dim SpecialStatus As String     'This will be set to the status of the serial on the SpecialStatusSheet, if found.
    Dim StatusCell As Range         'This will be set to the status cell of the SerialCell on the MasterSheet.
    Dim MasterSerialRow As Integer  'This will be set to the row number of SerialCell.Value on the MasterSheet.
    Dim StatusColumn As Integer     'This will be set to the index of the "Status" column on the MasterSheet.
    
    StatusColumn = ThisWorkbook.SheetColumnLookup("Status", False, ThisWorkbook.MasterSheet, False)
    'First we have to find that serial number on the MasterSheet to be sure we can even update it.
    If SerialCell.Value = Empty Then
        MasterSerialRow = ThisWorkbook.SheetSerialRowLookup(SerialCell.Comment.Text, ThisWorkbook.MasterSheet)
    Else
        MasterSerialRow = ThisWorkbook.SheetSerialRowLookup(SerialCell.Value, ThisWorkbook.MasterSheet)
    End If
    'If we couldn't find this serial number on the MasterSheet then we give up trying to update its entry on said sheet.
    If MasterSerialRow = 0 Then Exit Sub
    'First we find the status cell of the specified SerialCell to post the status to.
    Set StatusCell = ThisWorkbook.MasterSheet.Cells(MasterSerialRow, StatusColumn)
    If SerialCell.Value = Empty Then
        'If the SerialCell is empty then that means it was probably just deleted, and so we should use the value stored in the
        'SerialCell comment to fetch the CurrentStatus().
        ShippedStatus = Sheets(ThisWorkbook.ShippedSheet.Name).CurrentStatus(SerialCell.Comment.Text)
        CompletedStatus = Sheets(ThisWorkbook.CompletedSheet.Name).CurrentStatus(SerialCell.Comment.Text)
        SpecialStatus = Sheets(ThisWorkbook.SpecialStatusSheet.Name).CurrentStatus(SerialCell.Comment.Text)
    ElseIf SerialCell.Value <> Empty Then
        'If the SerialCell isn't empty then we can use its value to fetch the CurrentStatus().
        ShippedStatus = Sheets(ThisWorkbook.ShippedSheet.Name).CurrentStatus(SerialCell.Value)
        CompletedStatus = Sheets(ThisWorkbook.CompletedSheet.Name).CurrentStatus(SerialCell.Value)
        SpecialStatus = Sheets(ThisWorkbook.SpecialStatusSheet.Name).CurrentStatus(SerialCell.Value)
    End If
    'Here we simply check for the final possible status first and work our way back, if we find a status along the way we stop and
    'report the status that we find first. The logic here is hopefully self-evident.
    Application.EnableEvents = False
    If ShippedStatus <> Empty Then
        StatusCell.Value = ShippedStatus
        Application.EnableEvents = True
        Call CreateHyperlink(StatusCell, SerialCell.Worksheet.Cells(SerialCell.Row, ThisWorkbook.SheetColumnLookup("Serial", False, SerialCell.Worksheet, False)))
        Exit Sub
    ElseIf CompletedStatus <> Empty Then
        StatusCell.Value = CompletedStatus
        Application.EnableEvents = True
        Call CreateHyperlink(StatusCell, SerialCell.Worksheet.Cells(SerialCell.Row, ThisWorkbook.SheetColumnLookup("Serial", False, SerialCell.Worksheet, False)))
        Exit Sub
    ElseIf SpecialStatus <> Empty Then
        StatusCell.Value = SpecialStatus
        Application.EnableEvents = True
        Call CreateHyperlink(StatusCell, SerialCell.Worksheet.Cells(SerialCell.Row, ThisWorkbook.SheetColumnLookup("Serial", False, SerialCell.Worksheet, False)))
        Exit Sub
    Else
        StatusCell.Value = "SCANNED"
        Application.EnableEvents = True
        Call CreateHyperlink(StatusCell, SerialCell.Worksheet.Cells(SerialCell.Row, ThisWorkbook.SheetColumnLookup("Serial", False, SerialCell.Worksheet, False)))
        Exit Sub
    End If

End Sub

Public Sub ClearAllFilters()
Attribute ClearAllFilters.VB_Description = "Clears all filters on all worksheets within this workbook."
Attribute ClearAllFilters.VB_ProcData.VB_Invoke_Func = "R\n14"
    'When called resets all filters on all the sheets within the workbook.

    Dim Sheet As Worksheet      'This will be used in the loop below.

    For Each Sheet In ThisWorkbook.Worksheets
        Call ResetAutoFilter(Sheet)
    Next
    
    MsgBox "All filters reset on all worksheets within this workbook.", vbInformation, "All Filters Reset"

End Sub

Private Sub ResetAutoFilter(ByRef Sheet As Worksheet)
    'When called will instantly disable and then re-enable AutoFilter mode.
    
    'Here we clear our previous filter.
    Sheet.AutoFilterMode = False
    'Then we re-enable AutoFilter.
    Sheet.Cells(1, 1).AutoFilter
    
End Sub

Public Sub SheetFieldLookup(ByRef SerialCell As Range, ByVal TargetHeader As String, ByRef Sheet As Worksheet)
    'When called this will look up the given serial number on the given Sheet and assign the value of the TargetHeader
    'for that serial number to the TargetHeader of the calling sheet.

    Dim SheetSerialRow As Integer               'This will be set to the row index of the gven serial number on the given Sheet, if found.
    Dim SheetTargetColumn As Integer            'This will be set to the column index of the TargetHeader column on the given Sheet, if found.
    Dim SheetTargetCell As Range                'This will be set to the TargetHeader cell of the given serial number on the given Sheet, if found.
    Dim CallingSheetTargetCell As Range         'This will be set to the TargetHeader cell of the given serial number on the calling sheet.
    Dim CallingSheetTargetColumn As Integer     'This will be set to the column index of the TargetHeader column on the calling sheet, if found.

    CallingSheetTargetColumn = ThisWorkbook.SheetColumnLookup(TargetHeader, False, SerialCell.Worksheet, True)
    If CallingSheetTargetColumn = 0 Then
        'If 0 then the column couldn't be found so we ensure all filters are cleared and all rows and columns aren't hidden and try one more time.
        Call ResetAutoFilter(SerialCell.Worksheet)
        Call UnhideAllColumns(SerialCell.Worksheet)
        Call UnhideAllRows(SerialCell.Worksheet)
        CallingSheetTargetColumn = ThisWorkbook.SheetColumnLookup(TargetHeader, False, SerialCell.Worksheet, False)
    End If
    'If 0 then the column still couldn't be found and we simply give up because we can't write a value to a cell we can't reference.
    If CallingSheetTargetColumn = 0 Then Exit Sub
    'Here we find the cell we're trying to populate with the corrisponding data we find on the given Sheet.
    Set CallingSheetTargetCell = SerialCell.Worksheet.Cells(SerialCell.Row, CallingSheetTargetColumn)
    SheetSerialRow = SheetSerialRowLookup(SerialCell.Value, Sheet)
    'If 0 then the row couldn't be found so we ensure all filters are cleared and all rows and columns aren't hidden and try one more time.
    If SheetSerialRow = 0 Then
        Call ResetAutoFilter(Sheet)
        Call UnhideAllColumns(Sheet)
        Call UnhideAllRows(Sheet)
        SheetSerialRow = SheetSerialRowLookup(SerialCell.Value, Sheet)
    End If
    If SheetSerialRow = 0 Then
        'If 0 then the row still couldn't be found.
        'We temporarily disable events to prevent the chance of causing an infinite loop or needlessly recurring code when cahnging cell values.
        Application.EnableEvents = False
        'If the field we're looking up has anything to do with Asset we don't post "*N/A*" per Jon Gregg.
        If InStr(TargetHeader, "Asset") Then
            CallingSheetTargetCell.Value = Empty
        Else
            CallingSheetTargetCell.Value = "*N/A*"
        End If
        Application.EnableEvents = True
        Exit Sub
    End If
    SheetTargetColumn = SheetColumnLookup(TargetHeader, False, Sheet, True)
    'If 0 then the column couldn't be found so we ensure all filters are cleared and all rows and columns aren't hidden and try one more time.
    If SheetTargetColumn = 0 Then
        Call ResetAutoFilter(Sheet)
        Call UnhideAllColumns(Sheet)
        Call UnhideAllRows(Sheet)
        SheetTargetColumn = SheetColumnLookup(TargetHeader, False, Sheet, False)
    End If
    If SheetTargetColumn = 0 Then
        'If 0 then the column still couldn't be found.
        Application.EnableEvents = False
        CallingSheetTargetCell.Value = "*N/A*"
        Application.EnableEvents = True
        Exit Sub
    End If
    Set SheetTargetCell = Sheet.Cells(SheetSerialRow, SheetTargetColumn)
    'If we found the serial number, but the TargetHeader cell is empty, we return as much.
    If SheetTargetCell.Value = Empty Then
        Application.EnableEvents = False
        'If the TargetHeader contains "SIM", "IMEI" or "Tracking" we leave the cell empty; we don't want to see a bunch of bloat data.
        If InStr(TargetHeader, "SIM") Or InStr(TargetHeader, "IMEI") Or InStr(TargetHeader, "Tracking") Then
            CallingSheetTargetCell.Value = Empty
        Else
            CallingSheetTargetCell.Value = "*BLANK*"
        End If
        Application.EnableEvents = True
        Exit Sub
    End If
    'Finally, if we found the serial number, and the SheetTargetCell cell isn't empty, we return the SheetTargetCell.Value.
    If SheetTargetCell.Value <> Empty Then
        Application.EnableEvents = False
        CallingSheetTargetCell.Value = SheetTargetCell.Value
        Application.EnableEvents = True
    End If

End Sub

Public Sub DeleteRow(ByRef SerialCell As Range)
    'This is called when we want to delete an entire row (bold I know) of the given sheet.

    Dim Sheet As Worksheet
    
    Set Sheet = SerialCell.Worksheet
    'First we update the status of the serial number if the deletion is called on a sheet that isn't the Master.
    If Sheet.Name <> ThisWorkbook.MasterSheet.Name And Sheet.Name <> ThisWorkbook.SerialAssetSheet.Name Then Call SetStatus(SerialCell)
    'Then we disable application events before deleting the specified row as this causes various events to fire with (now) a
    'Null reference to the object that was changed. Refer to a Null reference; you're gonna have a bad time.
    Application.EnableEvents = False
    Sheet.Rows(SerialCell.Row).Delete
    Application.EnableEvents = True

End Sub

Public Sub UpdateAsset(ByRef AssetCell As Range)
    'When called we tell the MasterSheet to update the given serial number's asset field.
    
    Dim SheetSerialCell As Range        'This will be set to the serial cell for rhe given asset on the calling sheet.
    Dim SheetSerialColumn As Integer    'This will be set to the column index of the "Serial" column on the calling sheet, if found.
    Dim MasterAssetCell As Range        'This will be set to the asset cell for the calling serial number on the MasterSheet.
    Dim MasterSerialRow As Integer      'This will be ser to the row number of the calling serial number on the MasterSheet.
    Dim MasterAssetColumn As Integer    'This will be set to the column index of the "Asset" column on the MasterSheet, if found.
    
    SheetSerialColumn = ThisWorkbook.SheetColumnLookup("Serial", False, AssetCell.Worksheet, True)
    If SheetSerialColumn = 0 Then
        'If 0 we try again after making sure that data isn't obstructed.
        Call ResetAutoFilter(AssetCell.Worksheet)
        Call UnhideAllColumns(AssetCell.Worksheet)
        Call UnhideAllRows(AssetCell.Worksheet)
        SheetSerialColumn = ThisWorkbook.SheetColumnLookup("Serial", False, AssetCell.Worksheet, False)
    End If
    'If still 0 we give up quietly.
    If SheetSerialColumn = 0 Then Exit Sub
    Set SheetSerialCell = ThisWorkbook.SerialAssetSheet.Cells(AssetCell.Row, SheetSerialColumn)
    MasterSerialRow = ThisWorkbook.SheetSerialRowLookup(SheetSerialCell.Value, ThisWorkbook.MasterSheet)
    If MasterSerialRow = 0 Then
        'If 0 we try again after making sure that data isn't obstructed.
        Call ResetAutoFilter(ThisWorkbook.MasterSheet)
        Call UnhideAllColumns(ThisWorkbook.MasterSheet)
        Call UnhideAllRows(ThisWorkbook.MasterSheet)
        MasterSerialRow = ThisWorkbook.SheetSerialRowLookup(SheetSerialCell.Value, ThisWorkbook.MasterSheet)
    End If
    'If still 0 we give up quietly.
    If MasterSerialRow = 0 Then Exit Sub
    MasterAssetColumn = ThisWorkbook.SheetColumnLookup("Asset", False, ThisWorkbook.MasterSheet, True)
    If MasterAssetColumn = 0 Then
        'If 0 we try again after making sure that data isn't obstructed.
        Call ResetAutoFilter(ThisWorkbook.MasterSheet)
        Call UnhideAllColumns(ThisWorkbook.MasterSheet)
        Call UnhideAllRows(ThisWorkbook.MasterSheet)
        MasterAssetColumn = ThisWorkbook.SheetColumnLookup("Asset", False, ThisWorkbook.MasterSheet, False)
    End If
    'If still 0 we give up quietly.
    If MasterAssetColumn = 0 Then Exit Sub
    Set MasterAssetCell = ThisWorkbook.MasterSheet.Cells(MasterSerialRow, MasterAssetColumn)
    If AssetCell.Value = Empty Then
        MasterAssetCell.Value = "*BLANK*"
    ElseIf AssetCell.Value <> Empty Then
        MasterAssetCell.Value = AssetCell.Value
    End If

End Sub

Public Sub ToUpperCase(ByRef Cell As Range)
    'When called this forces the text within the passed cell to be upper-case.

    'We don't want this functionality to apply to sheet headers, so we check for that.
    If Cell.Row = 1 Then Exit Sub
    'First we disable events to prevent an infinite loop.
    Application.EnableEvents = False
    Cell.Value = UCase(Cell.Value)
    'Then we enable events to allow the sheet to function again.
    Application.EnableEvents = True

End Sub

Public Function HeaderCount(ByRef Sheet As Worksheet) As Integer
    'When called will return the number of contiguous cells in row 1 of the specified worksheet that aren't empty.

    Dim HeaderRange As Range                'This will be set to the header row (row 1) of the given worksheet.
    Dim Cel As Range                        'This will be set to the cell within the for each loop below.
    Dim ColumnCount As Integer              'This will be set to the number of columns with headers in row 1.
    
    'Here we count how many columns have headers, and therefore how many cells in the new row we need to format.
    Set HeaderRange = Sheet.Rows(1).Cells
    For Each Cel In HeaderRange
        'If this header cell isn't empty, then it is an active header and we count it.
        If Cel.Value <> Empty Then
            ColumnCount = ColumnCount + 1
        ElseIf Cel.Value = Empty Then
            'The first empty header cell we find is (probably) the end of the active headers, so we stop checking.
            Exit For
        End If
    Next
    'Here we return ColumnCount.
    HeaderCount = ColumnCount

End Function

Public Sub ExtendFormatting(ByRef FormatCell As Range)

    Dim TargetCell As Range     'This will be used in the loop below to check the cell for formatting.
    
    Set TargetCell = FormatCell
    Do Until TargetCell.NumberFormatLocal <> FormatCell.NumberFormatLocal
        Set TargetCell = TargetCell.Offset(1, 0)
    Loop
    'Here we go back 2 rows so that we are within the blank formatted rows.
    Set TargetCell = TargetCell.Offset(-2, 0)
    Application.EnableEvents = False
    TargetCell.EntireRow.Insert
    Application.EnableEvents = True

End Sub

Public Sub MigrateDataSelection()
    'When called this will ask for the path of the previous version of the ongoing master and will fetch all non-shipped units.

    Dim FileSelectionDialog As FileDialog       'This will be set to the file dialog object itself for later referencing.
    Dim SelectedFile As Variant                 'This will contain the entire path of the file selected.
    Dim MigratingBook As Workbook               'This will be set to the selected workbook once it is open, for future referencing.

    Set FileSelectionDialog = Application.FileDialog(msoFileDialogOpen)
    With FileSelectionDialog
        .AllowMultiSelect = False
        .Title = "Select an Ongoing Master workbook."
        .ButtonName = "Migrate Data"
    
        'Any number other than 0 is true, and if the user cancels the dialog it will return 0.
        If .Show Then
            'Here we make doubly sure that there was only 1 file selected, otherwise things could get messy, but in a bad way.
            If .SelectedItems.Count = 1 Then
                For Each SelectedFile In .SelectedItems
                    'Here we open the selected master in ReadOnly mode to prevent potential conflicts if someone else is using the file.
                    'And also to prevent any chance of a freak accident resulting in the modification or destruction of the original data.
                    Set MigratingBook = Application.Workbooks.Open(CStr(SelectedFile), ReadOnly = True)
                    Call MigrateData(MigratingBook)
                    'Finally we exit the for loop after the first iteration as a final check to be sure only 1 file is operated on.
                    Exit For
                Next
            End If
        End If
    End With

End Sub

Private Sub MigrateData(ByRef MigratingBook As Workbook)

    Dim Sheet As Worksheet              'This will be set to each sheet within ThisWorkbook.
    Dim MigratingSheet As Worksheet     'This will be set to each sheet within MigratingBook.
    Dim MigratingColumn As Integer      'This will be set to each column within MigratingSheet.
    Dim Counter As Integer              'This will be used within a for loop below in place of an inconsistent for each loop.
    Dim SheetSerialRange As Range       'This will be set to the serials that were migrated to the (not master) sheet so the lookup function may use them as a reference.
    Dim MasterSerialRange As Range      'This will be the base set of serial numbers we are migrating, initially this will be set to the migrating master's serial column, then it will be set to the new master's serial column.
    Dim Cel As Range                    'This will be set to each cell within a for each loop.
    Dim TransferCell As Range           'This will be set to the cell we are currently transferring data to.
    Dim SerialColumn As Integer         'This will be set to the index of the "Serial" column on each Sheet.
    Dim SerialRow As Integer            'This will be set to the row index of the specificed serial on the MigratingSheet.
    Dim DateColumnIndex As Integer      'This will be set to the column index of the Date column per sheet.
    Dim StatusCell As Range             'This will be set only once to the first status cell on the master to reference later, primarily for it's color index value.
    
    If MigratingBook.MultiUserEditing Then
        MsgBox "Workbook sharing needs to be disabled on " & MigratingBook.Name & " for migration. Migration canceled.", vbCritical, MigratingBook.Name & " Sharing"
        Exit Sub
    End If
    
    For Each Sheet In ThisWorkbook.Sheets
        Sheet.Activate
        'Here we attempt to find the sheet with the same name as the Sheet within the MigratingBook.
        Set MigratingSheet = MigratingBook.Sheets(Sheet.Name)
        On Error GoTo ContinueLoop
        'First we check for the most specific type of Serial column.
        SerialColumn = ThisWorkbook.SheetColumnLookup("Unit Serial", False, Sheet, True)
        If SerialColumn = 0 Then
            'If the more specific variant isn't found then we broaden our search.
            SerialColumn = ThisWorkbook.SheetColumnLookup("Serial", False, Sheet, True)
        End If
        'Here we get the column index of the date column for this sheet for later comparrison.
        DateColumnIndex = ThisWorkbook.SheetColumnLookup("Date", False, Sheet, True)
        If Sheet.Name = ThisWorkbook.MasterSheet.Name Then
            'Since the MasterSheet is the only sheet that displays a unit's status it must be treated differently.
            MigratingColumn = ThisWorkbook.SheetColumnLookup("Status", False, MigratingSheet, True)
            'Here we apply a custom Text Filter that excludes all rows with the "Shipped" status or are simply blank rows.
            MigratingSheet.Columns(MigratingColumn).AutoFilter MigratingColumn, Criteria1:="<>SHIPPED", Criteria2:="<>"
            'Here we set the MasterSerialRange to only the serial column cells that show through our filter on the migrating master for future referencing.
            Set MasterSerialRange = MigratingSheet.UsedRange.Columns(ThisWorkbook.SheetColumnLookup("Serial", False, MigratingSheet, True)).Offset(1, 0).SpecialCells(xlCellTypeVisible)
            'The code block below is responsible for migrating the serials first.
            'Here we get the first empty cell in the column on the new sheet.
            Set TransferCell = Sheet.Cells(Sheet.UsedRange.Rows.Count, SerialColumn).End(xlUp).Offset(1, 0)
            For Each Cel In MasterSerialRange
                If Cel.Value = Empty Then Exit For
                DoEvents
                'If SerialRow is 0 then that serial number isn't present on this sheet, and therefore doesn't need to be migrated.
                SerialRow = ThisWorkbook.SheetSerialRowLookup(Cel.Value, MigratingSheet)
                If SerialRow <> 0 Then
                    TransferCell.Value = MigratingSheet.Cells(SerialRow, SerialColumn).Value
                    Set TransferCell = TransferCell.Offset(1, 0)
                    'Activating the TransferCell isn't necessary but it allows the user to see the migration process step by step.
                    TransferCell.Activate
                End If
            Next
            'Here we set the MasterSerialRange to the newly migrated serial column cells on the MasterSheet and do not set it again.
            Set MasterSerialRange = Range(ThisWorkbook.MasterSheet.Cells(2, SerialColumn), ThisWorkbook.MasterSheet.Cells(Sheet.UsedRange.Rows.Count, SerialColumn))
            'Here we set the SheetSerialRange to the newly migrated serial column cells on this sheet.
            Set SheetSerialRange = MasterSerialRange
            'Here we set StatusCell to the first status cell on the MasterSheet so we can reference its ColorIndex.
            Set StatusCell = Sheet.Cells(2, ThisWorkbook.SheetColumnLookup("Status", False, Sheet, False))
        ElseIf Sheet.Name <> ThisWorkbook.MasterSheet.Name Then
            'If the current sheet we're migrating to isn't the MasterSheet (which we assume was migrated first) then we simply pull
            'all the relevant information from each sheet for each serial number in SerialRange.
            'The code block below is responsible for migrating the serials first on every other sheet other than the Master.
            'Here we get the first empty cell in the column on the new sheet.
            Set TransferCell = Sheet.Cells(Sheet.UsedRange.Rows.Count, SerialColumn).End(xlUp).Offset(1, 0)
            For Each Cel In MasterSerialRange
                If Cel.Value <> Empty Then
                    DoEvents
                    SerialRow = ThisWorkbook.SheetSerialRowLookup(Cel.Value, MigratingSheet)
                    'If SerialRow is 0 then that serial number isn't present on this sheet, and therefore doesn't need to be migrated.
                    If SerialRow <> 0 Then
                        'Here we "move" the found serial number to this sheet by transfering the cell value.
                        TransferCell.Value = MigratingSheet.Cells(SerialRow, SerialColumn).Value
                        'Then we move the TransferCell down 1 row for the next serial we migrate and activate it.
                        Set TransferCell = TransferCell.Offset(1, 0)
                        'Activating the TransferCell isn't necessary but it allows the user to see the migration process step by step.
                        TransferCell.Activate
                    End If
                End If
            Next
            'Here we set the SheetSerialRange to the newly migrated serial column cells on this sheet.
            Set SheetSerialRange = Range(Sheet.Cells(2, SerialColumn), Sheet.Cells(Sheet.UsedRange.Rows.Count, SerialColumn))
        End If
        For Counter = 1 To HeaderCount(Sheet)
            'First we make sure not to try and transfer serial numbers again because bad cyclical things...won't happen?
            If Counter <> SerialColumn Then 'And Counter <> ThisWorkbook.SheetColumnLookup("Tracking", False, Sheet, True) Then 'HERE
                'Here we attempt to find the column with the same header as the one we need to populate the new master.
                MigratingColumn = ThisWorkbook.SheetColumnLookup(Sheet.Cells(1, Counter).Value, False, MigratingSheet, True)
                'If we don't find the column we need, we don't panic, but let the user know and move on.
                If MigratingColumn <> 0 Then
                    'Here we get the first empty cell in the column on the new sheet.
                    Set TransferCell = Sheet.Cells(Sheet.UsedRange.Rows.Count, Counter).End(xlUp).Offset(1, 0)
                    For Each Cel In SheetSerialRange
                        If Cel.Value <> Empty Then
                            DoEvents
                            'If TransferCell is set to a row other than the row SheetFieldLookup() is populating, then we correct it.
                            'This can happen in columns such as the date column where information is automatically generated based on
                            'related information being entered prior, such as a serial number.
                            'The TransferCell is only used for visual purposes and has nothing to do with data transfer.
                            If TransferCell.Row <> Cel.Row Then Set TransferCell = Sheet.Cells(Cel.Row, Counter)
                            If TransferCell.Interior.ColorIndex = StatusCell.Interior.ColorIndex And Counter <> DateColumnIndex Then
                                'Then we don't do anything as a cell with a non-default interior color is likely an auto-generating cell and will not accept
                                'any migratory data so we assume we can skip this column and exit this nested For loop.
                                Exit For
                            Else
                                'Otherwise we activate the cell and attempt to populate it with migrated data.
                                TransferCell.Activate
                                Call ThisWorkbook.SheetFieldLookup(Cel, CStr(Sheet.Cells(1, Counter).Value), MigratingSheet)
                            End If
                            Set TransferCell = TransferCell.Offset(1, 0)
                        End If
                    Next
                ElseIf MigratingColumn = 0 Then
                       MsgBox "Unable to locate the " & Sheet.Cells(1, Counter).Value & " column on the " & Sheet.Name & " sheet of " & MigratingBook.Name, vbInformation, "Unable to locate the " & Sheet.Cells(1, Counter).Value & " column"
                End If
            End If
        Next
ContinueLoop:
    Next
    
    'We re-enter serials to update status on master.
    Set SheetSerialRange = Range(SpecialStatusSheet.Cells(2, SheetColumnLookup("Serial", False, SpecialStatusSheet, False)), SpecialStatusSheet.Cells(SpecialStatusSheet.UsedRange.Rows.Count, SheetColumnLookup("Serial", False, SpecialStatusSheet, False)))
    For Each Cel In SheetSerialRange
        Cel.Value = Cel.Value
    Next
    
    'Here we re-enter locations to create history comment.
    Set SheetSerialRange = Range(ThisWorkbook.MasterSheet.Cells(2, SheetColumnLookup("Location", False, ThisWorkbook.MasterSheet, False)), ThisWorkbook.MasterSheet.Cells(ThisWorkbook.MasterSheet.UsedRange.Rows.Count, SheetColumnLookup("Location", False, ThisWorkbook.MasterSheet, False)))
    ThisWorkbook.MasterSheet.Activate
    For Each Cel In SheetSerialRange
        If Cel.Value <> Empty Then
            Cel.Value = Cel.Value
        End If
        Cel.Activate
        DoEvents
    Next
    
    MsgBox "Data migration from " & MigratingBook.Name & " complete!", vbOKOnly, "Data Migration Complete"
    'Now we clear any fitlers we may have applied in order to migrate the data.
    For Each Sheet In MigratingBook.Sheets
        Sheet.AutoFilterMode = False
    Next
    'We close the workbook we migrated from and do not save changes.
    MigratingBook.Close (False)
    
    'Finally we set the FirstSave boolean to true so we can catch the AfterSave event and enable sharing.
    If ThisWorkbook.ReadOnly And ThisWorkbook.MultiUserEditing = False Then
        FirstSave = True
    End If

End Sub

Public Sub CreateHyperlink(ByRef TargetCell As Range, ByRef DestinationCell As Range)
    'When called will create a hyperlink within TargetCell, using TargetCell's value as the display text, leading to DestinationCell.
    
    'Turns out for some reason Microsoft can't get Excel to create hyperlinks while the workbook is shared.
    'Hyperlinks work while the workbook is shared, but cannot be created so if we're sharing then we bail.
    If ThisWorkbook.MultiUserEditing = True Then Exit Sub
    If TargetCell.Hyperlinks.Count > 0 Then
        Application.EnableEvents = False
        With TargetCell.Hyperlinks.Item(1)
            .Address = ""
            .SubAddress = "'" & DestinationCell.Worksheet.Name & "'!" & DestinationCell.Address
            .ScreenTip = "Go to " & TargetCell.Worksheet.Cells(TargetCell.Row, ThisWorkbook.SheetColumnLookup("Serial", False, TargetCell.Worksheet, False)).Value & " on the " & DestinationCell.Worksheet.Name & " sheet."
            .TextToDisplay = TargetCell.Value
        End With
    Else
        TargetCell.Hyperlinks.Add TargetCell, "", "'" & DestinationCell.Worksheet.Name & "'!" & DestinationCell.Address, "Go to " & TargetCell.Worksheet.Cells(TargetCell.Row, ThisWorkbook.SheetColumnLookup("Serial", False, TargetCell.Worksheet, False)).Value & " on the " & DestinationCell.Worksheet.Name & " sheet.", TargetCell.Value
    End If
    Application.EnableEvents = True
    
End Sub
