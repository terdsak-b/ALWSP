table 50002 ItemDepreciationLine
{
    Caption = 'ItemDepreciationLine';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = "Item Depreciation"."Item No.";
        }
        field(2; "Source Type"; Enum "Depreciation Item Type")
        {
            Caption = 'Description';
            TableRelation = "Item Depreciation"."Item Type";
        }
        field(3; "No. of Year"; Integer)
        {
            Caption = 'No. of Year';
        }
        field(4; "Depreciation Amount"; Decimal)
        {
            Caption = 'Depreciation Amount';
        }
        field(5; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(6; Jan; Decimal)
        {
            Caption = 'Jan';
        }
        field(7; Feb; Decimal)
        {
            Caption = 'Feb';
        }
        field(8; Mar; Decimal)
        {
            Caption = 'Mar';
        }
        field(9; Apr; Decimal)
        {
            Caption = 'Apr';
        }
        field(10; May; Decimal)
        {
            Caption = 'May';
        }
        field(11; Jun; Decimal)
        {
            Caption = 'Jun';
        }
        field(12; Jul; Decimal)
        {
            Caption = 'Jul';
        }
        field(13; Aug; Decimal)
        {
            Caption = 'Aug';
        }
        field(14; Sep; Decimal)
        {
            Caption = 'Sep';
        }
        field(15; Oct; Decimal)
        {
            Caption = 'Oct';
        }
        field(16; Nov; Decimal)
        {
            Caption = 'Nov';
        }
        field(17; Dec; Decimal)
        {
            Caption = 'Dec';
        }
    }
    keys
    {
        key(PK; "Source No.", "Source Type", "No. of Year")
        {
            Clustered = true;
        }
    }
}

