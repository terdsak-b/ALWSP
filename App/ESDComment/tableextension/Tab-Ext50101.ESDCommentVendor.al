tableextension 50101 ESDCommentVendor extends Vendor
{
    fields
    {
        field(50100; "Transfer Comment"; Boolean)
        {
            Caption = 'Transfer Comment';
            DataClassification = ToBeClassified;
        }
        field(50101; "ESD Comment"; Text[100])
        {
            Caption = 'ESD Comment';
            DataClassification = ToBeClassified;
        }
    }
}
