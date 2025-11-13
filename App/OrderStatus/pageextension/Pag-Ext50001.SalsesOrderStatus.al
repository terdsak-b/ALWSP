namespace ALWSP.ALWSP;

using Microsoft.Sales.Document;

pageextension 50001 SalsesOrderStatus extends "Sales Order Subform"
{
    layout
    {
        addbefore("Location Code")
        {
            field("Status"; Rec."Order Status")
            {
                Caption = 'Status';
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Displays the status of the sales order line.';
            }
        }
    }
}
