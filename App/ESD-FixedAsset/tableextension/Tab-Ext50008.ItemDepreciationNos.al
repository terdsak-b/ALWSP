namespace ALWSP.ALWSP;

using Microsoft.Sales.Setup;
using Microsoft.Foundation.NoSeries;

tableextension 50008 ItemDepreciationNos extends "Sales & Receivables Setup"
{
    fields
    {
        field(50000; "Item Nos."; Code[20])
        {
            Caption = 'ESD-Fixed Asset Item Nos.';
            TableRelation = "No. Series";
        }
    }
}
