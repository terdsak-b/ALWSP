namespace ALWSP.ALWSP;
using Microsoft.Sales.Customer;
using System.Utilities;
using Microsoft.Purchases.Vendor;

codeunit 50005 "Batch Comment Management"
{
    procedure ApplyBatchUpdate(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmMsg: Label 'Are you sure you want to apply the batch comment updates?';
        NotChangesMsg: Label 'Comment are the same as before.';
        SuccessMsg: Label 'Batch update completed successfully.';
        NoModificationsMsg: Label 'No modifications found in the selected records.';
    begin
        if BatchCommentUpdateBuffer."Status Indicator" = '' then begin
            Message(NoModificationsMsg);
            exit;
        end;

        if BatchCommentUpdateBuffer."New Comment" = BatchCommentUpdateBuffer."Old Comment" then begin
            Message(NotChangesMsg);
        end;

        if not ConfirmManagement.GetResponseOrDefault(ConfirmMsg, false) then
            exit;

        if BatchCommentUpdateBuffer.FindSet() then
            repeat
                case BatchCommentUpdateBuffer."Entity Type" of
                    BatchCommentUpdateBuffer."Entity Type"::Customer:
                        begin
                            if Customer.Get(BatchCommentUpdateBuffer."Entity No.") then begin
                                if BatchCommentUpdateBuffer."New Comment" <> '' then
                                    Customer.Validate("ESD Comment", BatchCommentUpdateBuffer."New Comment");
                                Customer.Validate("Transfer Comment", BatchCommentUpdateBuffer."Transfer Comment");
                                Customer.Modify(true);
                            end;
                        end;
                    BatchCommentUpdateBuffer."Entity Type"::Vendor:
                        begin
                            if Vendor.Get(BatchCommentUpdateBuffer."Entity No.") then begin
                                if BatchCommentUpdateBuffer."New Comment" <> '' then
                                    Vendor.Validate("ESD Comment", BatchCommentUpdateBuffer."New Comment");
                                Vendor.Validate("Transfer Comment", BatchCommentUpdateBuffer."Transfer Comment");
                                Vendor.Modify(true);
                            end;
                        end;
                end;

            until BatchCommentUpdateBuffer.Next() = 0;
        LoadDefaultRecords(BatchCommentUpdateBuffer);
        Message(SuccessMsg);
    end;

    procedure ClearStatusIndicators(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    begin
        if BatchCommentUpdateBuffer.FindSet(true) then
            repeat
                BatchCommentUpdateBuffer.Modified := false;
                BatchCommentUpdateBuffer.CalcFields();
                BatchCommentUpdateBuffer.Modify();
            until BatchCommentUpdateBuffer.Next() = 0;
    end;

    procedure DeleteComment(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmMsg: Label 'Are you sure you want to delete the comments for the selected entities?';
        NoCommentsMsg: Label 'No comments to delete.';
        DeletedMsg: Label 'Comments deleted successfully.';
    begin
        if BatchCommentUpdateBuffer.IsEmpty or (BatchCommentUpdateBuffer."Old Comment" = '') then begin
            Message(NoCommentsMsg);
            exit;
        end;

        if not ConfirmManagement.GetResponseOrDefault(ConfirmMsg, false) then
            exit;

        if BatchCommentUpdateBuffer.FindSet() then
            repeat
                case BatchCommentUpdateBuffer."Entity Type" of
                    BatchCommentUpdateBuffer."Entity Type"::Customer:
                        begin
                            if Customer.Get(BatchCommentUpdateBuffer."Entity No.") then begin
                                Customer.Validate("ESD Comment", '');
                                Customer.Validate("Transfer Comment", false);
                                Customer.Modify(true);
                            end;
                        end;
                    BatchCommentUpdateBuffer."Entity Type"::Vendor:
                        begin
                            if Vendor.Get(BatchCommentUpdateBuffer."Entity No.") then begin

                                Vendor.Validate("ESD Comment", '');
                                Vendor.Validate("Transfer Comment", false);
                                Vendor.Modify(true);
                            end;
                        end;
                end;
                BatchCommentUpdateBuffer.Delete();
            until BatchCommentUpdateBuffer.Next() = 0;
        LoadDefaultRecords(BatchCommentUpdateBuffer);
        Message(DeletedMsg);
    end;

    procedure LoadCustomers(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
    begin
        if not BatchCommentUpdateBuffer.IsEmpty then
            BatchCommentUpdateBuffer.FindLast();
        if Customer.FindSet() then
            repeat
                // Check if customer already exists in buffer
                BatchCommentUpdateBuffer.SetRange("Entity Type", BatchCommentUpdateBuffer."Entity Type"::Customer);
                BatchCommentUpdateBuffer.SetRange("Entity No.", Customer."No.");
                if BatchCommentUpdateBuffer.IsEmpty then begin
                    BatchCommentUpdateBuffer.Reset();
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entry No." += 1;
                    BatchCommentUpdateBuffer."Entity Type" := BatchCommentUpdateBuffer."Entity Type"::Customer;
                    BatchCommentUpdateBuffer."Entity No." := Customer."No.";
                    BatchCommentUpdateBuffer.Insert(true);
                    BatchCommentUpdateBuffer."Entity Name" := Customer.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Customer."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Customer."Transfer Comment";
                    BatchCommentUpdateBuffer.Modify(true);
                end;
                BatchCommentUpdateBuffer.Reset();
            until Customer.Next() = 0;
    end;

    procedure LoadDefaultRecords(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        BatchCommentUpdateBuffer.Reset();
        BatchCommentUpdateBuffer.DeleteAll();

        // Load Customers with ESD comments
        if Customer.FindSet() then
            repeat
                if (Customer."ESD Comment" <> '') or Customer."Transfer Comment" then begin
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entry No." += 1;
                    BatchCommentUpdateBuffer."Entity Type" := "Comment Entity Type"::Customer;
                    BatchCommentUpdateBuffer."Entity No." := Customer."No.";
                    BatchCommentUpdateBuffer.Insert(true);
                    BatchCommentUpdateBuffer."Entity Name" := Customer.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Customer."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Customer."Transfer Comment";
                    Clear(BatchCommentUpdateBuffer."New Comment");
                    BatchCommentUpdateBuffer.Modify(true);
                end;
            until Customer.Next() = 0;

        // Load Vendors with ESD comments
        if Vendor.FindSet() then
            repeat
                if (Vendor."ESD Comment" <> '') or Vendor."Transfer Comment" then begin
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entry No." += 1;
                    BatchCommentUpdateBuffer."Entity Type" := "Comment Entity Type"::Vendor;
                    BatchCommentUpdateBuffer."Entity No." := Vendor."No.";
                    BatchCommentUpdateBuffer.Insert(true);
                    BatchCommentUpdateBuffer."Entity Name" := Vendor.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Vendor."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Vendor."Transfer Comment";
                    Clear(BatchCommentUpdateBuffer."New Comment");
                    BatchCommentUpdateBuffer.Modify(true);
                end;
            until Vendor.Next() = 0;
    end;

    procedure LoadVendors(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Vendor: Record Vendor;
    begin
        if not BatchCommentUpdateBuffer.IsEmpty then
            BatchCommentUpdateBuffer.FindLast();
        if Vendor.FindSet() then
            repeat
                // Check if vendor already exists in buffer
                BatchCommentUpdateBuffer.SetRange("Entity Type", BatchCommentUpdateBuffer."Entity Type"::Vendor);
                BatchCommentUpdateBuffer.SetRange("Entity No.", Vendor."No.");
                if BatchCommentUpdateBuffer.IsEmpty then begin
                    BatchCommentUpdateBuffer.Reset();
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entry No." += 1;
                    BatchCommentUpdateBuffer."Entity Type" := BatchCommentUpdateBuffer."Entity Type"::Vendor;
                    BatchCommentUpdateBuffer."Entity No." := Vendor."No.";
                    BatchCommentUpdateBuffer.Insert(true);
                    BatchCommentUpdateBuffer."Entity Name" := Vendor.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Vendor."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Vendor."Transfer Comment";
                    BatchCommentUpdateBuffer.Modify(true);
                end;
                BatchCommentUpdateBuffer.Reset();
            until Vendor.Next() = 0;
    end;
}
