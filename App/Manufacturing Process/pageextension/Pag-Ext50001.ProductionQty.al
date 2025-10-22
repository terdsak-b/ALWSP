namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;

pageextension 50001 ProductionQty extends "Item Card"
{
    layout
    {
        addlast(Replenishment_Production)
        {
            field("Production Quantity"; Rec."Production Quantity")
            {
                ApplicationArea = All;
            }
        }
    }
}
