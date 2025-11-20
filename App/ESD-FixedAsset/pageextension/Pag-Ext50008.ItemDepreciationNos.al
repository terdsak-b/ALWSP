namespace ALWSP.ALWSP;

using Microsoft.Sales.Setup;

pageextension 50008 ItemDepreciationNos extends "Sales & Receivables Setup"
{
    layout
    {
        addlast("Number Series")
        {
            field("ESD-Fixed Asset Item Nos."; Rec."Item Nos.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the No. Series for Item Nos.';
            }
        }
    }
}
