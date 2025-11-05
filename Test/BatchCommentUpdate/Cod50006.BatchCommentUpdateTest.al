namespace ALWSP.ALWSP;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;

codeunit 50006 "Batch Comment Update Test"
{
    Subtype = Test;

    var
        GlobalBatchCommentUpdateBuffer: Record "Batch Comment Update Buffer";
        GlobalAssert: Codeunit "Assert";
        GlobalESDCommentMsg: Text[100];
        GlobalValueShouldBeMatched: Label 'Value should be matched.';

    [Test]
    procedure "01_Setup_Load_Customers_Into_Buffer"()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO] Load Customers into Batch Comment Update Buffer and customer should be loaded correctly
        Initialize(false);

        // [WHEN] Load Customers
        LoadPersonsIntoBuffer(true);

        // [THEN] Verify that Customers are loaded into the buffer correctly
        VerifyCustomersLoaded();
    end;

    [Test]
    procedure "02_Setup_Load_Vendors_Into_Buffer"()
    var
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Load Vendors into Batch Comment Update Buffer and vendors should be loaded correctly
        Initialize(false);

        // [WHEN] Load Vendors
        LoadPersonsIntoBuffer(false);

        // [THEN] Verify that Vendors are loaded into the buffer correctly
        VerifyVendorsLoaded();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure "03_Create_ESDComment"()
    begin
        // [SCENARIO] Apply changes to create ESD comments to customers and vendors and verify it correctly
        // [GIVEN] Clear ESD comments in customers and vendors and create random ESD comment message
        Initialize(false);

        // [WHEN] Apply changes to customers
        CreateESDCommentToPerson(true, GlobalESDCommentMsg);

        // [THEN] Verify that ESD comments are created correctly
        VerifyESDCommentsCreated();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure "04_Delete_ESDComment"()
    begin
        // [SCENARIO] Delete ESD comments from customers and vendors and verify it correctly
        // [GIVEN] Create ESD comments in customers and vendors
        Initialize(true);

        // [WHEN] Delete ESD comments
        DeleteESDCommentFromPerson();

        // [THEN] Verify that ESD comments are deleted
        VerifyESDCommentsDeleted();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
        // No operation for message handling in tests
    end;

    local procedure Initialize(CreateComments: Boolean)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        LibraryRandom: Codeunit "Library - Random";
    begin
        Clear(GlobalESDCommentMsg);
        GlobalBatchCommentUpdateBuffer.Init();
        GlobalBatchCommentUpdateBuffer.Reset();
        GlobalBatchCommentUpdateBuffer.DeleteAll();

        // Clear ESD comment message from customer and vendor
        if not CreateComments then begin
            if Customer.FindSet(true) then
                repeat
                    Customer."ESD Comment" := '';
                    Customer."Transfer Comment" := false;
                    Customer.Modify();
                until Customer.Next() = 0;

            if Vendor.FindSet(true) then
                repeat
                    Vendor."ESD Comment" := '';
                    Vendor."Transfer Comment" := false;
                    Vendor.Modify();
                until Vendor.Next() = 0;
        end;

        GlobalESDCommentMsg := 'Update Comment: ' + LibraryRandom.RandText(84);

        if CreateComments then begin
            // Create ESD comments for customers and vendors
            if Customer.FindSet() then
                repeat
                    Customer."ESD Comment" := GlobalESDCommentMsg;
                    Customer."Transfer Comment" := true;
                    Customer.Modify(true);
                until Customer.Next() = 0;

            if Vendor.FindSet() then
                repeat
                    Vendor."ESD Comment" := GlobalESDCommentMsg;
                    Vendor."Transfer Comment" := true;
                    Vendor.Modify(true);
                until Vendor.Next() = 0;
        end;
    end;

    local procedure LoadPersonsIntoBuffer(CustorVend: Boolean)
    var
        BatchCommentManagement: Codeunit "Batch Comment Management";
        CommentEntityType: Enum "Comment Entity Type";
    begin
        if CustorVend then begin
            BatchCommentManagement.LoadCustomers(GlobalBatchCommentUpdateBuffer);
        end else begin
            BatchCommentManagement.LoadVendors(GlobalBatchCommentUpdateBuffer);
        end;
    end;

    local procedure VerifyCustomersLoaded()
    var
        Customer: Record Customer;
    begin
        if Customer.FindSet() and GlobalBatchCommentUpdateBuffer.FindSet() then
            repeat
                GlobalAssert.AreEqual(Customer."No.", GlobalBatchCommentUpdateBuffer."Entity No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(Customer.Name, GlobalBatchCommentUpdateBuffer."Entity Name", GlobalValueShouldBeMatched);
            until (Customer.Next() = 0) and (GlobalBatchCommentUpdateBuffer.Next() = 0);
    end;

    local procedure VerifyVendorsLoaded()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.FindSet() and GlobalBatchCommentUpdateBuffer.FindSet() then
            repeat
                GlobalAssert.AreEqual(Vendor."No.", GlobalBatchCommentUpdateBuffer."Entity No.", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(Vendor.Name, GlobalBatchCommentUpdateBuffer."Entity Name", GlobalValueShouldBeMatched);
            until (Vendor.Next() = 0) and (GlobalBatchCommentUpdateBuffer.Next() = 0);
    end;

    local procedure CreateESDCommentToPerson(TransferComment: Boolean; var ESDCommentMsg: Text[100])
    var
        BatchCommentManagement: Codeunit "Batch Comment Management";
    begin
        LoadPersonsIntoBuffer(true);
        LoadPersonsIntoBuffer(false);

        if GlobalBatchCommentUpdateBuffer.FindSet(true) then
            repeat
                GlobalBatchCommentUpdateBuffer."New Comment" := ESDCommentMsg;
                GlobalBatchCommentUpdateBuffer."Transfer Comment" := TransferComment;
                GlobalBatchCommentUpdateBuffer."Status Indicator" := 'M';
                GlobalBatchCommentUpdateBuffer.Modify();
            until GlobalBatchCommentUpdateBuffer.Next() = 0;

        BatchCommentManagement.ApplyBatchUpdate(GlobalBatchCommentUpdateBuffer);
    end;

    local procedure DeleteESDCommentFromPerson()
    var
        BatchCommentManagement: Codeunit "Batch Comment Management";

    begin
        LoadPersonsIntoBuffer(true);
        LoadPersonsIntoBuffer(false);

        if GlobalBatchCommentUpdateBuffer.FindSet() then
            repeat
                BatchCommentManagement.DeleteComment(GlobalBatchCommentUpdateBuffer);
            until GlobalBatchCommentUpdateBuffer.Next() = 0;

    end;

    local procedure VerifyESDCommentsDeleted()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        // Verify Customers
        if Customer.FindSet() then
            repeat
                GlobalAssert.AreEqual('', Customer."ESD Comment", GlobalValueShouldBeMatched);
            until Customer.Next() = 0;

        // Verify Vendors
        if Vendor.FindSet() then
            repeat
                GlobalAssert.AreEqual('', Vendor."ESD Comment", GlobalValueShouldBeMatched);
            until Vendor.Next() = 0;
    end;

    local procedure VerifyESDCommentsCreated()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        // Verify Customers
        if Customer.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalESDCommentMsg, Customer."ESD Comment", GlobalValueShouldBeMatched);
            until Customer.Next() = 0;

        // Verify Vendors
        if Vendor.FindSet() then
            repeat
                GlobalAssert.AreEqual(GlobalESDCommentMsg, Vendor."ESD Comment", GlobalValueShouldBeMatched);
            until Vendor.Next() = 0;
    end;
}