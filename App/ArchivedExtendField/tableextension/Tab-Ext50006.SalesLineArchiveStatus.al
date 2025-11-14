namespace ALWSP.ALWSP;

using Microsoft.Sales.Archive;

tableextension 50006 SalesLineArchiveStatus extends "Sales Line Archive"
{
    fields
    {
        field(50000; "Order status"; Enum "Order Status")
        {
            Caption = 'Order status';
            DataClassification = ToBeClassified;
        }
    }
}
