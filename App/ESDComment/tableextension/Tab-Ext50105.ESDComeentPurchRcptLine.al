tableextension 50105 "ESDComeentPurch.Rcpt.Line" extends "Purch. Rcpt. Line"
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
