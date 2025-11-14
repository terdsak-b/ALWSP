namespace ALWSP.ALWSP;

using Microsoft.Purchases.Archive;

pageextension 50006 ESDComentPurchLineArchive extends "Purchase Order Archive Subform"
{
    layout
    {
        addafter(Description)
        {
            field(ESDComment; Rec."ESD Commnet")
            {
                ApplicationArea = All;
                Caption = 'ESD Comment';
                Editable = false;
            }
        }
    }
}
