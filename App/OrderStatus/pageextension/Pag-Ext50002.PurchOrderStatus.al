namespace ALWSP.ALWSP;

using Microsoft.Purchases.Document;

pageextension 50002 PurchOrderStatus extends "Purchase Order Subform"
{
    layout
    {
        addbefore("Location Code")
        {
            field(Status; Rec.Status)
            {
                Caption = 'Status';
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Displays the status of the purchase order line.';
            }
        }
    }
}
