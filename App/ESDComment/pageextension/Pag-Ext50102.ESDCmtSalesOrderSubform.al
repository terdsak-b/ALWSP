pageextension 50102 ESDCmtSalesOrderSubform extends "Sales Order Subform"
{
    layout
    {
        addafter(Description)
        {
            field("ESD Comment"; Rec."ESD Comment")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Enter any comments related to the ESD (Enterprise Solutions & Developmet) for this sales order.';
            }
        }
    }
}
