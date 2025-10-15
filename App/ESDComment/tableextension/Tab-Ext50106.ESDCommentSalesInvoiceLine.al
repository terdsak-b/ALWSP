tableextension 50106 ESDCommentSalesInvoiceLine extends "Sales Invoice Line"
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
