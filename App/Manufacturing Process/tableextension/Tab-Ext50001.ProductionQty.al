namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;

tableextension 50001 "Production Qty" extends Item
{
    fields
    {
        field(50000; "Production Quantity"; Integer)
        {
            Caption = 'Production Quantity';
            DataClassification = ToBeClassified;
            InitValue = 1;

            trigger OnValidate()
            begin
                if Rec."Production Quantity" < 0 then
                    Error('Production Quantity cannot be less than 0.');
            end;
        }
    }
}
