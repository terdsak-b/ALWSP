codeunit 50102 "ESD Comment Transfer Test"
{
    Subtype = Test;

    var
        GlobalAssert: Codeunit Assert;
        GlobalComment: Label 'This is a test comment';
        GlobalValueShouldbeMatch: Label 'Value should be matched';
        GlobalValueShouldbeNotMatch: Label 'Value should be not matched';
        GlobalItem: Record Item;

        GlobalCustomer: Record Customer;
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        GlobalLibrarySales: Codeunit "Library - Sales";

        GlobalSalesInvoiceHeader: Record "Sales Invoice Header";
        GlobalSalesShipmentHader: Record "Sales Shipment Header";

        GlobalVendor: Record Vendor;
        GlobalPurchaseHeader: Record "Purchase Header";
        GlobalPurchaseLine: Record "Purchase Line";
        GlobalLibraryPurchase: Codeunit "Library - Purchase";

        GlobalPurchaseInvoiceHeader: Record "Purch. Inv. Header";
        GlobalPurchaseReceiptHeader: Record "Purch. Rcpt. Header";

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

    local procedure Initialize()
    begin
        //Temporary empty procedure for Initialize
    end;

    [Test]
    [HandlerFunctions('ConfirmSalesHandler')]
    procedure VerifyCustCmntTransferToPostedSalesInvLineAndSalesShiptLine()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that customer comments are transferred to sales line when creating a new sales order.
        //            and comment should be same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A customer with a comment and transfer comment enabled. and create a new sales order for that customer.
        CreateCustSetupData(GlobalComment, true);

        // [When] Add sales line to the sales order and add qty and Posted document sales invoice line.
        SalesOrderSetup(true);

        // [Then] The sales line should have the customer comment in the ESD Comment field.
        CheckingPostedCommentTransferSales();
    end;

    [ConfirmHandler]
    procedure ConfirmSalesHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmSalesHandler')]
    procedure VerifyCustCmnt_Not_TransferbyCmntTrfield()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that customer comments are transferred to sales line when creating a new sales order.
        //            and comment should be Not same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A customer with a comment and transfer comment disabled. and create a new sales order for that customer.
        CreateCustSetupData(GlobalComment, false);

        // [When] Add sales line to the sales order and add qty and Posted document sales invoice line.
        SalesOrderSetup(false);

        // [Then] The sales line should Not have the customer comment in the ESD Comment field.
        "CheckingPostedComment_Not_TransferSales"();
    end;

    [Test]
    [HandlerFunctions('UnconfirmSalesHandler')]
    procedure VerifyCustCmnt_Not_TransferbyHandlerCmtTrfieldTrue()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that customer comments are transferred to sales line when creating a new sales order.
        //            and comment should be Not same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A customer with a comment and transfer comment disabled. and create a new sales order for that customer.
        CreateCustSetupData(GlobalComment, true);

        // [When] Add sales line to the sales order and add qty and Posted document sales invoice line.
        SalesOrderSetup(false);

        // [Then] The sales line should Not have the customer comment in the ESD Comment field.
        "CheckingPostedComment_Not_TransferSales"();
    end;

    [ConfirmHandler]
    procedure UnconfirmSalesHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [Test]
    [HandlerFunctions('UnconfirmSalesHandler')]
    procedure VerifyCustCmnt_Not_TransferbyTransferbyHandlerCmtTrfieldFalse()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that customer comments are transferred to sales line when creating a new sales order.
        //            and comment should be Not same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A customer with a comment and transfer comment disabled. and create a new sales order for that customer.
        CreateCustSetupData(GlobalComment, false);

        // [When] Add sales line to the sales order and add qty and Posted document sales invoice line.
        SalesOrderSetup(false);

        // [Then] The sales line should Not have the customer comment in the ESD Comment field.
        "CheckingPostedComment_Not_TransferSales"();
    end;

    [Test]
    [HandlerFunctions('ConfirmPurchaseHandler')]
    procedure VerifyVendorCmntTransferToPostedPurchInvLineAndPurchRcptLine()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that vendor comments are transferred to purchase line when creating a new purchase order.
        //            and comment should be same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A vendor with a comment and transfer comment enabled. and create a new purchase order for that vendor.
        CreateVendSetupData(GlobalComment, true);

        // [When] Add purchase line to the purchase order and add qty and Posted document purchase invoice line.
        PurchaseOrderSetup(true);

        // [Then] The purchase line should have the vendor comment in the ESD Comment field.
        CheckingPostedCommentTransferPurchase();

    end;

    [ConfirmHandler]
    procedure ConfirmPurchaseHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmPurchaseHandler')]
    procedure VerifyVendorCmnt_Not_TransferbyCmntTrfield()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that vendor comments are transferred to purchase line when creating a new purchase order.
        //            and comment should be Not same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A vendor with a comment and transfer comment disabled. and create a new purchase order for that vendor.
        CreateVendSetupData(GlobalComment, false);

        // [When] Add purchase line to the purchase order and add qty and Posted document purchase invoice line.
        PurchaseOrderSetup(false);

        // [Then] The purchase line should Not have the vendor comment in the ESD Comment field.
        CheckingPostedComment_Not_TransferPurchase();

    end;

    [Test]
    [HandlerFunctions('UnconfirmPurchaseHandler')]
    procedure VerifyVendorCmnt_Not_TransferbyHandlerCmtTrfieldTrue()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that vendor comments are transferred to purchase line when creating a new purchase order.
        //            and comment should be Not same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A vendor with a comment and transfer comment disabled. and create a new purchase order for that vendor.
        CreateVendSetupData(GlobalComment, true);

        // [When] Add purchase line to the purchase order and add qty and Posted document purchase invoice line.
        PurchaseOrderSetup(false);

        // [Then] The purchase line should Not have the vendor comment in the ESD Comment field.
        CheckingPostedComment_Not_TransferPurchase();

    end;

    [ConfirmHandler]
    procedure UnconfirmPurchaseHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [Test]
    [HandlerFunctions('UnconfirmPurchaseHandler')]
    procedure VerifyVendorCmnt_Not_TransferbyHandlerCmtTrfieldFalse()
    begin
        // [Feature] ESD Comment Transfer Test
        // [Scenario] Verify that vendor comments are transferred to purchase line when creating a new purchase order.
        //            and comment should be Not same in posted sales invoice line and sales shipment line.
        Initialize();

        // [Given] A vendor with a comment and transfer comment disabled. and create a new purchase order for that vendor.
        CreateVendSetupData(GlobalComment, false);

        // [When] Add purchase line to the purchase order and add qty and Posted document purchase invoice line.
        PurchaseOrderSetup(false);

        // [Then] The purchase line should Not have the vendor comment in the ESD Comment field.
        CheckingPostedComment_Not_TransferPurchase();

    end;

    local procedure CreateCustSetupData(Comment: Text[100]; TransferComment: Boolean)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        GlobalLibrarySales.CreateCustomer(GlobalCustomer);
        GlobalCustomer.Validate("Transfer Comment", TransferComment);
        GlobalCustomer.Validate("ESD Comment", Comment);
        GlobalCustomer.Modify();

        LibraryInventory.CreateItem(GlobalItem);

        CheckInsertVATPostingSetup(GlobalCustomer."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
        CreateGenPostingSetup(GlobalCustomer."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
        CreateInventoryPostingSetup('', GlobalItem."Inventory Posting Group");
    end;

    local procedure SalesOrderSetup(AreEqual: Boolean)
    var
        InvoiceNo: Code[20];
        ShipmentNo: Code[20];
    begin
        GlobalLibrarySales.CreateSalesHeader(GlobalSalesHeader, "Sales Document Type"::Order, GlobalCustomer."No.");
        GlobalLibrarySales.CreateSalesLine(GlobalSalesLine, GlobalSalesHeader, "Sales Line Type"::Item, GlobalItem."No.", 1.00);

        if AreEqual then
            GlobalAssert.AreEqual(GlobalCustomer."ESD Comment", GlobalSalesLine."ESD Comment", GlobalValueShouldbeMatch)
        else
            GlobalAssert.AreNotEqual(GlobalCustomer."ESD Comment", GlobalSalesLine."ESD Comment", GlobalValueShouldbeNotMatch);

        ShipmentNo := GlobalLibrarySales.PostSalesDocument(GlobalSalesHeader, true, false);
        InvoiceNo := GlobalLibrarySales.PostSalesDocument(GlobalSalesHeader, false, true);

        GlobalSalesShipmentHader.Get(ShipmentNo);
        GlobalSalesInvoiceHeader.Get(InvoiceNo);
    end;

    local procedure CheckingPostedCommentTransferSales()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", GlobalSalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, "Sales Line Type"::Item);
        GlobalAssert.RecordCount(SalesInvoiceLine, 1);
        SalesInvoiceLine.FindFirst();
        SalesShipmentLine.SetRange("Document No.", GlobalSalesShipmentHader."No.");
        SalesShipmentLine.SetRange(Type, "Sales Line Type"::Item);
        GlobalAssert.RecordCount(SalesShipmentLine, 1);
        SalesShipmentLine.FindFirst();
        GlobalAssert.AreEqual(GlobalCustomer."ESD Comment", SalesInvoiceLine."ESD Comment", GlobalValueShouldbeMatch);
        GlobalAssert.AreEqual(GlobalCustomer."ESD Comment", SalesShipmentLine."ESD Comment", GlobalValueShouldbeMatch);
    end;

    local procedure "CheckingPostedComment_Not_TransferSales"()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", GlobalSalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, "Sales Line Type"::Item);
        GlobalAssert.RecordCount(SalesInvoiceLine, 1);
        SalesInvoiceLine.FindFirst();
        SalesShipmentLine.SetRange("Document No.", GlobalSalesShipmentHader."No.");
        SalesShipmentLine.SetRange(Type, "Sales Line Type"::Item);
        GlobalAssert.RecordCount(SalesShipmentLine, 1);
        SalesShipmentLine.FindFirst();
        GlobalAssert.AreNotEqual(GlobalCustomer."ESD Comment", SalesInvoiceLine."ESD Comment", GlobalValueShouldbeNotMatch);
        GlobalAssert.AreNotEqual(GlobalCustomer."ESD Comment", SalesShipmentLine."ESD Comment", GlobalValueShouldbeNotMatch);
    end;

    local procedure CreateVendSetupData(Comment: Text[100]; TransferComment: Boolean)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        GlobalLibraryPurchase.CreateVendor(GlobalVendor);
        GlobalVendor.Validate("Transfer Comment", TransferComment);
        GlobalVendor.Validate("ESD Comment", Comment);
        GlobalVendor.Modify();

        LibraryInventory.CreateItem(GlobalItem);

        CheckInsertVATPostingSetup(GlobalVendor."VAT Bus. Posting Group", GlobalItem."VAT Prod. Posting Group");
        CreateGenPostingSetup(GlobalVendor."Gen. Bus. Posting Group", GlobalItem."Gen. Prod. Posting Group");
        CreateInventoryPostingSetup('', GlobalItem."Inventory Posting Group");
    end;

    local procedure PurchaseOrderSetup(AreEqual: Boolean)
    var
        InvoiceNo: Code[20];
        ReceiptNo: Code[20];
        LibraryUtility: Codeunit "Library - Utility";
    begin
        GlobalLibraryPurchase.CreatePurchHeader(GlobalPurchaseHeader, "Purchase Document Type"::Order, GlobalVendor."No.");
        GlobalLibraryPurchase.CreatePurchaseLine(GlobalPurchaseLine, GlobalPurchaseHeader, "Purchase Line Type"::Item, GlobalItem."No.", 1.00);

        if AreEqual then
            GlobalAssert.AreEqual(GlobalVendor."ESD Comment", GlobalPurchaseLine."ESD Comment", GlobalValueShouldbeMatch)
        else
            GlobalAssert.AreNotEqual(GlobalVendor."ESD Comment", GlobalPurchaseLine."ESD Comment", GlobalValueShouldbeNotMatch);

        GlobalPurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateRandomText(20);
        GlobalPurchaseHeader.Modify();

        ReceiptNo := GlobalLibraryPurchase.PostPurchaseDocument(GlobalPurchaseHeader, true, false);
        InvoiceNo := GlobalLibraryPurchase.PostPurchaseDocument(GlobalPurchaseHeader, false, true);

        GlobalPurchaseReceiptHeader.Get(ReceiptNo);
        GlobalPurchaseInvoiceHeader.Get(InvoiceNo);
    end;

    local procedure CheckingPostedCommentTransferPurchase()
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", GlobalPurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange(Type, "Purchase Line Type"::Item);
        GlobalAssert.RecordCount(PurchaseInvoiceLine, 1);
        PurchaseInvoiceLine.FindFirst();
        PurchaseReceiptLine.SetRange("Document No.", GlobalPurchaseReceiptHeader."No.");
        PurchaseReceiptLine.SetRange(Type, "Purchase Line Type"::Item);
        GlobalAssert.RecordCount(PurchaseReceiptLine, 1);
        PurchaseReceiptLine.FindFirst();
        GlobalAssert.AreEqual(GlobalVendor."ESD Comment", PurchaseInvoiceLine."ESD Comment", GlobalValueShouldbeMatch);
        GlobalAssert.AreEqual(GlobalVendor."ESD Comment", PurchaseReceiptLine."ESD Comment", GlobalValueShouldbeMatch);
    end;

    local procedure CheckingPostedComment_Not_TransferPurchase()
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", GlobalPurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.SetRange(Type, "Purchase Line Type"::Item);
        GlobalAssert.RecordCount(PurchaseInvoiceLine, 1);
        PurchaseInvoiceLine.FindFirst();
        PurchaseReceiptLine.SetRange("Document No.", GlobalPurchaseReceiptHeader."No.");
        PurchaseReceiptLine.SetRange(Type, "Purchase Line Type"::Item);
        GlobalAssert.RecordCount(PurchaseReceiptLine, 1);
        PurchaseReceiptLine.FindFirst();
        GlobalAssert.AreNotEqual(GlobalVendor."ESD Comment", PurchaseInvoiceLine."ESD Comment", GlobalValueShouldbeNotMatch);
        GlobalAssert.AreNotEqual(GlobalVendor."ESD Comment", PurchaseReceiptLine."ESD Comment", GlobalValueShouldbeNotMatch);
    end;
}