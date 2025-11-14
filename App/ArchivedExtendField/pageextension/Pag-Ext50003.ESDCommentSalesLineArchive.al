namespace ALWSP.ALWSP;

using Microsoft.Sales.Archive;

pageextension 50003 ESDCommentSalesLineArchive extends "Sales Order Archive Subform"
{
    layout
    {
        addafter(Description)
        {
            field(ESDComment; Rec."ESD Comment")
            {
                ApplicationArea = All;
                Caption = 'ESD Comment';
                Editable = false;
            }
        }
    }
}
