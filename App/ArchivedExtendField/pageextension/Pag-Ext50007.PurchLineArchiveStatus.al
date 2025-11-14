namespace ALWSP.ALWSP;

using Microsoft.Purchases.Archive;

pageextension 50007 PurchLineArchiveStatus extends "Purchase Order Archive Subform"
{
    layout
    {
        addbefore("Location Code")
        {
            field("Order Status"; Rec."Order Status")
            {
                ApplicationArea = All;
                Caption = 'Order Status';
                Editable = false;
            }
        }
    }
}
