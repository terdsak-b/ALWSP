namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;

tableextension 50000 ReplacementItem extends Item
{
    fields
    {
        field(50000; "Replacement Item"; Code[20])
        {
            Caption = 'Replacement Item';
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
    }
}
