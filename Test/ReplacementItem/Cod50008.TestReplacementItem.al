namespace ALWSP.ALWSP;
using Microsoft.Inventory.Item;
using Microsoft.Sales.History;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;

codeunit 50008 "Test Replacement Item"
{
    Subtype = Test;

    var
        GlobalItem: Record Item;
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        GlobalSalesShipmentHeader: Record "Sales Shipment Header";
        GlobalCustomer: Record Customer;
        GlobalAssert: Codeunit "Assert";
        GlobalLibraryInventory: Codeunit "Library - Inventory";
        GlobalLibrarySales: Codeunit "Library - Sales";
        GlobalMainItemCode: Code[20];
        GlobalReplacementItemCode: Code[20];
        GlobalValueShouldBeMatched: Label 'Value should be matched.';

    [Test]
    procedure "01_CreateItemAndSetReplacementItemAndPostInvforReplacement"()
    begin
        // [SCENARIO] Setup an item with a replacement item
        // [GIVEN] No. Series Item "M000x" insufficient with Replacement Item "R000x" more available
        Initialize();

        // [WHEN] Creating Item "M000x" with Replacement Item "R000x" and setting stock quantity
        CreateItemMainAndReplacementItemWithStock();

        // [THEN] Item "M000x" should have Replacement Item set to "R000x" and stock quantity as expected
        VerifyItemhasReplacementItemCorrectlyValued();

    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure "02_CreateSalesOrderWithReplacementItemAndPost"()
    begin
        // [SCENARIO] Create a sales order with a replacement item and post it
        Initialize();

        // [GIVEN] Item "M000x" with Replacement Item "R000x" and insufficient stock for "M000x"
        EnsureTestDataExists();

        // [GIVEN] Creating Sales Order with Item "M000x"
        CreateSalesOrderWithItemMain();

        // [WHEN] Posting Sales Order and confirming replacement
        PostingSaleOrderAndConfirmingReplacement();

        // [THEN] Checking stock levels of both items
        VerifyPostedSalesOrderWithReplacementItem();

    end;

    [Test]
    procedure "03_CheckReplacementResultAfterPosted"()
    begin
        // [SCENARIO] Check stock levels after posting sales order with replacement item
        Initialize();

        // [WHEN] Checking item exist
        CheckItemExist();

        // [THEN] Stock of "R000x" should decrease
        VerifyReplacementItemStockDecreased();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    var
        ExpectedConfirmMsgPart: Label 'Do you want to replace item %1 to %2 in this sales order?';
    begin
        Answer := true;

        if GlobalItem.Get(GlobalMainItemCode) then
            GlobalAssert.AreEqual(StrSubstNo(ExpectedConfirmMsgPart, GlobalItem."No.", GlobalItem."Replacement Item"), Question, GlobalValueShouldBeMatched);
    end;

    local procedure CheckItemExist()
    begin
        if GlobalMainItemCode = '' then
            exit;
    end;

    local procedure VerifyReplacementItemStockDecreased()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";

    begin
        if GlobalItem.Get(GlobalReplacementItemCode) then begin
            ItemLedgerEntry.SetRange("Item No.", GlobalReplacementItemCode);
            ItemLedgerEntry.CalcSums(Quantity);
            GlobalAssert.AreEqual(5, ItemLedgerEntry.Quantity, GlobalValueShouldBeMatched);
        end;
    end;

    local procedure PostingSaleOrderAndConfirmingReplacement()
    var
        ShippmentNo: Code[20];
        ReplacementItemMgt: Codeunit "ReplacementItemMgt";
    begin
        ReplacementItemMgt.ReplaceItemsInSalesOrder(GlobalSalesHeader);
        ShippmentNo := GlobalLibrarySales.PostSalesDocument(GlobalSalesHeader, true, false);
        GlobalSalesShipmentHeader.Get(ShippmentNo);
    end;

    local procedure VerifyPostedSalesOrderWithReplacementItem()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", GlobalSalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, "Sales Line Type"::Item);
        GlobalAssert.RecordCount(SalesShipmentLine, 1);
        SalesShipmentLine.FindFirst();

        if GlobalItem.Get(GlobalMainItemCode) then begin
            GlobalAssert.AreEqual(GlobalItem."Replacement Item", SalesShipmentLine."No.", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(5, SalesShipmentLine.Quantity, GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual('', SalesShipmentLine."Location Code", GlobalValueShouldBeMatched);
        end;
    end;

    local procedure CheckInsertVATPostingSetup(GetVATBus: Code[20]; GetVATProd: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        if not VATPostingSetup.Get(GetVATBus, GetVATProd) then begin
            VATPostingSetup.Init();
            VATPostingSetup.Validate("VAT Bus. Posting Group", GetVATBus);
            VATPostingSetup.Validate("VAT Prod. Posting Group", GetVATProd);
            VATPostingSetup.Insert(true);
        end;

        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify();
    end;

    local procedure CreateGenPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        if not GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);

        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Account", GLAccount."No.");
        GeneralPostingSetup.Validate("COGS Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Credit Memo Account", GLAccount."No.");
        GeneralPostingSetup.Modify();
    end;

    local procedure CreateInventoryPostingSetup(LocationCode: Code[10]; InvtPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        if not InventoryPostingSetup.Get(LocationCode, InvtPostingGroupCode) then
            LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationCode, InvtPostingGroupCode);

        LibraryERM.CreateGLAccount(GLAccount);
        InventoryPostingSetup.Validate("Cap. Overhead Variance Account", GLAccount."No.");
        InventoryPostingSetup.Validate("Capacity Variance Account", GLAccount."No.");
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Validate("Inventory Account (Interim)", GLAccount."No.");
        InventoryPostingSetup.Validate("Material Variance Account", GLAccount."No.");
        InventoryPostingSetup.Validate("Mfg. Overhead Variance Account", GLAccount."No.");
        InventoryPostingSetup.Validate("Subcontracted Variance Account", GLAccount."No.");
        InventoryPostingSetup.Validate("WIP Account", GLAccount."No.");
        InventoryPostingSetup.Modify();
    end;

    local procedure CreateItemMainAndReplacementItemWithStock()
    var
        ItemJnlLine: Record "Item Journal Line";
        MainItemPrefix: Code[10];
        ReplacementItemPrefix: Code[10];
    begin
        MainItemPrefix := 'M';
        ReplacementItemPrefix := 'R';
        GlobalItem := CreateItemWithPrefix(MainItemPrefix);
        GlobalMainItemCode := GlobalItem."No.";
        GlobalReplacementItemCode := CreateItemWithPrefix(ReplacementItemPrefix)."No.";

        GlobalItem.Validate("Replacement Item", GlobalReplacementItemCode);
        GlobalItem.Modify();
        if GlobalItem.Get(GlobalReplacementItemCode) then begin
            GlobalLibraryInventory.CreateItemJnlLine(ItemJnlLine,
                                                ItemJnlLine."Entry Type"::"Positive Adjmt.",
                                                WorkDate(),
                                                GlobalReplacementItemCode,
                                                10,
                                                '');

            CreateInventoryPostingSetup('', ItemJnlLine."Inventory Posting Group");

            GlobalLibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name",
                                                 ItemJnlLine."Journal Batch Name");
        end;
    end;

    local procedure CreateItemWithPrefix(var Prefix: Code[10]): Record Item
    var
        Item: Record Item;
        ItemNo: Code[20];
        SequenceNo: Integer;
    begin
        // Find the next sequence number for this prefix
        Item.SetFilter("No.", Prefix + '*');
        if Item.FindLast() then begin
            Evaluate(SequenceNo, CopyStr(Item."No.", StrLen(Prefix) + 1));
            SequenceNo += 1;
        end else
            SequenceNo := 1;

        // Create item number with prefix and sequence
        ItemNo := Prefix + Format(SequenceNo, 0, '<Integer,4><Filler Character,0>');

        // Create item with specific number
        GlobalLibraryInventory.CreateItem(Item);
        Item.Rename(ItemNo);  // Rename to your custom number

        exit(Item);
    end;

    local procedure CreateSalesOrderWithItemMain()
    begin
        GlobalCustomer.FindFirst();
        GlobalItem.Get(GlobalReplacementItemCode);

        CheckInsertVATPostingSetup(GlobalCustomer."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
        CreateGenPostingSetup(GlobalCustomer."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
        CreateInventoryPostingSetup('', GlobalItem."Inventory Posting Group");

        GlobalLibrarySales.CreateSalesHeader(GlobalSalesHeader, "Sales Document Type"::Order, GlobalCustomer."No.");
        GlobalLibrarySales.CreateSalesLine(GlobalSalesLine, GlobalSalesHeader, "Sales Line Type"::Item, GlobalMainItemCode, 10);

        GlobalSalesLine.Validate("Qty. to Ship", 5);
        GlobalSalesLine.Modify();
    end;

    local procedure Initialize()
    begin
        GlobalItem.Reset();
        GlobalSalesHeader.Reset();
        GlobalSalesLine.Reset();
    end;

    local procedure EnsureTestDataExists()
    begin
        // Create data only if it doesn't exist
        if GlobalMainItemCode = '' then
            CreateItemMainAndReplacementItemWithStock();

        if GlobalCustomer."No." = '' then
            GlobalCustomer.FindFirst();
    end;

    local procedure VerifyItemhasReplacementItemCorrectlyValued()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if GlobalItem.Get(GlobalMainItemCode) then
            GlobalAssert.AreEqual(GlobalReplacementItemCode, GlobalItem."Replacement Item", GlobalValueShouldBeMatched);

        if GlobalItem.Get(GlobalReplacementItemCode) then begin
            ItemLedgerEntry.SetRange("Item No.", GlobalReplacementItemCode);
            ItemLedgerEntry.CalcSums(Quantity);
            GlobalAssert.AreEqual(10, ItemLedgerEntry.Quantity, GlobalValueShouldBeMatched);
        end;
    end;
}
