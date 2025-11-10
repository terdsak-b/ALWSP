namespace ALWSP.ALWSP;

using Microsoft.Purchases.Document;

tableextension 50002 PurchLineStatus extends "Purchase Line"
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
