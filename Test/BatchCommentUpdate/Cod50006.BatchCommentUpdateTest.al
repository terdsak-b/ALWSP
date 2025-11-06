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
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure "01_Create_ESDCommentToCustomerAndVendor"()
    begin
        // [SCENARIO] Apply changes to create ESD comments to customers and vendors and verify it correctly
        // [GIVEN] Clear ESD comments in customers and vendors and create random ESD comment message
        Initialize(false);

        // [WHEN] Apply changes to customers
        CreateESDCommentToPerson(true, GlobalESDCommentMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure "02_Check_ESDComment_CreatedOnCustomerAndVendor"()
    begin
        // [SCENARIO] Create and Delete ESD comments from customers and vendors and verify it correctly
        // [GIVEN] Clear ESD comments in customers and vendors and create random ESD comment message
        Initialize(false);

        // [WHEN] Create and Delete ESD comments
        CreateESDCommentToPerson(true, GlobalESDCommentMsg);

        // [THEN] Verify that ESD comments are deleted
        VerifyESDCommentsCreated();
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