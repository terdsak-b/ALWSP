pageextension 70031 "PostedReturnReceiptsPageExt" extends "Posted Return Receipts" //6662
{
    layout
    {
        addfirst(Control1)
        {
            field("Lookup Value Code"; Rec."Lookup Value Code")
            {
                ToolTip = 'Specifies the lookup value the transaction is done for.';
                ApplicationArea = All;
            }
        }
    }
}