namespace ALWSP.ALWSP;

using Microsoft.Purchases.Document;

tableextension 50002 PurchLineStatus extends "Purchase Line"
{
    fields
    {
        field(50000; "Order Status"; Enum "Order Status")
        {
            Caption = 'Order Status';
            InitValue = Open;
        }
    }
}
