namespace ALWSP.ALWSP;

using Microsoft.Inventory.Item;
using Microsoft.TestLibraries.Foundation.NoSeries;
using Microsoft.Assembly.Document;

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
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Creates a new assembly order for the selected item.';

                trigger OnAction()
                var
                    //AssemblyOrderMgt: Codeunit "Assembly Order Management";
                    Item: Record Item;
                    AssemblyOrder: Record "Assembly Header";
                    SelectionCount: Integer;
                    ConfirmMsg: Text;
                    QuestionMsg: Text;
                    CreateAssemblyOrder: Codeunit "CreateAssemblyOrder";
                begin
                    CurrPage.SetSelectionFilter(Item);
                    SelectionCount := Item.Count();


                    ConfirmMsg := StrSubstNo('You are about to create assembly orders for %1 item(s). Do you want to continue?', SelectionCount);
                    if not Confirm(ConfirmMsg) then begin
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
                            //Call Create Assembly Order function from Assembly Order Management codeunit
                            GlobalNo := CreateAssemblyOrder.CreateAssemblyOrder(Item."No.", GlobalQtyDict.Get(Item."No."));
                            BuildMessageNo();
                        until Item.Next() = 0;
                    QuestionMsg := GlobalNoMessage + GlobalNavQstMsg;
                    if Confirm(QuestionMsg) then begin
                        CurrPage.Close();
                        AssemblyOrder.FindLast();
                        Page.Run(Page::"Assembly Orders", AssemblyOrder); // Open the last created assembly order
                    end else begin
                        CurrPage.Close();
                        Page.Run(Page::"Assembly Order Items"); // Refresh the assembly order item page for set Global variables to default
                    end;
                end;
            }
        }
    }
    var
        GlobalQtyDict: Dictionary of [Code[20], Decimal];
        GlobalQty: Decimal;
        GlobalNo: Code[20];
        GlobalFirstItemNo: Code[20];
        GlobalLastItemNo: Code[20];
        GlobalProcessedCount: Integer;
        GlobalNoMessage: Text;
        GlobalNavQstMsg: Label '\Do you want to view the created assembly orders?';


    trigger OnOpenPage();
    begin
        Rec.Init();
        Rec.SetRange("Assembly BOM", true);

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
                GlobalNoMessage := StrSubstNo('Created assembly order: %1', GlobalFirstItemNo);
            else
                GlobalNoMessage := StrSubstNo('Created %1 assembly orders: %2...%3',
                    GlobalProcessedCount,
                    GlobalFirstItemNo,
                    GlobalLastItemNo);
        end;
    end;
}
