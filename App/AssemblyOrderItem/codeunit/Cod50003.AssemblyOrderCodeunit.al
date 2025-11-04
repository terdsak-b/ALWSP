namespace ALWSP.ALWSP;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using System.Utilities;
codeunit 50003 AssemblyOrderCodeunit
{

    procedure BuildConfirmMessageWithAsmOrderNo(AsmNoList: List of [Code[20]]; Counter: Integer): Text
    var
        FirstNo: Code[20];
        LastNo: Code[20];
        MsgNo: Text;
        CreatedMsg: Label 'Created assembly order: %1';
        CreatedMultipleMsg: Label 'Created %1 assembly orders: %2...%3';
        PartConfirmQstMsg: Label '\Do you want to view the created assembly orders?';
    begin
        if Counter = 1 then begin
            FirstNo := AsmNoList.Get(1);
            MsgNo := StrSubstNo(CreatedMsg, FirstNo);
        end else begin
            FirstNo := AsmNoList.Get(1);
            LastNo := AsmNoList.Get(Counter);
            MsgNo := StrSubstNo(CreatedMultipleMsg, Counter, FirstNo, LastNo);
        end;
        exit(MsgNo + PartConfirmQstMsg);
    end;

    procedure CreateAsmblyOrderOnAction(var Item: Record Item; Quantity: Decimal; ItemQtyDict: Dictionary of [Code[20], Decimal]): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        ConfirmManagement: Codeunit "Confirm Management";
        AsmNo: Code[20];
        AsmNoList: List of [Code[20]];
        ConfirmMsg: Text;
        QuestionMsg: Text;
        ConfirmQstMsg: Label 'You are about to create assembly orders for %1 item(s). Do you want to continue?';
    begin
        ConfirmMsg := StrSubstNo(ConfirmQstMsg, Item.Count());
        if not ConfirmManagement.GetResponseOrDefault(ConfirmMsg, false) then
            exit(false);

        if Item.FindSet() then
            repeat
                //Call Create Assembly Order function from Assembly Order Management codeunit
                AsmNo := CreateAssemblyOrder(Item."No.",
                                            Item."Location Filter",
                                            Item."Variant Filter",
                                            ItemQtyDict.Get(Item."No."));
                AsmNoList.Add(AsmNo);
            until Item.Next() = 0;

        QuestionMsg := BuildConfirmMessageWithAsmOrderNo(AsmNoList, Item.Count());
        if ConfirmManagement.GetResponseOrDefault(QuestionMsg, false) then begin
            AssemblyHeader.FindLast();
            Page.Run(Page::"Assembly Orders", AssemblyHeader); // Open the last created assembly order
            exit(true);
        end else
            exit(false);
    end;

    procedure CreateAssemblyOrder(ParentItem: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]; Quantity: Decimal): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        Window: Dialog;
        Completed: Label 'Completed - Order No. %1';
        Creating: Label 'Creating Assembly Order...';
        Initializing: Label 'Initializing...';
        ProcessingMsg: Label 'Creating Assembly Order for #1###############\\Status: @2@@@@@@@@@@@@@';
        Validating: Label 'Validating...';
    begin
        Window.Open(ProcessingMsg);
        Window.Update(1, ParentItem);

        Window.Update(2, Initializing);
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader.Insert(true);

        Window.Update(2, Validating);
        AssemblyHeader.Validate("Item No.", ParentItem);
        AssemblyHeader.Validate("Location Code", LocationCode);
        AssemblyHeader.Validate("Due Date", WorkDate() + 1);
        AssemblyHeader.Validate(Quantity, Quantity);
        if VariantCode <> '' then
            AssemblyHeader.Validate("Variant Code", VariantCode);

        Window.Update(2, Creating);
        AssemblyHeader.Modify(true);

        Window.Update(2, StrSubstNo(Completed, AssemblyHeader."No."));
        Window.Close();

        exit(AssemblyHeader."No."); // Return Assembly Order No
    end;
}