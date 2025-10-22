namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;

page 50001 "Manufacturing Item"
{
    ApplicationArea = All;
    Caption = 'Manufacturing Item';
    PageType = List;
    SourceTable = Item;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Product Quantity"; Rec."Production Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity to be produced for the item (Default 1).';
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Manufacturing Policy"; Rec."Manufacturing Policy")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateProductionOrder)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create All of Production Order';
                Image = Production;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Creates a new production order for the selected item.';

                trigger OnAction()
                var
                    CreateProdOrder: Codeunit "CalcProdOrder";
                    ConfirmMsg: Label 'Do you want to create production orders for all listed items?';
                begin
                    if not Confirm(ConfirmMsg) then
                        exit;
                    if Rec.FindSet() then
                        repeat
                            CreateProdOrder.CreateProdOrder(Rec, Rec."Production Quantity");
                        until Rec.Next() = 0;
                    Message('Created production orders successfully.');
                end;
            }

            action(CreateSelectProductionOrder)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create Selected Production Orders';
                Image = Production;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Creates production orders for the selected items.';

                trigger OnAction()
                var
                    CreateProdOrder: Codeunit "CalcProdOrder";
                    Item: Record Item;
                    SelectionCount: Integer;
                    ConfirmMsg: Text;
                begin
                    CurrPage.SetSelectionFilter(Item);
                    SelectionCount := Item.Count;

                    if SelectionCount = 0 then
                        Error('Please select one or more items.');

                    ConfirmMsg := StrSubstNo('Do you want to create production orders for %1 selected items?', SelectionCount);
                    if not Confirm(ConfirmMsg) then
                        exit;

                    if Item.FindSet() then
                        repeat
                            CreateProdOrder.CreateProdOrder(Item, Item."Production Quantity");
                        until Item.Next() = 0;

                    Message('Successfully created %1 production orders.', SelectionCount);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        //Filter data
        Rec.SetRange(Type, Rec.Type::Inventory);
        Rec.SetRange("Replenishment System", Rec."Replenishment System"::"Prod. Order");
        Rec.SetRange("Manufacturing Policy", Rec."Manufacturing Policy"::"Make-to-Order");
        Rec.SetFilter("Routing No.", '<>%1', '');
        Rec.SetFilter("Production BOM No.", '<>%1', '');
        Rec.SetRange("Reordering Policy", Rec."Reordering Policy"::Order);

        if Rec.FindSet() then
            repeat
                //Set Production Quantity default to 1 when open page
                if Rec."Production Quantity" <> 1 then begin
                    Rec."Production Quantity" := 1;
                end;
                Rec.Modify();
            until Rec.Next() = 0;
    end;
}
