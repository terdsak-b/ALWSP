pageextension 50103 ESDCmtPurchaseOrderSubform extends "Purchase Order Subform"
{
    layout
    {
        addafter(Description)
        {
            field("ESD Comment"; Rec."ESD Comment")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Enter any comments related to the ESD (Enterprise Solutions & Development) for this purchase order.';
            }
        }
    }
}
