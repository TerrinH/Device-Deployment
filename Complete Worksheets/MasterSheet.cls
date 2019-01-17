VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

Dim SerialColumn As Integer     'This will be the column index of the "Serial" column on this worksheet.
Dim AssetColumn As Integer      'This will be the column index of the "Asset" column on this worksheet.
Dim DateColumn As Integer       'This will be the column index of the "Date" column on this worksheet.
Dim StatusColumn As Integer     'This will be the column index of the "Status" column on this worksheet.
Dim LocationColumn As Integer   'This will be the column index of the "Status" column on this worksheet.
Dim SheetInitialized As Boolean 'This will be false by default (Null of Boolean is False) and set to true after first sheet activation.

Private Sub Worksheet_Activate()
    'This is called every time the sheet is activated in order to be sure we have the latest column locations.
    
    'If this sheet hasn't been initialized then we need to perform some 'first-time setup' instructions.
    If Not SheetInitialized Then
        SheetInitialized = True
        Set ThisWorkbook.MasterSheet = ThisWorkbook.ActiveSheet
        'Here we specifically set the active cell to the first empty cell in column 1 (A).
        ThisWorkbook.MasterSheet.Range("A" & ThisWorkbook.MasterSheet.UsedRange.Rows.Count).End(xlUp).Offset(1, 0).Select
    End If
    'Here we look up our column indexes for future use by the rest of the code on this sheet.
    SerialColumn = ThisWorkbook.SheetColumnLookup("Unit Serial", False, ThisWorkbook.MasterSheet, False)
    AssetColumn = ThisWorkbook.SheetColumnLookup("Asset", False, ThisWorkbook.MasterSheet, False)
    DateColumn = ThisWorkbook.SheetColumnLookup("Date", False, ThisWorkbook.MasterSheet, False)
    StatusColumn = ThisWorkbook.SheetColumnLookup("Status", False, ThisWorkbook.MasterSheet, False)
    LocationColumn = ThisWorkbook.SheetColumnLookup("Location", False, ThisWorkbook.MasterSheet, False)

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
        If TargetCell.Column = AssetColumn Then Call AssetEvent(TargetCell)
        If TargetCell.Column = DateColumn Then Call DateEvent(TargetCell)
        If TargetCell.Column = StatusColumn Then Call StatusEvent(TargetCell)
        If TargetCell.Column = LocationColumn Then Call LocationEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the SerialColumn.
        'NOTE: The SerialColumn check must be the last we check for, because if the TargetCell is within the SerialColumn, and its
        'NOTE: value was deleted, then further references to TargetCell will be Null because we end up deleting the row later in the code.
        'NOTE: Refer to a Null reference; you're gonna have a bad time.
        If TargetCell.Column = SerialColumn Then Call SerialEvent(TargetCell)
        DoEvents
    Next
    
End Sub

Private Sub SerialEvent(ByRef SerialCell As Range)
    'When called will perform all the operations that hinge upon a serial cell being changed.

    'If the change to the SerialCell results in the cell's value being set to Empty, then we delete the entire row.
    'This is done in order to force the user to re-enter all of the associated data and prevent possible serial/data association mix-ups.
    If SerialCell.Value = Empty Then
        Call ThisWorkbook.DeleteRow(SerialCell)
        Exit Sub
    End If
    Call ThisWorkbook.SetDate(SerialCell)
    Call ThisWorkbook.SetStatus(SerialCell)
    'Here we fetch the Asset the serial number was assigned to.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Asset", ThisWorkbook.SerialAssetSheet)
    'Then we extend the formatting to maintain 60 rows of wiggle room for data entry.
    Call ThisWorkbook.ExtendFormatting(SerialCell)

End Sub

Private Sub AssetEvent(ByRef AssetCell As Range)
    'When called will perform all the operations that hinge upon an asset cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the asset.
    
    Set SerialCell = AssetCell.Worksheet.Cells(AssetCell.Row, SerialColumn)
    'Here we fetch the Asset the serial number was assigned to.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Asset", ThisWorkbook.SerialAssetSheet)

End Sub

Private Sub StatusEvent(ByRef StatusCell As Range)
    'When called will perform all the operations that hinge upon a status cell being changed.

    Dim SerialCell As Range     'This will be set to the serial cell of the StatusCell.
    
    Set SerialCell = StatusCell.Worksheet.Cells(StatusCell.Row, SerialColumn)
    'We have to disable and then re-enable events later on to prevent potential infinite loops.
    Application.EnableEvents = False
    Call ThisWorkbook.SetStatus(SerialCell)
    Application.EnableEvents = True

End Sub

Private Sub DateEvent(ByRef DateCell As Range)
    'When called will perform all the operations that hinge upon a date cell being changed.
    
    Call ThisWorkbook.SetDate(DateCell.Worksheet.Cells(DateCell.Row, SerialColumn))
    
End Sub

Private Sub LocationEvent(ByRef LocationCell As Range)
    'When called will perform all the operations that hinge upon a location cell being changed.
    
    Call ThisWorkbook.CreateCellComment(LocationCell, True)
    
End Sub
