namespace ALWSP.ALWSP;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item;

codeunit 50001 CreateProdOrder
{
    procedure CreateProdOrder(Item: Record Item; Quantity: Integer): Code[20]
    var
        ProdOrder: Record "Production Order";
        Window: Dialog;
        ProcessingMsg: Label 'Creating Production Order for #1###############\\Status: @2@@@@@@@@@@@@@';
    begin
        if Item."Production BOM No." = '' then
            Error('Production BOM No. must be specified on the item card.');

        if Item."Routing No." = '' then
            Error('Routing No. must be specified on the item card.');

        Window.Open(ProcessingMsg);
        Window.Update(1, Item."No.");

        Window.Update(2, 'Initializing...');
        ProdOrder.Init();
        ProdOrder.Status := ProdOrder.Status::Released;
        ProdOrder.Validate("Source Type", ProdOrder."Source Type"::Item);

        Window.Update(2, 'Validating...');
        ProdOrder.Validate("Source No.", Item."No.");
        ProdOrder.Validate(Quantity, Quantity);
        ProdOrder.Validate("Due Date", WorkDate());

        Window.Update(2, 'Creating Production Order...');
        ProdOrder.Insert(true);

        RefreshProdOrder(ProdOrder, false, true, true, true, false);

        Window.Update(2, StrSubstNo('Completed - Order No. %1', ProdOrder."No."));
        Sleep(500);
        Window.Close();

        exit(ProdOrder."No."); // Return Production Order No
    end;


    local procedure RefreshProdOrder(var ProductionOrder: Record "Production Order"; Forward: Boolean; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; CreateInbRqst: Boolean)
    var
        TmpProductionOrder: Record "Production Order";
        RefreshProductionOrder: Report "Refresh Production Order";
        TempTransactionType: TransactionType;
        Direction: Option Forward,Backward;
    begin
        Commit();
        TempTransactionType := CurrentTransactionType;
        CurrentTransactionType(TRANSACTIONTYPE::Update);

        if Forward then
            Direction := Direction::Forward
        else
            Direction := Direction::Backward;
        if ProductionOrder.HasFilter then
            TmpProductionOrder.CopyFilters(ProductionOrder)
        else begin
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            TmpProductionOrder.SetRange(Status, ProductionOrder.Status);
            TmpProductionOrder.SetRange("No.", ProductionOrder."No.");
        end;
        RefreshProductionOrder.InitializeRequest(Direction, CalcLines, CalcRoutings, CalcComponents, CreateInbRqst);
        RefreshProductionOrder.SetTableView(TmpProductionOrder);
        RefreshProductionOrder.UseRequestPage := false;
        RefreshProductionOrder.RunModal();

        Commit();
        CurrentTransactionType(TempTransactionType);
    end;
}