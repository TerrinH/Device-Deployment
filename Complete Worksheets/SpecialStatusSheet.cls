VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

Dim SerialColumn As Integer         'The column number of the column with the header of "Serial" on this worksheet.
Dim ModelColumn As Integer          'The column number of the column with the header of "Model" on this worksheet.
Dim CustomerColumn As Integer       'The column number of the column with the header of "Customer" on this worksheet.
Dim StatusColumn As Integer         'The column number of the column with the header of "Status" on this worksheet.
Dim LocationColumn As Integer       'The column number of the column with the header of "Location" on this worksheet.
Dim DateColumn As Integer           'The column number of the column with the header of "Date" on this worksheet.
Dim CommentColumn As Integer        'The column number of the column with the header of "Comment" on this worksheet.
Dim SheetInitialized As Boolean     'This will be false by default (Null of Boolean is False) and set to true after first sheet activation.

Private Sub Worksheet_Activate()
    'This is called every time the sheet is activated in order to be sure we have the latest column locations.
    
    'If this sheet hasn't been initialized then we need to perform some 'first-time setup' instructions.
    If Not SheetInitialized Then
        SheetInitialized = True
        Set ThisWorkbook.SpecialStatusSheet = ThisWorkbook.ActiveSheet
        'Here we specifically set the active cell to the first empty cell in column 1 (A).
        ThisWorkbook.SpecialStatusSheet.Range("A" & ThisWorkbook.SpecialStatusSheet.UsedRange.Rows.Count).End(xlUp).Offset(1, 0).Select
    End If
    Call UpdateColumnIndexes

End Sub

Private Sub Worksheet_Change(ByVal Target As Range)
    'Called whenever something changes on this worksheet. This is where we catch modifications to our cells and then make things happen.
    
    'Here we loop through all the changed cells and handle them individually, even if there's only 1.
    Dim TargetCell As Range
    For Each TargetCell In Target.Cells
        If TargetCell Is Nothing Then Exit Sub
        If TargetCell.Row = 1 Then
            Call UpdateColumnIndexes
            Exit Sub
        End If
        'Here we force all input to be uppercase.
        Call ThisWorkbook.ToUpperCase(TargetCell)
        'Here we check and see if the column of the TargetCell was the ModelColumn.
        If TargetCell.Column = ModelColumn Then Call ModelEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the CustomerColumn.
        If TargetCell.Column = CustomerColumn Then Call CustomerEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the LocationColumn.
        If TargetCell.Column = LocationColumn Then Call LocationEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the DateColumn.
        If TargetCell.Column = DateColumn Then Call DateEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the CommentColumn.
        If TargetCell.Column = CommentColumn Then Call CommentEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the StatusColumn.
        If TargetCell.Column = StatusColumn Then Call StatusEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the SerialColumn.
        'NOTE: The SerialColumn check must be the last we check for, because if the TargetCell is within the SerialColumn, and its
        'NOTE: value was deleted, then further references to TargetCell will be Null because we end up deleting the row later in the code.
        'NOTE: Refer to a Null reference; you're gonna have a bad time.
        If TargetCell.Column = SerialColumn Then Call SerialEvent(TargetCell)
        DoEvents
    Next
    
End Sub

Private Sub UpdateColumnIndexes()
    'When called will search for and update all tracked column indexes.
    
    'Critical column lookups that fail will be reported.
    SerialColumn = ThisWorkbook.SheetColumnLookup("Unit Serial", False, ThisWorkbook.SpecialStatusSheet, False)
    ModelColumn = ThisWorkbook.SheetColumnLookup("Unit Model", False, ThisWorkbook.SpecialStatusSheet, True)
    CustomerColumn = ThisWorkbook.SheetColumnLookup("Customer", False, ThisWorkbook.SpecialStatusSheet, True)
    StatusColumn = ThisWorkbook.SheetColumnLookup("Status", False, ThisWorkbook.SpecialStatusSheet, False)
    LocationColumn = ThisWorkbook.SheetColumnLookup("Location", False, ThisWorkbook.SpecialStatusSheet, True)
    DateColumn = ThisWorkbook.SheetColumnLookup("Date", False, ThisWorkbook.SpecialStatusSheet, True)
    CommentColumn = ThisWorkbook.SheetColumnLookup("Comment", False, ThisWorkbook.SpecialStatusSheet, True)

End Sub

Private Sub SerialEvent(ByRef SerialCell As Range)
    'When called will perform all the operations that hinge upon a serial cell being changed.
    
    'Every sheet that isn't the MasterSheet needs to report to the MasterSheet that the status of this unit has changed, and we do so below.
    Call ThisWorkbook.SetStatus(SerialCell)
    'If the change to the SerialCell results in the cell's value being set to Empty, then we delete the entire row.
    'This is done in order to force the user to re-enter all of the associated data and prevent possible serial/data association mix-ups.
    If SerialCell.Value = Empty Then
        Call ThisWorkbook.DeleteRow(SerialCell)
        Exit Sub
    End If
    'If the SerialCell isn't empty then a serial number was entered, and we commit that to the same cell's comment.
    Call ThisWorkbook.CreateCellComment(SerialCell, False)
    Call ThisWorkbook.SetDate(SerialCell)
    'Then we fetch the customer name associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Customer", ThisWorkbook.MasterSheet)
    'And then we fetch the Model associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Unit Model", ThisWorkbook.MasterSheet)
    'And then we fetch the Location the serial number was assigned to.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Location", ThisWorkbook.MasterSheet)
    'Finally, we extend the formatting to maintain 60 rows of wiggle room for data entry.
    Call ThisWorkbook.ExtendFormatting(SerialCell)

End Sub

