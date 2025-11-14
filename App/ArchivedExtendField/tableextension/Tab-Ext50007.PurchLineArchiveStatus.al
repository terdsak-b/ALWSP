namespace ALWSP.ALWSP;

using Microsoft.Purchases.Archive;

tableextension 50007 PurchLineArchiveStatus extends "Purchase Line Archive"
{
    fields
    {
        field(50000; "Order Status"; Enum "Order Status")
        {
            Caption = 'Order Status';
            DataClassification = ToBeClassified;
        }
    }
}
