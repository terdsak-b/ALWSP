table 50000 "Batch Comment Update Buffer"
{
    Caption = 'Batch Comment Update Buffer';
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Entity Type"; Enum "Comment Entity Type")
        {
            Caption = 'Entity Type';
        }
        field(3; "Entity No."; Code[20])
        {
            Caption = 'Entity No.';
        }
        field(4; "Entity Name"; Text[100])
        {
            Caption = 'Entity Name';
        }
        field(5; "Old Comment"; Text[100])
        {
            Caption = 'Old Comment';
        }
        field(6; "New Comment"; Text[100])
        {
            Caption = 'New Comment';
        }
        field(7; "Transfer Comment"; Boolean)
        {
            Caption = 'Transfer Comment';
        }
        field(8; "Modified"; Boolean)
        {
            Caption = 'Modified';
        }
        field(9; "Status Indicator"; Text[10])
        {
            Caption = 'Status';
            Editable = false;

            trigger OnValidate()
            begin
                CalcFields();
            end;
        }
    }
    keys
    {
        key(PK; "Entry No.", "Entity Type", "Entity No.")
        {
            Clustered = true;
        }
    }

    procedure CalcFields()
    begin
        if Rec.Modified then
            Rec."Status Indicator" := '● Modified'
        else
            Rec."Status Indicator" := '';
    end;
}