Private Sub StatusEvent(ByRef StatusCell As Range)
    'When called will perform all the operations that hinge upon a status cell being changed.
    
    Dim SerialCell As Range 'This will be the serial number cell itself as a cell, value and all.

    Set SerialCell = ThisWorkbook.SpecialStatusSheet.Cells(StatusCell.Row, SerialColumn)
    Call ThisWorkbook.SetStatus(SerialCell)
    
End Sub

Private Sub DateEvent(ByRef DateCell As Range)
    'When called will perform all the operations that hinge upon a date cell being changed.
    
    Call ThisWorkbook.SetDate(DateCell)
    
End Sub

Private Sub CommentEvent(ByRef CommentCell As Range)
    'When called will perform all the operations that hinge upon a comment cell being changed.
    
    Dim Serial As String                'This will store the serial number as a string of characters.
    Dim MasterRow As Integer            'This will contain the row number of the Serial on the MasterSheet.
    Dim CommentText As String           'This will contain the comment entered in the CommentCell.
    Dim MasterStatusColumn As Integer   'The column number of the column with the header of "Status" on the MasterSheet.

    'We get our MasterSheet status column index. We don't handle a return of 0 because at this point the user would already be well aware.
    MasterStatusColumn = ThisWorkbook.SheetColumnLookup("Status", False, ThisWorkbook.MasterSheet, False)
    'We check and make sure that the comment was entered with a valid serial number in the serial cell of that row.
    If ThisWorkbook.SpecialStatusSheet.Cells(CommentCell.Row, SerialColumn).Value <> Empty Then
        'Get the actual serial number so we can search for it on the master.
        Serial = ThisWorkbook.SpecialStatusSheet.Cells(CommentCell.Row, SerialColumn).Value
        'Find the serial number on the MasterSheet and return its row.
        MasterRow = ThisWorkbook.SheetSerialRowLookup(Serial, ThisWorkbook.MasterSheet)
        If MasterRow <> 0 Then
            'If we find the serial number on the MasterSheet then we can add the comment text to the status cell
            'for that serial number and under the user's login name.
            CommentText = CommentCell.Value
            'If there isn't any text to post for the comment then we immediately give up.
            If CommentText = Empty Then Exit Sub
            'If the CommentText isn't Empty we clear any previous comments to prevent any creation conflicts.
            ThisWorkbook.MasterSheet.Cells(MasterRow, MasterStatusColumn).ClearComments
            'Then we create a comment on the status cell found on the MasterSheet with the Windows
            'username of the user and the comment supplied in the SpecialStatusSheet.
            With ThisWorkbook.MasterSheet.Cells(MasterRow, MasterStatusColumn).AddComment
                .Text (Environ$("UserName") & Chr(10) & Now & Chr(10) & CommentText)
                .Shape.TextFrame.Characters(1, Len(Environ$("UserName"))).Font.Bold = True
            End With
        Else
            'Here we let the user know that there was a problem looking up the serial number.
            MsgBox "Unable to create special status comment on the " & ThisWorkbook.MasterSheet.Name & " sheet due to " + Serial + " not being present.", vbInformation, "Special Status Comment Error"
        End If
    End If

End Sub

Public Function CurrentStatus(ByRef Serial As String) As String
    'This function will report the status of the given serial number on this sheet, typically with a binary (non-numerically binary) result.

    Dim SerialRow As Integer    'This will contain the row number of the serial given on this worksheet, if present.
    Dim TargetCell As Range     'This will be set to the "Status" cell for the given serial number, if found.
    Dim StatusColumn As Integer 'This will be set to the index of the "Status" column for the given serial number, if found.
    
    SerialRow = ThisWorkbook.SheetSerialRowLookup(Serial, ThisWorkbook.SpecialStatusSheet)
    If SerialRow = 0 Then
        'If 0 then Serial couldn't be found on this sheet so we return Empty to convey this.
        CurrentStatus = Empty
        Exit Function
    End If
    StatusColumn = ThisWorkbook.SheetColumnLookup("Status", False, ThisWorkbook.SpecialStatusSheet, False)
    Set TargetCell = ThisWorkbook.SpecialStatusSheet.Cells(SerialRow, StatusColumn)
    If TargetCell.Value = Empty Then
        'If the serial number is found, but there isn't a special status set at all, then we treat it as if it isn't even here.
        'This alone should be enough to coach the user into investigating their special status entry if it is expected to be here.
        CurrentStatus = Empty
        Exit Function
    ElseIf TargetCell.Value <> Empty Then
        'If the serial number is found, and there is a special status set, then we will return the set status.
        CurrentStatus = TargetCell.Value
        Exit Function
    End If
    
End Function

Private Sub ModelEvent(ByRef ModelCell As Range)
    'When called will perform all the operations that hinge upon a model cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the ModelCell.

    Set SerialCell = ModelCell.Worksheet.Cells(ModelCell.Row, SerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    'And then we fetch the Model associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Unit Model", ThisWorkbook.MasterSheet)
    Application.EnableEvents = True

End Sub

Private Sub CustomerEvent(ByRef CustomerCell As Range)
    'When called will perform all the operations that hinge upon a customer cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the CustomerCell.

    Set SerialCell = CustomerCell.Worksheet.Cells(CustomerCell.Row, SerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    'And then we fetch the customer associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Customer", ThisWorkbook.MasterSheet)
    Application.EnableEvents = True

End Sub

Private Sub LocationEvent(ByRef LocationCell As Range)
    'When called will perform all the operations that hinge upon a location cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the LocationCell.

    Set SerialCell = LocationCell.Worksheet.Cells(LocationCell.Row, SerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    'And then we fetch the location associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Location", ThisWorkbook.MasterSheet)
    Application.EnableEvents = True

End Sub
