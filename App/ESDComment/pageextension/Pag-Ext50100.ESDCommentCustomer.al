pageextension 50100 ESDCommentCustomer extends "Customer Card"
{
    layout
    {
        addlast(General)
        {
            field("Transfer Comment"; Rec."Transfer Comment")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the transfer comment is enabled for this customer.';
            }
            field("ESD Comment"; Rec."ESD Comment")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ESD comment for this customer.';
            }
        }
    }
}