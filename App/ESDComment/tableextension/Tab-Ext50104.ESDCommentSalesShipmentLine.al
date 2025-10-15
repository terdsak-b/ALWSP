tableextension 50104 ESDCommentSalesShipmentLine extends "Sales Shipment Line"
{
    fields
    {
        field(50100; "ESD Comment"; Text[100])
        {
            Caption = 'ESD Comment';
            DataClassification = ToBeClassified;
        }
    }
}
