namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

page 50001 "Manufacturing Items"
{
    ApplicationArea = All;
    Caption = 'Manufacturing Item';
    PageType = List;
    SourceTable = Item;
    UsageCategory = Lists;
    SaveValues = true;

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
                field("Production Quantity"; GlobalQty)
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
            action(CreateAllProductionOrder)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create All of Production Order';
                Image = Production;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Creates a new production order for the selected item.';

                trigger OnAction()
                begin
                    GlobalConfirmMsg := 'Do you want to create production orders for all listed items?';
                    if not Confirm(GlobalConfirmMsg) then begin
                        //Reset GlobalQtyDict values to 1 for all items
                        if Rec.FindSet() then
                            repeat
                                GlobalQty := 1.00;
                                GlobalQtyDict.Set(Rec."No.", GlobalQty);
                            until Rec.Next() = 0;
                        exit;
                    end;
                    if Rec.FindSet() then
                        repeat
                            GlobalNo := GlobalCreateProdOrder.CreateProdOrder(Rec, GlobalQtyDict.Get(Rec."No."));

                            // While processing items
                            BuildMessageNo();
                        until Rec.Next() = 0;

                    GlobalQuestionMsg := GlobalNoMessage + GlobalNavQstMsg;
                    if Confirm(GlobalQuestionMsg) then begin
                        CurrPage.Close();
                        GlobalProdOrder.FindLast();
                        Page.RunModal(Page::"Production Order List", GlobalProdOrder);
                    end else begin
                        CurrPage.Close();
                        Page.Run(Page::"Manufacturing Items"); // Refresh the manufacturing item page for set Global variables to default
                    end;
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
                    Item: Record Item;
                    SelectionCount: Integer;

                begin
                    CurrPage.SetSelectionFilter(Item);
                    SelectionCount := Item.Count;

                    if SelectionCount = 0 then
                        Error('Please select one or more items.');

                    GlobalConfirmMsg := StrSubstNo('Do you want to create production orders for %1 selected items?', SelectionCount);
                    if not Confirm(GlobalConfirmMsg) then begin
                        //Reset GlobalQtyDict values to 1 for selected items
                        if Item.FindSet() then
                            repeat
                                GlobalQty := 1.00;
                                GlobalQtyDict.Set(Item."No.", GlobalQty);
                            until Item.Next() = 0;
                        exit;
                    end;
                    if Item.FindSet() then
                        repeat
                            GlobalNo := GlobalCreateProdOrder.CreateProdOrder(Item, GlobalQtyDict.Get(Item."No."));
                            // While processing items
                            BuildMessageNo();
                        until Item.Next() = 0;

                    GlobalQuestionMsg := GlobalNoMessage + GlobalNavQstMsg;

                    if Confirm(GlobalQuestionMsg) then begin
                        CurrPage.Close();
                        GlobalProdOrder.FindLast();
                        Page.RunModal(Page::"Production Order List", GlobalProdOrder);
                    end else begin
                        CurrPage.Close();
                        Page.Run(Page::"Manufacturing Items"); // Refresh the manufacturing item page for set Global variables to default
                    end;
                end;
            }
        }
    }
    var
        GlobalCreateProdOrder: Codeunit CreateProdOrder;
        GlobalProdOrder: Record "Production Order";
        GlobalQty: Decimal;
        GlobalQtyDict: Dictionary of [Code[20], Decimal];
        GlobalNo: Code[20];
        GlobalConfirmMsg: Text;
        GlobalFirstItemNo: Code[20];
        GlobalLastItemNo: Code[20];
        GlobalProcessedCount: Integer;
        GlobalNoMessage: Text;
        GlobalQuestionMsg: Text;
        GlobalNavQstMsg: Label '\Do you want to view the created production orders?';

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
                if not GlobalQtyDict.ContainsKey(Rec."No.") then begin
                    if GlobalQty <> 1 then
                        GlobalQty := 1.00;
                    GlobalQtyDict.Add(Rec."No.", GlobalQty);
                end;
            until Rec.Next() = 0;
    end;

    local procedure BuildMessageNo()
    begin
        // While processing items
        case GlobalProcessedCount of
            0:  // First item
                GlobalFirstItemNo := GlobalNo;
        end;
        GlobalLastItemNo := GlobalNo;
        GlobalProcessedCount += 1;
        case GlobalProcessedCount of
            1:
                GlobalNoMessage := StrSubstNo('Created production order: %1', GlobalFirstItemNo);
            else
                GlobalNoMessage := StrSubstNo('Created %1 production orders: %2...%3',
                    GlobalProcessedCount,
                    GlobalFirstItemNo,
                    GlobalLastItemNo);
        end;
    end;
}