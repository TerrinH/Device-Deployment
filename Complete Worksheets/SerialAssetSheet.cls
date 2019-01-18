VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet5"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

Dim CustomerColumn As Integer   'The column number of the column with the header of "Customer" on this worksheet.
Dim SerialColumn As Integer     'The column number of the column with the header of "Serial" on this worksheet.
Dim AssetColumn As Integer      'The column number of the column with the header of "Asset" on this worksheet.
Dim DateColumn As Integer       'The column number of the column with the header of "Date" on this worksheet.
Dim SheetInitialized As Boolean 'This will be false by default (Null of Boolean is False) and set to true after first sheet activation.

Private Sub Worksheet_Activate()
    'This is called every time the sheet is activated in order to be sure we have the latest column locations.
    
    'If this sheet hasn't been initialized then we need to perform some 'first-time setup' instructions.
    If Not SheetInitialized Then
        SheetInitialized = True
        Set ThisWorkbook.SerialAssetSheet = ThisWorkbook.ActiveSheet
        'Here we specifically set the active cell to the first empty cell in column 1 (A).
        ThisWorkbook.SerialAssetSheet.Range("A" & ThisWorkbook.SerialAssetSheet.UsedRange.Rows.Count).End(xlUp).Offset(1, 0).Select
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
        'Here we check and see if the column of the TargetCell was the CustomerColumn.
        If TargetCell.Column = CustomerColumn Then Call CustomerEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the DateColumn.
        If TargetCell.Column = DateColumn Then Call DateEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the AssetColumn.
        If TargetCell.Column = AssetColumn Then Call AssetEvent(TargetCell)
        'Here we check and see if the column of the TargetCell was the SerialColumn.
        'NOTE: The SerialColumn check must be moved to the end because if the TargetCell is within the SerialColumn, and its
        'NOTE: value was deleted, then further references to TargetCell will be Null because we end up deleting the row.
        'NOTE: Refer to a Null reference, you're gonna have a bad time.
        If TargetCell.Column = SerialColumn Then Call SerialEvent(TargetCell)
        DoEvents
    Next

End Sub

Private Sub UpdateColumnIndexes()
    'When called will search for and update all tracked column indexes.
    
    'Critical column lookups that fail will be reported.
    CustomerColumn = ThisWorkbook.SheetColumnLookup("Customer", False, ThisWorkbook.SerialAssetSheet, True)
    SerialColumn = ThisWorkbook.SheetColumnLookup("Unit Serial", False, ThisWorkbook.SerialAssetSheet, False)
    AssetColumn = ThisWorkbook.SheetColumnLookup("Asset", False, ThisWorkbook.SerialAssetSheet, False)
    DateColumn = ThisWorkbook.SheetColumnLookup("Date", False, ThisWorkbook.SerialAssetSheet, True)

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
    'Then we fetch the customer name associated with the serial number.
    Call ThisWorkbook.SheetFieldLookup(SerialCell, "Customer", ThisWorkbook.MasterSheet)
    'Then we extend the formatting to maintain 60 rows of wiggle room for data entry.
    Call ThisWorkbook.ExtendFormatting(SerialCell)

End Sub

Private Sub DateEvent(ByRef DateCell As Range)
    'When called will perform all the operations that hinge upon a date cell being changed.
    
    Call ThisWorkbook.SetDate(DateCell)
    
End Sub

Private Sub AssetEvent(ByRef AssetCell As Range)
    'When called will perform all the operations that hinge upon an asset cell being changed.

    'Here we pass the updated asset to try and update the MasterSheet.
    Call ThisWorkbook.UpdateAsset(AssetCell)

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
