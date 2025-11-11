namespace ALWSP.ALWSP;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Journal;
using Microsoft.Sales.Document;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Warehouse.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Item;

codeunit 50010 "Test Order Status Ctrl.Locat"
{
    Subtype = Test;

    var
        GlobalCustomer: Record Customer;
        GlobalItem: Record Item;
        GlobalLocation: Record Location;
        GlobalPurchaseHeader: Record "Purchase Header";
        GlobalPurchaseLine: Record "Purchase Line";
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        GlobalVendor: Record Vendor;
        GlobalWarehouseReceiptHeader: Record "Warehouse Receipt Header";
        GlobalWarehouseReceiptLine: Record "Warehouse Receipt Line";
        GlobalWarehouseShipmentHeader: Record "Warehouse Shipment Header";
        GlobalWarehouseShipmentLine: Record "Warehouse Shipment Line";
        GlobalAssert: Codeunit "Assert";
        GlobalIsHandled: Boolean;
        GlobalValueShouldBeMatched: Label 'Values should be matched';
        GlobalValueShouldNotbeEmpty: Label 'Value should not be empty';

    [Test]
    procedure "00_GenaralSetupforCreatePurchAndSalesOrderWithCtrlWarehouse"()
    begin
        // [SECENARIO] Setup controlled warehouse for testing order status with location
        Initialize();

        // [WHEN] Controlled location is set up and setup item with a quantity on hand in the controlled location
        CreateSetupDataforPurchaseOrderAndSalesOrder();

        // [THEN] Controlled location is available for use in purchase and sales orders
        CheckSetupDataAvailable();
    end;


    [Test]
    procedure "01_CreatePurchaseOrderWithPartiallyPosted"()
    begin
        // [SCENARIO] Create a purchase order with location and verify order status
        Initialize();

        // [GIVEN] location setup with controlled location enabled and vendor with location receiving setup
        //         and setup item with a quantity on hand in the controlled location
        SetupDataforPurchOrder();

        // [WHEN] A purchase order is created with a specific location and create warehouse receipt and partially posted
        CreatePurchaseOrderAndCreateWhseReceiptAndPost(false);

        // [THEN] The order status should reflect the correct location information
        CheckPurchaseOrderAndWhseReceiptPartiallyPosted();
    end;

    [Test]
    procedure "02_CreateSalesOrderWithPartiallyPosted"()
    begin
        // [SCENARIO] Create a sales order with location and verify order status
        Initialize();

        // [GIVEN] A sales order is created with a specific location 
        SetupDataforSalesOrder();

        // [WHEN] The order status is created with a specific location and partially posted
        CreateSalesOrderAndWhseShipmentAndPost(false);

        // [THEN] The order status should reflect the correct location information
        CheckSalesOrderAndWhseShipmentPartiallyPosted();
    end;

    [Test]
    procedure "03_CreatePurchOrderWithFullyPosted"()
    begin
        // [SCENARIO] Create a purchase order and fully post with location and verify order status
        Initialize();

        // [GIVEN] A purchase order is created with a specific location
        SetupDataforPurchOrder();

        // [WHEN] The order is fully posted
        CreatePurchaseOrderAndCreateWhseReceiptAndPost(true);

        // [THEN] The order status should reflect the correct location information
        CheckPurchaseOrderAndWhseReceiptFullyPosted();
    end;

    [Test]
    procedure "04_CreateSalesOrderWithFullyPosted"()
    begin
        // [SCENARIO] Create a sales order and fully post with location and verify order status
        Initialize();

        // [GIVEN] A sales order is created with a specific location
        SetupDataforSalesOrder();

        // [WHEN] The order is fully posted
        CreateSalesOrderAndWhseShipmentAndPost(true);

        // [THEN] The order status should reflect the correct location information
        CheckSalesOrderAndWhseShipmentFullyPosted();
    end;

    [Test]
    procedure "05_CheckPostedPurchOrderAndSalesOrderWithPartiallyPosted"()
    begin
        // [SCENARIO] Check a posted purchase order and posted sales order with location and partially posted
        Initialize();

        // [GIVEN] A purchase order and sales order is partially posted with a specific location
        SetupDataforPurchOrder();

        // [WHEN] The order status is checked and partially posted
        GetPartiallyPostedPurchaseOrderAndSalesOrder();

        // [THEN] The order status should reflect the correct location information
    end;

    [Test]
    procedure "06_CheckPostedPurchOrderAndSalesOrderWithFullyPosted"()
    begin
        // [SCENARIO] Check a posted purchase order and posted sales order with location and fully posted
        Initialize();

        // [GIVEN] A purchase order and sales order is fully posted with a specific location
        SetupDataforSalesOrder();

        // [WHEN] The order status is checked
        GetFullyPostedPurchaseOrderAndSalesOrder();

        // [THEN] The order status should reflect the correct location information
    end;

    local procedure GetFullyPostedPurchaseOrderAndSalesOrder()
    begin
        // Implementation for getting fully posted purchase order and sales order
    end;

    local procedure GetPartiallyPostedPurchaseOrderAndSalesOrder()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Implementation for getting partially posted purchase order and sales order
        GlobalSalesHeader.SetRange("Document Type", GlobalSalesHeader."Document Type"::Order);
        GlobalSalesHeader.SetRange(Status, GlobalSalesHeader.Status::Released);
        GlobalSalesHeader.SetRange("Location Code", GlobalLocation.Code);
        GlobalSalesHeader.SetRange("Sell-to Customer No.", GlobalCustomer."No.");


        GlobalPurchaseHeader.SetRange("Document Type", GlobalPurchaseHeader."Document Type"::Order);
        GlobalPurchaseHeader.SetRange(Status, GlobalPurchaseHeader.Status::Released);
        GlobalPurchaseHeader.SetRange("Location Code", GlobalLocation.Code);
        GlobalPurchaseHeader.SetRange("Pay-to Vendor No.", GlobalVendor."No.");
    end;

    local procedure CheckPurchaseOrderAndWhseReceiptFullyPosted()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", GlobalPurchaseHeader."No.");
        GlobalPurchaseLine.SetRange("Document No.", GlobalPurchaseHeader."No.");

        if WarehouseReceiptLine.FindSet() and GlobalPurchaseLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalPurchaseLine."No.", WarehouseReceiptLine."Item No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine."Location Code", WarehouseReceiptLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine.Quantity, WarehouseReceiptLine.Quantity, GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine.Quantity, WarehouseReceiptLine."Qty. Received", GlobalValueShouldBeMatched);
            until (WarehouseReceiptLine.Next() = 0) and (GlobalPurchaseLine.Next() = 0);
    end;

    local procedure CheckSalesOrderAndWhseShipmentFullyPosted()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", GlobalSalesHeader."No.");
        GlobalSalesLine.SetRange("Document No.", GlobalSalesHeader."No.");

        if WarehouseShipmentLine.FindSet() and GlobalSalesLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalSalesLine."No.", WarehouseShipmentLine."Item No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine."Location Code", WarehouseShipmentLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine.Quantity, WarehouseShipmentLine.Quantity, GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine.Quantity, WarehouseShipmentLine."Qty. Shipped", GlobalValueShouldBeMatched);
            until (WarehouseShipmentLine.Next() = 0) and (GlobalSalesLine.Next() = 0);
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

    local procedure CheckPurchaseOrderAndWhseReceiptPartiallyPosted()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", GlobalPurchaseHeader."No.");
        GlobalPurchaseLine.SetRange("Document No.", GlobalPurchaseHeader."No.");

        if WarehouseReceiptLine.FindSet() and GlobalPurchaseLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalPurchaseLine."No.", WarehouseReceiptLine."Item No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine."Location Code", WarehouseReceiptLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine.Quantity, WarehouseReceiptLine.Quantity, GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine."Quantity Received", WarehouseReceiptLine."Qty. Received", GlobalValueShouldBeMatched);
            until (WarehouseReceiptLine.Next() = 0) and (GlobalPurchaseLine.Next() = 0);
    end;

    local procedure CheckSalesOrderAndWhseShipmentPartiallyPosted()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", GlobalSalesHeader."No.");
        GlobalSalesLine.SetRange("Document No.", GlobalSalesHeader."No.");

        if WarehouseShipmentLine.FindSet() and GlobalSalesLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalSalesLine."No.", WarehouseShipmentLine."Item No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine."Location Code", WarehouseShipmentLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine.Quantity, WarehouseShipmentLine.Quantity, GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine."Quantity Shipped", WarehouseShipmentLine."Qty. Shipped", GlobalValueShouldBeMatched);
            until (WarehouseShipmentLine.Next() = 0) and (GlobalSalesLine.Next() = 0);
    end;

    local procedure CheckSetupDataAvailable()
    begin
        GlobalAssert.IsFalse(GlobalLocation.IsEmpty(), GlobalValueShouldNotbeEmpty);
        GlobalAssert.IsFalse(GlobalVendor.IsEmpty(), GlobalValueShouldNotbeEmpty);
        GlobalAssert.IsFalse(GlobalCustomer.IsEmpty(), GlobalValueShouldNotbeEmpty);

        GlobalAssert.RecordCount(GlobalItem, 3);
    end;

    local procedure CreateGenPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
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

    local procedure CreatePurchaseOrderAndCreateWhseReceiptAndPost(PostFully: Boolean)
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        OrderStatusManagement: Codeunit OrderStatusManagement;
    begin
        LibraryPurchase.CreatePurchHeader(GlobalPurchaseHeader, "Purchase Document Type"::Order, GlobalVendor."No.");
        if GlobalItem.FindSet() then
            repeat
                LibraryPurchase.CreatePurchaseLine(GlobalPurchaseLine, GlobalPurchaseHeader, "Sales Line Type"::Item, GlobalItem."No.", 10);
            until GlobalItem.Next() = 0;

        CheckInsertVATPostingSetup(GlobalCustomer."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
        CreateGenPostingSetup(GlobalCustomer."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
        if GlobalItem.FindSet() then
            repeat
                CreateInventoryPostingSetup(GlobalLocation.Code, GlobalItem."Inventory Posting Group");
            until GlobalItem.Next() = 0;

        LibraryPurchase.ReleasePurchaseDocument(GlobalPurchaseHeader);

        LibraryWarehouse.CreateWhseReceiptFromPO(GlobalPurchaseHeader);

        GlobalWarehouseReceiptHeader.SetRange("Location Code", GlobalPurchaseHeader."Location Code");
        GlobalWarehouseReceiptLine.SetRange("Source No.", GlobalPurchaseHeader."No.");
        if not PostFully then begin
            if GlobalWarehouseReceiptLine.FindSet() then
                repeat
                    GlobalWarehouseReceiptLine."Qty. to Receive" := Round(GlobalWarehouseReceiptLine.Quantity / 2, 0.1, '=');
                    GlobalWarehouseReceiptLine.Modify(true);
                until GlobalWarehouseReceiptLine.Next() = 0;
        end;
        GlobalWarehouseReceiptLine.FindFirst();
        GlobalWarehouseReceiptHeader.SetRange("No.", GlobalWarehouseReceiptLine."No.");
        GlobalWarehouseReceiptHeader.FindFirst();
        LibraryWarehouse.PostWhseReceipt(GlobalWarehouseReceiptHeader);
        OrderStatusManagement.UpdatePurchaseLineStatus(GlobalWarehouseReceiptLine);
    end;

    local procedure CreateSalesOrderAndWhseShipmentAndPost(FullyPost: Boolean)
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        OrderStatusManagement: Codeunit OrderStatusManagement;
    begin
        LibrarySales.CreateSalesHeader(GlobalSalesHeader, "Sales Document Type"::Order, GlobalCustomer."No.");
        if GlobalItem.FindSet() then
            repeat
                LibrarySales.CreateSalesLine(GlobalSalesLine, GlobalSalesHeader, "Sales Line Type"::Item, GlobalItem."No.", 10);
                GlobalSalesLine."Location Code" := GlobalLocation.Code;
                GlobalSalesLine.Modify(true);
            until GlobalItem.Next() = 0;

        CheckInsertVATPostingSetup(GlobalCustomer."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
        CreateGenPostingSetup(GlobalCustomer."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
        if GlobalItem.FindSet() then
            repeat
                CreateInventoryPostingSetup(GlobalLocation.Code, GlobalItem."Inventory Posting Group");
            until GlobalItem.Next() = 0;

        LibrarySales.ReleaseSalesDocument(GlobalSalesHeader);

        LibraryWarehouse.CreateWhseShipmentFromSO(GlobalSalesHeader);

        GlobalWarehouseShipmentHeader.SetRange("Location Code", GlobalSalesHeader."Location Code");
        GlobalWarehouseShipmentLine.SetRange("Source No.", GlobalSalesHeader."No.");
        if not FullyPost then begin
            if GlobalWarehouseShipmentLine.FindSet() then
                repeat
                    GlobalWarehouseShipmentLine."Qty. to Ship" := Round(GlobalWarehouseShipmentLine.Quantity / 2, 0.1, '=');
                    GlobalWarehouseShipmentLine.Modify(true);
                until GlobalWarehouseShipmentLine.Next() = 0;
        end;
        GlobalWarehouseShipmentLine.FindFirst();
        GlobalWarehouseShipmentHeader.SetRange("No.", GlobalWarehouseShipmentLine."No.");
        GlobalWarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(GlobalWarehouseShipmentHeader, false);
        OrderStatusManagement.UpdateSalesLineStatus(GlobalWarehouseShipmentLine);
    end;

    local procedure CreateSetupDataforPurchaseOrderAndSalesOrder()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ItemCount: Integer;
    begin
        GlobalLocation.SetRange("Require Receive", true);
        GlobalLocation.SetRange("Require Shipment", true);
        GlobalLocation.SetRange("Require Put-away", false);
        GlobalLocation.SetRange("Require Pick", false);
        GlobalLocation.SetRange("Bin Mandatory", false);
        if not GlobalLocation.FindFirst() then begin
            LibraryWarehouse.CreateLocation(GlobalLocation);
            GlobalLocation."Require Receive" := true;
            GlobalLocation."Require Shipment" := true;
            GlobalLocation.Modify(true);

            CreateSetupDataforPurchaseOrderAndSalesOrder();
        end;

        WarehouseEmployee.SetRange("Location Code", GlobalLocation.Code);
        if not WarehouseEmployee.FindFirst() then begin
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, GlobalLocation.Code, false);

            CreateSetupDataforPurchaseOrderAndSalesOrder();
        end;

        GlobalVendor.SetRange("Location Code", GlobalLocation.Code);
        if not GlobalVendor.FindFirst() then begin
            LibraryPurchase.CreateVendor(GlobalVendor);
            GlobalVendor."Location Code" := GlobalLocation.Code;
            GlobalVendor.Modify(true);

            CreateSetupDataforPurchaseOrderAndSalesOrder();
        end;

        GlobalCustomer.SetRange("Location Code", GlobalLocation.Code);
        if not GlobalCustomer.FindFirst() then begin
            LibrarySales.CreateCustomer(GlobalCustomer);
            GlobalCustomer."Location Code" := GlobalLocation.Code;
            GlobalCustomer.Modify(true);

            CreateSetupDataforPurchaseOrderAndSalesOrder();
        end;

        ItemLedgerEntry.SetRange("Location Code", GlobalLocation.Code);
        if ItemLedgerEntry.Count() < 3 then begin
            for ItemCount := 1 to 3 do begin
                LibraryInventory.CreateItem(GlobalItem);
                LibraryInventory.CreateItemJnlLine(ItemJournalLine,
                                                ItemJournalLine."Entry Type"::"Positive Adjmt.",
                                                WorkDate(),
                                                GlobalItem."No.",
                                                30,
                                                GlobalLocation.Code);


                CreateInventoryPostingSetup(GlobalLocation.Code, GlobalItem."Inventory Posting Group");

                LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
            end;

            CreateSetupDataforPurchaseOrderAndSalesOrder();
        end;

        // Choose 3 items of item ledger entries in the location to global item record
        ItemLedgerEntry.SetRange("Location Code", GlobalLocation.Code);
        ItemCount := 0;
        if ItemLedgerEntry.FindSet() then //TODO: Improve logic to select distinct items
            repeat
                if GlobalItem.Get(ItemLedgerEntry."Item No.") then begin
                    if not GlobalItem.Mark() then begin
                        GlobalItem.Mark(true);
                        ItemCount += 1;
                        if ItemCount >= 3 then
                            break;
                    end;
                end;
            until ItemLedgerEntry.Next() = 0;
        GlobalItem.MarkedOnly(true);
        GlobalIsHandled := true;
    end;

    local procedure Initialize()
    begin
        // Initialization code for tests

    end;

    local procedure SetupDataforPurchOrder()
    begin
        // Setup data for purchase order tests
        if not GlobalIsHandled then
            CreateSetupDataforPurchaseOrderAndSalesOrder();
    end;

    local procedure SetupDataforSalesOrder()
    begin
        // Setup data for sales order tests
        if not GlobalIsHandled then
            CreateSetupDataforPurchaseOrderAndSalesOrder();
    end;
}
