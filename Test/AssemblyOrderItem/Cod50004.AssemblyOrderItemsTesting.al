namespace ALWSP.ALWSP;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Journal;
using Microsoft.Assembly.History;

codeunit 50004 "Assembly Order Items Testing"
{
    Subtype = Test;

    var
        GlobalItem: Record Item temporary;
        GlobalLocation: Record Location;
        GlobalAssemblyHeader: Record "Assembly Header";
        GlobalAssert: Codeunit "Assert";
        GlobalChildQty: Decimal;
        GlobalNegativeQty: Decimal;
        GlobalParentQty: Decimal;
        GlobalExpectedMsg: Text;
        GlobalValueShouldBeMatched: Label 'Value should be matched.';

    [Test]
    procedure "01_SetupDataforAsmOrder"()
    begin
        // [SCENARIO] Create Setup Data for Assembly Order
        Initialize();

        // [WHEN] Set up test data and set up component items quantity
        CreateSetupDataForPostAssemvblyOrder();

        // [THEN] Verify component items quantity is set up correctly
        CheckResultAfterCreateSetupDataForPostAssemvblyOrder();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AssemblyOrdersHandler')]
    procedure "02_Create_AssemblyOrder"()
    begin
        // [SCENARIO] Create Assembly Order
        Initialize();

        // [GIVEN] Create Setup Data for Assembly Order
        CreateSetupDataForPostAssemvblyOrder();

        // [WHEN] Insert quantity to create Assembly Order for first selected item
        CreateAsmOrderItems();

        // [THEN] Verify Assembly Order is created with correct details
        VerifyAsmOrder();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AssemblyOrdersHandler')]
    procedure "03_Post_AssemblyOrder"()
    begin
        // [SCENARIO] Post Assembly Order
        Initialize();

        // [GIVEN] Create Setup Data for Assembly Order
        CreateSetupDataForPostAssemvblyOrder();

        // [WHEN] Create and Post Assembly Order for first selected item
        PostAssemblyOrder();

        // [THEN] Verify Assembly Order is posted with correct details and confirm item ledger entries
        VerifyPostedAssemblyOrderViaItemLedgerEntries();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    var
        OneAsmOrderMsg: Label 'Created assembly order: %1\Do you want to view the created assembly orders?';
    begin
        Answer := true;

        if not Question.Contains(':') then
            exit; // First confirm handler check

        if GlobalExpectedMsg = '' then
            exit;

        GlobalAssert.AreEqual(GlobalExpectedMsg, Question, GlobalValueShouldBeMatched);
    end;

    [PageHandler]
    procedure AssemblyOrdersHandler(var AssemblyOrders: Page "Assembly Orders")
    begin
        // Handle the Assembly Orders page
    end;

    local procedure CreateAsmOrderItems()
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeries: Codeunit "No. Series";
        ExpectedAsmOrderNo: Text;
        CreateAsmOrderMsg: Label 'Created assembly order: %1\Do you want to view the created assembly orders?';
        AssemblyOrderItems: TestPage "Assembly Order Items";
    begin
        if GlobalItem.FindFirst() then begin
            //NegativeQtyInsert(GlobalItem."No."); // Verify negative quantity error handling
            AssemblyOrderItems.OpenEdit();
            AssemblyOrderItems.GoToRecord(GlobalItem);
            AssemblyOrderItems."Assembly Quantity".SetValue(GlobalParentQty);

            AssemblySetup.Get();
            ExpectedAsmOrderNo := IncStr(NoSeries.PeekNextNo(AssemblySetup."Assembly Order Nos."), 0);
            GlobalExpectedMsg := StrSubstNo(CreateAsmOrderMsg, ExpectedAsmOrderNo);

            AssemblyOrderItems.CreateAssemblyOrder.Invoke();
        end;
    end;

    local procedure CreateAsmOrderAll_Items() // Unused for check Axxxxx...Axxxxx
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeries: Codeunit "No. Series";
        ExpectedAsmOrderFirstNo: Text;
        ExpectedAsmOrderLastNo: Text;
        CreateMultipleAsmOrderMsg: Label 'Created %1 assembly orders: %2...%3\Do you want to view the created assembly orders?';
        AssemblyOrderItems: TestPage "Assembly Order Items";
    begin
        AssemblyOrderItems.OpenEdit();
        if GlobalItem.FindSet() then
            repeat
                NegativeQtyInsert(GlobalItem."No."); // Verify negative quantity error handling
                AssemblyOrderItems.GoToKey(GlobalItem."No.");
                AssemblyOrderItems."Assembly Quantity".SetValue(GlobalParentQty);
            until GlobalItem.Next() = 0;

        AssemblySetup.Get();
        ExpectedAsmOrderFirstNo := IncStr(NoSeries.PeekNextNo(AssemblySetup."Assembly Order Nos."), 0);
        ExpectedAsmOrderLastNo := IncStr(ExpectedAsmOrderFirstNo, GlobalItem.Count() - 1);
        GlobalExpectedMsg := StrSubstNo(CreateMultipleAsmOrderMsg, GlobalItem.Count(), ExpectedAsmOrderFirstNo, ExpectedAsmOrderLastNo);
        AssemblyOrderItems.CreateAll.Invoke();
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

    local procedure Initialize()
    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        Clear(GlobalExpectedMsg);
        Clear(GlobalLocation);
        Clear(GlobalNegativeQty);
        Clear(GlobalParentQty);
        Clear(GlobalChildQty);

        GlobalParentQty := LibraryRandom.RandDecInRange(1, 5, 0);
        GlobalChildQty := LibraryRandom.RandDecInRange(90, 100, 0);
        GlobalNegativeQty := LibraryRandom.RandDecInRange(-10, -1, 0);
    end;

    local procedure NegativeQtyInsert(ItemNo: Code[20])
    var
        ErrorMsg: Label 'Production Quantity cannot be less than 0.';
        AssemblyOrderItems: TestPage "Assembly Order Items";
    begin
        AssemblyOrderItems.OpenEdit();
        AssemblyOrderItems.GoToKey(ItemNo);

        Commit();

        asserterror AssemblyOrderItems."Assembly Quantity".SetValue(GlobalNegativeQty);
        AssemblyOrderItems.Close();

        GlobalAssert.ExpectedError(ErrorMsg);
    end;

    local procedure PostAssemblyOrder()
    var

        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        CreateAsmOrderItems();
        if GlobalItem.FindFirst() then begin
            GlobalAssemblyHeader.SetRange("Document Type", GlobalAssemblyHeader."Document Type"::Order);
            GlobalAssemblyHeader.SetRange("Item No.", GlobalItem."No.");
            GlobalAssemblyHeader.FindLast();
            // Posting Setup Assembly order
            CreateInventoryPostingSetup(GlobalLocation.Code, GlobalItem."Inventory Posting Group");

            // Post Assembly order
            LibraryAssembly.PostAssemblyHeader(GlobalAssemblyHeader, '');
        end;
    end;

    local procedure CreateSetupDataForPostAssemvblyOrder()
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ErrorMsg: Label 'No Assembly Items found in the database.';
    begin
        Item.Init();
        Item.SetRange("Assembly BOM", true);
        Location.Init();
        LibraryWarehouse.CreateLocation(GlobalLocation);

        GlobalItem.DeleteAll();
        GlobalItem.Reset();

        if Item.FindSet() then begin
            repeat
                GlobalItem := Item;
                GlobalItem.Insert();

                BOMComponent.SetRange("Parent Item No.", Item."No.");
                if BOMComponent.FindSet() then
                    repeat
                        if BOMComponent.Type = BOMComponent.Type::Item then begin
                            // Create Item Assembly component for parent item
                            LibraryInventory.CreateItemJnlLine(ItemJournalLine,
                                                                   ItemJournalLine."Entry Type"::"Positive Adjmt.",
                                                                   WorkDate(),
                                                                   BOMComponent."No.",
                                                                   GlobalChildQty,
                                                                   GlobalLocation.Code);
                            // Posting setup inventory posting setup
                            CreateInventoryPostingSetup(GlobalLocation.Code, ItemJournalLine."Inventory Posting Group");

                            // Post item journal line
                            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name",
                                                                 ItemJournalLine."Journal Batch Name");
                        end;
                    until BOMComponent.Next() = 0;
            until Item.Next() = 0;
        end else begin
            asserterror;
            GlobalAssert.ExpectedError(ErrorMsg);
        end;
    end;

    local procedure VerifyAsmOrder()
    var
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
    begin
        if GlobalItem.FindFirst() then begin
            GlobalAssemblyHeader.SetRange("Document Type", GlobalAssemblyHeader."Document Type"::Order);
            GlobalAssemblyHeader.SetRange("Item No.", GlobalItem."No.");
            GlobalAssemblyHeader.FindLast();

            GlobalAssert.AreEqual(GlobalItem."No.", GlobalAssemblyHeader."Item No.", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalParentQty, GlobalAssemblyHeader.Quantity, GlobalValueShouldBeMatched);
        end;

        VerifyAsmOrderLineComponents();
    end;

    local procedure VerifyAsmOrderLineComponents()
    var
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        ExpectedQty: Decimal;
    begin
        if GlobalItem.FindFirst() then begin
            GlobalAssemblyHeader.FindLast();
            GlobalAssemblyHeader.Validate("Location Code", GlobalLocation.Code);
            GlobalAssemblyHeader.Modify();
            AssemblyLine.SetRange("Document Type", GlobalAssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", GlobalAssemblyHeader."No.");
            BOMComponent.SetRange("Parent Item No.", GlobalAssemblyHeader."Item No.");

            if BOMComponent.FindSet() then
                if AssemblyLine.FindSet() then
                    repeat
                        ExpectedQty := AssemblyLine."Quantity per" * GlobalAssemblyHeader.Quantity;

                        GlobalAssert.AreEqual(BOMComponent."No.", AssemblyLine."No.", GlobalValueShouldBeMatched);
                        GlobalAssert.AreEqual(BOMComponent.Type, AssemblyLine.Type, GlobalValueShouldBeMatched);

                        GlobalAssert.AreEqual(ExpectedQty, AssemblyLine.Quantity, GlobalValueShouldBeMatched);
                        GlobalAssert.AreEqual(ExpectedQty, AssemblyLine."Quantity to Consume", GlobalValueShouldBeMatched);
                        GlobalAssert.AreEqual(ExpectedQty, AssemblyLine."Remaining Quantity", GlobalValueShouldBeMatched);
                    until (AssemblyLine.Next() = 0) and (BOMComponent.Next() = 0);
        end;
    end;

    local procedure CheckResultAfterCreateSetupDataForPostAssemvblyOrder()
    var
        BOMComponent: Record "BOM Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if GlobalItem.FindSet() then
            repeat
                BOMComponent.SetRange("Parent Item No.", GlobalItem."No.");
                if BOMComponent.FindSet() then
                    repeat
                        if BOMComponent.Type = BOMComponent.Type::Item then begin
                            // Verify Item Ledger Entry for Assembly component
                            ItemLedgerEntry.SetRange("Item No.", BOMComponent."No.");
                            ItemLedgerEntry.SetRange("Location Code", GlobalLocation.Code);
                            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
                            if ItemLedgerEntry.FindLast() then begin
                                GlobalAssert.AreEqual(GlobalChildQty, ItemLedgerEntry."Quantity", GlobalValueShouldBeMatched);
                                GlobalAssert.AreEqual(GlobalLocation.Code, ItemLedgerEntry."Location Code", GlobalValueShouldBeMatched);
                            end;
                        end;
                    until BOMComponent.Next() = 0;
            until GlobalItem.Next() = 0;
    end;

    local procedure VerifyPostedAssemblyOrderViaItemLedgerEntries()
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin

        if GlobalItem.FindFirst() then begin
            PostedAssemblyHeader.SetRange("Item No.", GlobalItem."No.");
            PostedAssemblyHeader.FindFirst();
            PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");

            ItemLedgerEntry.SetRange("Document No.", PostedAssemblyHeader."No.");
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Posted Assembly");

            if ItemLedgerEntry.FindSet() then
                repeat
                    if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::"Assembly Output" then begin
                        GlobalAssert.AreEqual(GlobalParentQty, ItemLedgerEntry."Quantity", GlobalValueShouldBeMatched);
                    end else begin
                        PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item);
                        if PostedAssemblyLine.FindSet() then begin
                            repeat
                                GlobalAssert.AreEqual(-PostedAssemblyLine.Quantity, ItemLedgerEntry."Quantity", GlobalValueShouldBeMatched);
                            until PostedAssemblyLine.Next() = 0;
                        end;
                    end;
                until ItemLedgerEntry.Next() = 0;
        end;
    end;
}
