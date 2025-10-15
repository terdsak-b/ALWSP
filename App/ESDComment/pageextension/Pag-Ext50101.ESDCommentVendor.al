pageextension 50101 ESDCommentVendor extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("Transfer Comment"; Rec."Transfer Comment")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the vendor has a transfer comment.';
            }
            field("ESD Comment"; Rec."ESD Comment")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ESD comment for the vendor.';
            }
        }
    }
}