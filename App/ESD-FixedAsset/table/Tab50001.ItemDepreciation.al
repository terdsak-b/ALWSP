table 50001 "Item Depreciation"
{
    Caption = 'Item Depreciation';
    DataClassification = ToBeClassified;
    DataCaptionFields = "Item No.", "Item Name";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    SalesSetup.Get();
                    NoSeries.TestManual(SalesSetup."Item Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Item Type"; Enum "Depreciation Item Type")
        {
            Caption = 'Item Type';
        }
        field(3; "Item Name"; Text[100])
        {
            Caption = 'Item Name';
        }
        field(4; "Purchase Date"; Date)
        {
            Caption = 'Purchase Date';
        }
        field(5; "Total Price"; Decimal)
        {
            Caption = 'Total Price';
        }
        field(6; "Carcass value"; Decimal)
        {
            Caption = 'Carcass value';
        }
        field(7; "Year of Depreciation"; Integer)
        {
            Caption = 'Year of Depreciation';
        }
        field(8; "Last Depreciation Date"; Date)
        {
            Caption = 'Last Depreciation Date';
        }
        field(9; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }

    }
    keys
    {
        key(PK; "Item No.") { }
    }

    trigger OnInsert()
    begin
        if "Item No." = '' then begin
            SalesSetup.Get();
            SalesSetup.TestField("Item Nos.");
            "No. Series" := SalesSetup."Item Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "Item No." := NoSeries.GetNextNo("No. Series");
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);
            Rec.SetLoadFields("Item No.");
            while Rec.Get("Item No.") do
                "Item No." := NoSeries.GetNextNo("No. Series");
        end;

        Rec."Purchase Date" := WorkDate();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
}
