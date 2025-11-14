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
        GlobalIsHandle: Boolean;
        GlobalValueShouldBeMatched: Label 'Values should be matched';

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
        // [SCENARIO] Create a purchase order with location and verify order status partially posted
        Initialize();

        // [GIVEN] location setup with controlled location enabled and vendor with location receiving setup
        //         and setup item with a quantity on hand in the controlled location
        SetupData();

        // [WHEN] A purchase order is created with a specific location and create warehouse receipt and partially posted
        CreatePurchaseOrderAndCreateWarehouseReceiptAndPost(1);

        // [THEN] The order status should reflect the correct location information
        CheckPurchaseOrderAndWarehouseReceiptPartiallyPosted();
    end;

    [Test]
    procedure "02_CreateSalesOrderWithPartiallyPosted"()
    begin
        // [SCENARIO] Create a sales order with location and verify order status partially posted
        Initialize();

        // [GIVEN] location setup with controlled location enabled and customer with location shipping setup
        //         and setup item with a quantity on hand in the controlled location
        SetupData();

        // [WHEN] A sales order is created with a specific location and partially posted
        CreateSalesOrderAndWarehouseShipmentAndPost(1);

        // [THEN] The order status should reflect the correct location information
        CheckSalesOrderAndWarehouseShipmentPartiallyPosted();
    end;

    [Test]
    procedure "03_CreatePurchOrderWithFullyPosted"()
    begin
        // [SCENARIO] Create a purchase order and fully post with location and verify order status
        Initialize();

        // [GIVEN] location setup with controlled location enabled and vendor with location receiving setup
        //         and setup item with a quantity on hand in the controlled location
        SetupData();

        // [WHEN] A purchase order is created with a specific location and fully posted
        CreatePurchaseOrderAndCreateWarehouseReceiptAndPost(2);

        // [THEN] The order status should reflect the correct location information
        CheckPurchaseOrderFullyPosted();
    end;

    [Test]
    procedure "04_CreateSalesOrderWithFullyPosted"()
    begin
        // [SCENARIO] Create a sales order and fully post with location and verify order status
        Initialize();

        // [GIVEN] location setup with controlled location enabled and customer with location shipping setup
        //         and setup item with a quantity on hand in the controlled location
        SetupData();

        // [WHEN] A sales order is created with a specific location and fully posted
        CreateSalesOrderAndWarehouseShipmentAndPost(2);

        // [THEN] The order status should reflect the correct location information
        CheckSalesOrderFullyPosted();
    end;

    [Test]
    procedure "05_CreatePurchOrderWithMultiPosted"()
    begin
        // [SCENARIO] Create a purchase order and multi post with location and verify order status
        Initialize();

        // [GIVEN] location setup with controlled location enabled and vendor with location receiving setup
        //         and setup item with a quantity on hand in the controlled location
        SetupData();

        // [WHEN] The order is multi posted
        CreatePurchaseOrderAndCreateWarehouseReceiptAndPost(3);

        // [THEN] The order status should reflect the correct location information
        CheckPurchaseOrderAndWarehouseReceiptMultiPosted();
    end;

    [Test]
    procedure "06_CreateSalesOrderWithMultiPosted"()
    begin
        // [SCENARIO] Create a sales order and multi post with location and verify order status
        Initialize();

        // [GIVEN] location setup with controlled location enabled and customer with location shipping setup
        //         and setup item with a quantity on hand in the controlled location
        SetupData();

        // [WHEN] The order is multi posted
        CreateSalesOrderAndWarehouseShipmentAndPost(3);

        // [THEN] The order status should reflect the correct location information
        CheckSalesOrderAndWarehouseShipmentMultiPosted();
    end;

    [Test]
    procedure "07_CheckPostedPurchOrderWithPartiallyFullyAndMultiPosted"()
    begin
        // [SCENARIO] Check a posted purchase order with partially, fully and multi posted
        Initialize();

        // [GIVEN] A purchase order is partially, fully and multi posted with a specific location
        SetupData();

        // [WHEN] The order status is checked
        GetPartiallyFullyAndMultiPostedPurchaseOrder();

        // [THEN] The order status should reflect the correct location information
        CheckPurchaseOrder();
    end;

    [Test]
    procedure "08_CheckPostedSalesOrderWithPartiallyFullyAndMultiPosted"()
    begin
        // [SCENARIO] Check a posted sales order with partially, fully and multi posted
        Initialize();

        // [GIVEN] A sales order is partially, fully and multi posted with a specific location
        SetupData();

        // [WHEN] The order status is checked
        GetPartialliFullyAndMultiPostedSalesOrder();

        // [THEN] The order status should reflect the correct location information
        CheckSalesOrder();
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

    local procedure CheckPurchaseOrder()
    var
        Number: Integer;
    begin
        if GlobalPurchaseHeader.IsEmpty() then
            for Number := 1 to 3 do
                CreatePurchaseOrderAndCreateWarehouseReceiptAndPost(Number);

        if GlobalPurchaseHeader.FindSet() then
            repeat
                case true of
                    GlobalPurchaseHeader."Posting Description".Contains('TEST_PO_P'):
                        CheckPurchaseOrderAndWarehouseReceiptPartiallyPosted();
                    GlobalPurchaseHeader."Posting Description".Contains('TEST_PO_F'):
                        CheckPurchaseOrderFullyPosted();
                    GlobalPurchaseHeader."Posting Description".Contains('TEST_PO_M'):
                        CheckPurchaseOrderAndWarehouseReceiptMultiPosted();
                end;

            until GlobalPurchaseHeader.Next() = 0;
    end;

    local procedure CheckPurchaseOrderAndWarehouseReceiptMultiPosted()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", GlobalPurchaseHeader."No.");
        GlobalPurchaseLine.SetRange("Document No.", GlobalPurchaseHeader."No.");
        if WarehouseReceiptLine.FindFirst() and GlobalPurchaseLine.FindFirst() then begin
            GlobalAssert.AreEqual(GlobalPurchaseLine."No.", WarehouseReceiptLine."Item No.", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalPurchaseLine."Location Code", WarehouseReceiptLine."Location Code", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalPurchaseLine.Quantity, WarehouseReceiptLine.Quantity, GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalPurchaseLine."Quantity Received", WarehouseReceiptLine."Qty. Received", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual("Order Status"::"Partial", GlobalPurchaseLine."Order Status", GlobalValueShouldBeMatched);
        end;

        PurchRcptHeader.SetRange("Order No.", GlobalPurchaseHeader."No.");
        GlobalAssert.RecordCount(PurchRcptHeader, 1);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if GlobalPurchaseLine.FindSet() and PurchRcptLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalPurchaseLine."No.", PurchRcptLine."No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine."Location Code", PurchRcptLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine."Quantity Received", PurchRcptLine.Quantity, GlobalValueShouldBeMatched);
                if GlobalPurchaseLine.Quantity > GlobalPurchaseLine."Quantity Received" then
                    GlobalAssert.AreEqual("Order Status"::"Partial", GlobalPurchaseLine."Order Status", GlobalValueShouldBeMatched)
                else
                    GlobalAssert.AreEqual("Order Status"::"Completed", GlobalPurchaseLine."Order Status", GlobalValueShouldBeMatched);
            until (GlobalPurchaseLine.Next() = 0) and (PurchRcptLine.Next() = 0);
    end;

    local procedure CheckPurchaseOrderAndWarehouseReceiptPartiallyPosted()
    var
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
                GlobalAssert.AreEqual("Order Status"::"Partial", GlobalPurchaseLine."Order Status", GlobalValueShouldBeMatched);
            until (WarehouseReceiptLine.Next() = 0) and (GlobalPurchaseLine.Next() = 0);
    end;

    local procedure CheckPurchaseOrderFullyPosted()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", GlobalPurchaseHeader."No.");
        GlobalAssert.RecordIsEmpty(WarehouseReceiptLine);

        GlobalPurchaseLine.SetRange("Document No.", GlobalPurchaseHeader."No.");
        PurchRcptHeader.SetRange("Order No.", GlobalPurchaseHeader."No.");
        GlobalAssert.RecordCount(PurchRcptHeader, 1);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if GlobalPurchaseLine.FindSet() and PurchRcptLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalPurchaseLine."No.", PurchRcptLine."No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine."Location Code", PurchRcptLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseLine.Quantity, PurchRcptLine.Quantity, GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual("Order Status"::"Completed", GlobalPurchaseLine."Order Status", GlobalValueShouldBeMatched);
            until (GlobalPurchaseLine.Next() = 0) and (PurchRcptLine.Next() = 0);
    end;

    local procedure CheckSalesOrder()
    var
        Number: Integer;
    begin
        if GlobalSalesHeader.IsEmpty() then
            for Number := 1 to 3 do
                CreateSalesOrderAndWarehouseShipmentAndPost(Number);
        if GlobalSalesHeader.FindSet() then
            repeat
                case true of
                    GlobalSalesHeader."Posting Description".Contains('TEST_SO_P'):
                        CheckSalesOrderAndWarehouseShipmentPartiallyPosted();
                    GlobalSalesHeader."Posting Description".Contains('TEST_SO_F'):
                        CheckSalesOrderFullyPosted();
                    GlobalSalesHeader."Posting Description".Contains('TEST_SO_M'):
                        CheckSalesOrderAndWarehouseShipmentMultiPosted();
                end;

            until GlobalSalesHeader.Next() = 0;
    end;

    local procedure CheckSalesOrderAndWarehouseShipmentMultiPosted()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", GlobalSalesHeader."No.");
        GlobalSalesLine.SetRange("Document No.", GlobalSalesHeader."No.");
        if WarehouseShipmentLine.FindFirst() and GlobalSalesLine.FindFirst() then begin
            GlobalAssert.AreEqual(GlobalSalesLine."No.", WarehouseShipmentLine."Item No.", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalSalesLine."Location Code", WarehouseShipmentLine."Location Code", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalSalesLine.Quantity, WarehouseShipmentLine.Quantity, GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalSalesLine."Quantity Shipped", WarehouseShipmentLine."Qty. Shipped", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual("Order Status"::"Partial", GlobalSalesLine."Order Status", GlobalValueShouldBeMatched);
        end;

        SalesShipmentHeader.SetRange("Order No.", GlobalSalesHeader."No.");
        GlobalAssert.RecordCount(SalesShipmentHeader, 1);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        if GlobalSalesLine.FindSet() and SalesShipmentLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalSalesLine."No.", SalesShipmentLine."No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine."Location Code", SalesShipmentLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine."Quantity Shipped", SalesShipmentLine.Quantity, GlobalValueShouldBeMatched);

                if GlobalSalesLine.Quantity > GlobalSalesLine."Quantity Shipped" then
                    GlobalAssert.AreEqual("Order Status"::"Partial", GlobalSalesLine."Order Status", GlobalValueShouldBeMatched)
                else
                    GlobalAssert.AreEqual("Order Status"::"Completed", GlobalSalesLine."Order Status", GlobalValueShouldBeMatched);
            until (GlobalSalesLine.Next() = 0) and (SalesShipmentLine.Next() = 0);
    end;

    local procedure CheckSalesOrderAndWarehouseShipmentPartiallyPosted()
    var
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
                GlobalAssert.AreEqual("Order Status"::"Partial", GlobalSalesLine."Order Status", GlobalValueShouldBeMatched);
            until (WarehouseShipmentLine.Next() = 0) and (GlobalSalesLine.Next() = 0);
    end;

    local procedure CheckSalesOrderFullyPosted()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", GlobalSalesHeader."No.");
        GlobalSalesLine.SetRange("Document No.", GlobalSalesHeader."No.");
        GlobalAssert.RecordIsEmpty(WarehouseShipmentLine);

        SalesShipmentHeader.SetRange("Order No.", GlobalSalesHeader."No.");
        GlobalAssert.RecordCount(SalesShipmentHeader, 1);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        if GlobalSalesLine.FindSet() and SalesShipmentLine.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalSalesLine."No.", SalesShipmentLine."No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine."Location Code", SalesShipmentLine."Location Code", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalSalesLine.Quantity, SalesShipmentLine.Quantity, GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual("Order Status"::"Completed", GlobalSalesLine."Order Status", GlobalValueShouldBeMatched);
            until (GlobalSalesLine.Next() = 0) and (SalesShipmentLine.Next() = 0);
    end;

    local procedure CheckSetupDataAvailable()
    begin
        GlobalAssert.RecordIsNotEmpty(GlobalLocation);
        GlobalAssert.RecordIsNotEmpty(GlobalVendor);
        GlobalAssert.RecordIsNotEmpty(GlobalCustomer);
        GlobalAssert.RecordCount(GlobalItem, 2);
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

    local procedure CreatePurchaseOrderAndCreateWarehouseReceiptAndPost(CaseNo: Integer)
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        case CaseNo of
            1:
                GlobalPurchaseHeader.SetRange("Posting Description", 'TEST_PO_P');
            2:
                GlobalPurchaseHeader.SetRange("Posting Description", 'TEST_PO_F');
            3:
                GlobalPurchaseHeader.SetRange("Posting Description", 'TEST_PO_M');
        end;

        if not GlobalPurchaseHeader.IsEmpty() then
            exit;

        LibraryPurchase.CreatePurchHeader(GlobalPurchaseHeader, "Purchase Document Type"::Order, GlobalVendor."No.");

        case CaseNo of
            1:
                GlobalPurchaseHeader."Posting Description" := 'TEST_PO_P';
            2:
                GlobalPurchaseHeader."Posting Description" := 'TEST_PO_F';
            3:
                GlobalPurchaseHeader."Posting Description" := 'TEST_PO_M';
        end;

        if GlobalItem.FindSet() then
            repeat
                LibraryPurchase.CreatePurchaseLine(GlobalPurchaseLine, GlobalPurchaseHeader, "Sales Line Type"::Item, GlobalItem."No.", 10.00);
            until GlobalItem.Next() = 0;

        LibraryPurchase.ReleasePurchaseDocument(GlobalPurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(GlobalPurchaseHeader);

        GlobalWarehouseReceiptLine.SetRange("Source No.", GlobalPurchaseHeader."No.");

        case CaseNo of
            1:
                if GlobalWarehouseReceiptLine.FindSet() then
                    repeat
                        GlobalWarehouseReceiptLine.Validate("Qty. to Receive", Round(GlobalWarehouseReceiptLine.Quantity / 2, 0.1, '='));
                        GlobalWarehouseReceiptLine.Modify(true);
                    until GlobalWarehouseReceiptLine.Next() = 0;
            2:
                GlobalWarehouseReceiptLine.FindFirst();
            3:
                if GlobalWarehouseReceiptLine.FindFirst() then begin
                    GlobalWarehouseReceiptLine.Validate("Qty. to Receive", Round(GlobalWarehouseReceiptLine.Quantity / 2, 0.1, '='));
                    GlobalWarehouseReceiptLine.Modify(true);
                end;
        end;

        GlobalWarehouseReceiptHeader.SetRange("Location Code", GlobalPurchaseHeader."Location Code");
        GlobalWarehouseReceiptHeader.SetRange("No.", GlobalWarehouseReceiptLine."No.");
        GlobalWarehouseReceiptHeader.FindFirst();
        LibraryWarehouse.PostWhseReceipt(GlobalWarehouseReceiptHeader);
    end;

    local procedure CreateSalesOrderAndWarehouseShipmentAndPost(CaseNo: Integer)
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        case CaseNo of
            1:
                GlobalSalesHeader.SetRange("Posting Description", 'TEST_SO_P');
            2:
                GlobalSalesHeader.SetRange("Posting Description", 'TEST_SO_F');
            3:
                GlobalSalesHeader.SetRange("Posting Description", 'TEST_SO_M');
        end;

        if not GlobalSalesHeader.IsEmpty() then
            exit;

        LibrarySales.CreateSalesHeader(GlobalSalesHeader, "Sales Document Type"::Order, GlobalCustomer."No.");

        case CaseNo of
            1:
                GlobalSalesHeader."Posting Description" := 'TEST_SO_P';
            2:
                GlobalSalesHeader."Posting Description" := 'TEST_SO_F';
            3:
                GlobalSalesHeader."Posting Description" := 'TEST_SO_M';
        end;

        if GlobalItem.FindSet() then
            repeat
                LibrarySales.CreateSalesLine(GlobalSalesLine, GlobalSalesHeader, "Sales Line Type"::Item, GlobalItem."No.", 10.00);
            until GlobalItem.Next() = 0;

        LibrarySales.ReleaseSalesDocument(GlobalSalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(GlobalSalesHeader);

        GlobalWarehouseShipmentLine.SetRange("Source No.", GlobalSalesHeader."No.");

        case CaseNo of
            1:
                if GlobalWarehouseShipmentLine.FindSet() then
                    repeat
                        GlobalWarehouseShipmentLine.Validate("Qty. to Ship", Round(GlobalWarehouseShipmentLine.Quantity / 2, 0.1, '='));
                        GlobalWarehouseShipmentLine.Modify(true);
                    until GlobalWarehouseShipmentLine.Next() = 0;
            2:
                GlobalWarehouseShipmentLine.FindFirst();
            3:
                if GlobalWarehouseShipmentLine.FindFirst() then begin
                    GlobalWarehouseShipmentLine.Validate("Qty. to Ship", Round(GlobalWarehouseShipmentLine.Quantity / 2, 0.1, '='));
                    GlobalWarehouseShipmentLine.Modify(true);
                end;
        end;

        GlobalWarehouseShipmentHeader.SetRange("Location Code", GlobalSalesHeader."Location Code");
        GlobalWarehouseShipmentHeader.SetRange("No.", GlobalWarehouseShipmentLine."No.");
        GlobalWarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(GlobalWarehouseShipmentHeader, false);
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
        Number: Integer;
    begin
        GlobalLocation.SetRange(Name, 'TEST');
        if not GlobalLocation.FindFirst() then begin
            LibraryWarehouse.CreateLocation(GlobalLocation);
            GlobalLocation.Validate(Name, 'TEST');
            GlobalLocation.Validate("Require Receive", true);
            GlobalLocation.Validate("Require Shipment", true);
            GlobalLocation.Modify(true);
        end;

        WarehouseEmployee.SetRange("Location Code", GlobalLocation.Code);
        if WarehouseEmployee.IsEmpty() then
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, GlobalLocation.Code, false);

        GlobalVendor.SetRange("Location Code", GlobalLocation.Code);
        if not GlobalVendor.FindFirst() then begin
            LibraryPurchase.CreateVendor(GlobalVendor);
            GlobalVendor."Location Code" := GlobalLocation.Code;
            GlobalVendor.Modify(true);
        end;

        GlobalCustomer.SetRange("Location Code", GlobalLocation.Code);
        if not GlobalCustomer.FindFirst() then begin
            LibrarySales.CreateCustomer(GlobalCustomer);
            GlobalCustomer."Location Code" := GlobalLocation.Code;
            GlobalCustomer.Modify(true);
        end;

        for Number := 1 to 2 do begin
            GlobalItem.SetFilter(Description, 'TEST_ITEM' + Format(Number));
            if not GlobalItem.FindFirst() then begin
                LibraryInventory.CreateItem(GlobalItem);
                GlobalItem.Validate(Description, 'TEST_ITEM' + Format(Number));
                GlobalItem.Modify();
            end;

            ItemLedgerEntry.SetRange("Item No.", GlobalItem."No.");
            ItemLedgerEntry.SetRange("Location Code", GlobalLocation.Code);
            ItemLedgerEntry.CalcSums(Quantity);
            if ItemLedgerEntry.Quantity = 0.00 then begin
                LibraryInventory.CreateItemJnlLine(ItemJournalLine,
                                                ItemJournalLine."Entry Type"::"Positive Adjmt.",
                                                WorkDate(),
                                                GlobalItem."No.",
                                                30.00,
                                                GlobalLocation.Code);

                CheckInsertVATPostingSetup(GlobalCustomer."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
                CheckInsertVATPostingSetup(GlobalVendor."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
                CreateGenPostingSetup(GlobalCustomer."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
                CreateGenPostingSetup(GlobalVendor."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
                CreateInventoryPostingSetup(GlobalLocation.Code, GlobalItem."Inventory Posting Group");
                LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
            end;

        end;

        GlobalItem.SetFilter(Description, 'TEST_ITEM*');
        GlobalIsHandle := true;
    end;

    local procedure GetPartialliFullyAndMultiPostedSalesOrder()
    begin
        GlobalSalesHeader.SetRange("Document Type", GlobalSalesHeader."Document Type"::Order);
        GlobalSalesHeader.SetRange(Status, GlobalSalesHeader.Status::Released);
        GlobalSalesHeader.SetRange("Location Code", GlobalLocation.Code);
        GlobalSalesHeader.SetRange("Sell-to Customer No.", GlobalCustomer."No.");
        GlobalSalesHeader.SetFilter("Posting Description", 'TEST_SO_*');
    end;

    local procedure GetPartiallyFullyAndMultiPostedPurchaseOrder()
    begin
        GlobalPurchaseHeader.SetRange("Document Type", GlobalPurchaseHeader."Document Type"::Order);
        GlobalPurchaseHeader.SetRange(Status, GlobalPurchaseHeader.Status::Released);
        GlobalPurchaseHeader.SetRange("Location Code", GlobalLocation.Code);
        GlobalPurchaseHeader.SetRange("Pay-to Vendor No.", GlobalVendor."No.");
        GlobalPurchaseHeader.SetFilter("Posting Description", 'TEST_PO_*');
    end;

    local procedure Initialize()
    begin
        // Initialization code for tests
    end;

    local procedure SetupData()
    begin
        if not GlobalIsHandle then
            CreateSetupDataforPurchaseOrderAndSalesOrder();
    end;
}