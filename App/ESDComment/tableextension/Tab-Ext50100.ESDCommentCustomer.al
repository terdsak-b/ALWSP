tableextension 50100 ESDCommentCustomer extends Customer
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
