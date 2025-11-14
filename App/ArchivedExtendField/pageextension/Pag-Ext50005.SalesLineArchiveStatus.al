namespace ALWSP.ALWSP;

using Microsoft.Sales.Archive;

pageextension 50005 SalesLineArchiveStatus extends "Sales Order Archive Subform"
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
