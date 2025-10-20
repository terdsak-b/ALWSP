namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;

page 50001 "Manufacturing Item"
{
    ApplicationArea = All;
    Caption = 'Manufacturing Item';
    PageType = List;
    SourceTable = Item;
    
    layout
    {
        area(Content)
        {
            repeater(General)
            {
            }
        }
    }
}
