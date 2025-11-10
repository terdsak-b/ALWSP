namespace ALWSP.ALWSP;

using Microsoft.Sales.Document;

tableextension 50001 SalesLineStatus extends "Sales Line"
{
    fields
    {
        field(50000; Status; Enum "Order Status")
        {
            Caption = 'Status';
            InitValue = Open;
        }
    }
}
