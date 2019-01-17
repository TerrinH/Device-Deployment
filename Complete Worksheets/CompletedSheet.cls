VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet3"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

Dim CustomerColumn As Integer   'This will be set to the index of the "Customer" column on this Worksheet.
Dim UnitSerialColumn As Integer 'This will be set to the index of the "Unit Serial" column on this Worksheet.
Dim UnitModelColumn As Integer 'This will be set to the index of the "Unit Model" column on this Worksheet.
Dim LocationColumn As Integer   'This will be set to the index of the "Location" column on this Worksheet.
Dim DateColumn As Integer       'The column number of the column with the header of "Date" on this worksheet.
Dim SheetInitialized As Boolean 'This will be false by default (Null of Boolean is False) and set to true after first sheet activation.

Private Sub Worksheet_Activate()
    'This is called every time the sheet is activated in order to be sure we have the latest column locations.
    
    'If this sheet hasn't been initialized then we need to perform some 'first-time setup' instructions.
    If Not SheetInitialized Then
        SheetInitialized = True
        Set ThisWorkbook.CompletedSheet = ThisWorkbook.ActiveSheet
        'Here we specifically set the active cell to the first empty cell in column 1 (A).
        ThisWorkbook.CompletedSheet.Range("A" & ThisWorkbook.CompletedSheet.UsedRange.Rows.Count).End(xlUp).Offset(1, 0).Select
    End If
    CustomerColumn = ThisWorkbook.SheetColumnLookup("Customer", False, ThisWorkbook.CompletedSheet, False)
    UnitSerialColumn = ThisWorkbook.SheetColumnLookup("Unit Serial", False, ThisWorkbook.CompletedSheet, False)
    UnitModelColumn = ThisWorkbook.SheetColumnLookup("Model", False, ThisWorkbook.CompletedSheet, False)
    LocationColumn = ThisWorkbook.SheetColumnLookup("Location", False, ThisWorkbook.CompletedSheet, False)
    DateColumn = ThisWorkbook.SheetColumnLookup("Date", False, ThisWorkbook.CompletedSheet, False)

End Sub

Private Sub Worksheet_Change(ByVal Target As Range)
    'Called whenever something changes on this worksheet. This is where we catch modifications to our cells and then make things happen.
    
    'Here we loop through all the changed cells and handle them individually, even if there's only 1.
    Dim TargetCell As Range
    For Each TargetCell In Target.Cells
        If TargetCell Is Nothing Or TargetCell.Row = 1 Then
            Exit Sub
        End If
        'Here we force all input to be uppercase.
        Call ThisWorkbook.ToUpperCase(TargetCell)
        'Here we check and see if the column of the TargetCell was the CustomerColumn.
        If TargetCell.Column = CustomerColumn Then Call CustomerEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the LocationColumn.
        If TargetCell.Column = LocationColumn Then Call LocationEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the DateColumn.
        If TargetCell.Column = DateColumn Then Call DateEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the UnitModelColumn.
        If TargetCell.Column = UnitModelColumn Then Call ModelEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the SerialColumn.
        'NOTE: The SerialColumn check must be the last we check for, because if the TargetCell is within the SerialColumn, and its
        'NOTE: value was deleted, then further references to TargetCell will be Null because we end up deleting the row later in the code.
        'NOTE: Refer to a Null reference; you're gonna have a bad time.
        If TargetCell.Column = UnitSerialColumn Then Call UnitSerialEvent(TargetCell)
        DoEvents
    Next
    
End Sub

Private Sub UnitSerialEvent(ByRef UnitSerialCell As Range)
    'When called will perform all the operations that hinge upon a serial cell being changed.

    'Every sheet that isn't the MasterSheet needs to report to the MasterSheet that the status of this unit has changed.
    Call ThisWorkbook.SetStatus(UnitSerialCell)
    'If the change to the SerialCell results in the cell's value being set to Empty, then we delete the entire row.
    'This is done in order to force the user to re-enter all of the associated data and prevent possible serial/data association mix-ups.
    If UnitSerialCell.Value = Empty Then
        Call ThisWorkbook.DeleteRow(UnitSerialCell)
        Exit Sub
    End If
    'If the UnitSerialCell isn't empty then a serial number was entered, and we commit that to the same cell's comment.
    Call ThisWorkbook.CreateCellComment(UnitSerialCell, False)
    'Here we set the date for the cell and update its status.
    Call ThisWorkbook.SetDate(UnitSerialCell)
    'Then we fetch the customer name associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(UnitSerialCell, "Customer", ThisWorkbook.MasterSheet)
    'And then we fetch the Location the serial number was assigned to.
    Call ThisWorkbook.SheetFieldLookup(UnitSerialCell, "Location", ThisWorkbook.MasterSheet)
    'And then we fetch the Model the serial number was assigned to.
    Call ThisWorkbook.SheetFieldLookup(UnitSerialCell, "Unit Model", ThisWorkbook.MasterSheet)
    'Then we extend the formatting to maintain 60 rows of wiggle room for data entry.
    Call ThisWorkbook.ExtendFormatting(UnitSerialCell)

End Sub

Private Sub DateEvent(ByRef DateCell As Range)
    'When called will perform all the operations that hinge upon a date cell being changed.
    
    Call ThisWorkbook.SetDate(DateCell)
    
End Sub

Public Function CurrentStatus(ByRef Serial As String) As String
    'This function will report the status of the given serial number on this sheet, typically with a binary (non-numerically binary) result.
    
    Dim SerialRow As Integer    'This will be set to the row number of the given serial number.
    
    SerialRow = ThisWorkbook.SheetSerialRowLookup(Serial, ThisWorkbook.CompletedSheet)
    If SerialRow = 0 Then
        'If 0 then the given serial number couldn't be found on this sheet so we return Empty to convey this.
        CurrentStatus = Empty
        Exit Function
    ElseIf SerialRow <> 0 Then
        'If the Serial is found then we return "Completed" status.
        CurrentStatus = "COMPLETED"
        Exit Function
    End If
    
End Function

Private Sub CustomerEvent(ByRef CustomerCell As Range)
    'When called will perform all the operations that hinge upon a customer cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the CustomerCell.

    Set SerialCell = CustomerCell.Worksheet.Cells(CustomerCell.Row, UnitSerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    'And then we fetch the customer associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Customer", ThisWorkbook.MasterSheet)
    Application.EnableEvents = True

End Sub

Private Sub LocationEvent(ByRef LocationCell As Range)
    'When called will perform all the operations that hinge upon a location cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the LocationCell.

    Set SerialCell = LocationCell.Worksheet.Cells(LocationCell.Row, UnitSerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    'And then we fetch the location associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Location", ThisWorkbook.MasterSheet)
    Application.EnableEvents = True

End Sub

Private Sub ModelEvent(ByRef ModelCell As Range)
    'When called will perform all the operations that hinge upon a model cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the LocationCell.

    Set SerialCell = ModelCell.Worksheet.Cells(ModelCell.Row, UnitSerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    'And then we fetch the location associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Unit Model", ThisWorkbook.MasterSheet)
    Application.EnableEvents = True

End Sub
