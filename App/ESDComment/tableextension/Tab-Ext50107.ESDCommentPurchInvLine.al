tableextension 50107 "ESDCommentPurch.Inv.Line" extends "Purch. Inv. Line"
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
