namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;

pageextension 50000 "Replacement Item" extends "Item Card"
{
    layout
    {
        addlast(Planning)
        {
            field("Replacement Item"; Rec."Replacement Item")
            {
                ApplicationArea = Planning;
                Caption = 'Replacement Item';
                ToolTip = 'Specifies the replacement item for this item.';
            }
        }
    }
}
