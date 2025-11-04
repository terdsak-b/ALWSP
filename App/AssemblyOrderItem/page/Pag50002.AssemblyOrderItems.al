namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;

page 50002 "Assembly Order Items"
{
    ApplicationArea = All;
    Caption = 'Assembly Order Item';
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
                field("Assembly BOM"; Rec."Assembly BOM")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Assembly Quantity"; GlobalQty)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity to be produced for the item (Default 1).';

                    trigger OnValidate()
                    begin
                        if GlobalQty <= 0 then
                            Error('Production Quantity cannot be less than 0.');
                        GlobalQtyDict.Set(Rec."No.", GlobalQty);
                    end;

                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CreateAssemblyOrder)
            {
                ApplicationArea = All;
                Caption = 'Create Assembly Order';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Creates a new assembly order for the selected item.';

                trigger OnAction()
                var
                    //AssemblyOrderMgt: Codeunit "Assembly Order Management";
                    Item: Record Item;

                begin
                    CurrPage.SetSelectionFilter(Item);
                    if GlobalAssemblyOrderCodeunit.CreateAsmblyOrderOnAction(Item, GlobalQty, GlobalQtyDict) then
                        CurrPage.Close()
                    else
                        GlobalQty := 1.00;
                end;
            }
            action(CreateAll) //for test asm multiple msg
            {
                ApplicationArea = All;
                Caption = 'Create Assembly Orders for All Items';
                Image = NewDocument;
                Promoted = false;
                ToolTip = 'Creates new assembly orders for all assembly items.';

                trigger OnAction()
                begin
                    if GlobalAssemblyOrderCodeunit.CreateAsmblyOrderOnAction(Rec, GlobalQty, GlobalQtyDict) then
                        CurrPage.Close()
                    else
                        GlobalQty := 1.00;
                end;
            }
        }
    }

    trigger OnOpenPage();
    var
        ErrorMsg: Label 'No Assembly Items found in the database.';
    begin
        Rec.Init();
        Rec.SetRange("Assembly BOM", true);

        if Rec.FindSet() then begin
            repeat
                //Set Production Quantity default to 1 when open page
                if not GlobalQtyDict.ContainsKey(Rec."No.") then begin
                    if GlobalQty <> 1 then
                        GlobalQty := 1.00;
                    GlobalQtyDict.Add(Rec."No.", GlobalQty);
                end;
            until Rec.Next() = 0;
        end else begin
            Error(ErrorMsg);
        end;
    end;

    var
        GlobalAssemblyOrderCodeunit: Codeunit "AssemblyOrderCodeunit";
        GlobalQtyDict: Dictionary of [Code[20], Decimal];
        GlobalQty: Decimal;
}
