pageextension 50105 "Inventory by Location" extends "Planning Worksheet"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part("Inventory by Location"; "Inventory by Location")
            {
                ApplicationArea = All;
                SubPageLink = "Item No." = field("No."), "Location Code" = field("Location Code");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage."Inventory by Location".Page.UpdateInventoryQuantity(Rec."No.", Rec."Location Code");
    end;
}
