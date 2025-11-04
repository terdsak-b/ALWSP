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
    begin
        if not ConfirmManagement.GetResponseOrDefault(ConfirmMsg, false) then
            exit;

        if BatchCommentUpdateBuffer.FindSet() then
            repeat
                case BatchCommentUpdateBuffer."Entity Type" of
                    BatchCommentUpdateBuffer."Entity Type"::Customer:
                        begin
                            if Customer.Get(BatchCommentUpdateBuffer."Entity No.") then begin
                                if BatchCommentUpdateBuffer."New Comment" <> '' then
                                    Customer."ESD Comment" := BatchCommentUpdateBuffer."New Comment";
                                Customer."Transfer Comment" := BatchCommentUpdateBuffer."Transfer Comment";
                                Customer.Modify(true);
                            end;
                        end;
                    BatchCommentUpdateBuffer."Entity Type"::Vendor:
                        begin
                            if Vendor.Get(BatchCommentUpdateBuffer."Entity No.") then begin
                                if BatchCommentUpdateBuffer."New Comment" <> '' then
                                    Vendor."ESD Comment" := BatchCommentUpdateBuffer."New Comment";
                                Vendor."Transfer Comment" := BatchCommentUpdateBuffer."Transfer Comment";
                                Vendor.Modify(true);
                            end;
                        end;
                end;
            until BatchCommentUpdateBuffer.Next() = 0;
        Message('Batch update completed successfully.');
    end;

    procedure LoadCustomers(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
        EntryNo: Integer;
    begin
        if not BatchCommentUpdateBuffer.IsEmpty then
            BatchCommentUpdateBuffer.FindLast();

        EntryNo := BatchCommentUpdateBuffer."Entry No.";

        if Customer.FindSet() then
            repeat
                // Check if customer already exists in buffer
                BatchCommentUpdateBuffer.SetRange("Entity Type", BatchCommentUpdateBuffer."Entity Type"::Customer);
                BatchCommentUpdateBuffer.SetRange("Entity No.", Customer."No.");
                if BatchCommentUpdateBuffer.IsEmpty then begin
                    EntryNo += 1;
                    BatchCommentUpdateBuffer.Reset();
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entry No." := EntryNo;
                    BatchCommentUpdateBuffer."Entity Type" := BatchCommentUpdateBuffer."Entity Type"::Customer;
                    BatchCommentUpdateBuffer."Entity No." := Customer."No.";
                    BatchCommentUpdateBuffer."Entity Name" := Customer.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Customer."ESD Comment";
                    BatchCommentUpdateBuffer."New Comment" := Customer."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Customer."Transfer Comment";
                    BatchCommentUpdateBuffer.Insert();
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
        Customer.Reset();
        if Customer.FindSet() then
            repeat
                if (Customer."ESD Comment" <> '') or Customer."Transfer Comment" then begin
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entity Type" := BatchCommentUpdateBuffer."Entity Type"::Customer;
                    BatchCommentUpdateBuffer."Entity No." := Customer."No.";
                    BatchCommentUpdateBuffer."Entity Name" := Customer.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Customer."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Customer."Transfer Comment";
                    Clear(BatchCommentUpdateBuffer."New Comment");
                    BatchCommentUpdateBuffer.Insert();
                end;
            until Customer.Next() = 0;

        // Load Vendors with ESD comments
        Vendor.Reset();
        if Vendor.FindSet() then
            repeat
                if (Vendor."ESD Comment" <> '') or Vendor."Transfer Comment" then begin
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entity Type" := BatchCommentUpdateBuffer."Entity Type"::Vendor;
                    BatchCommentUpdateBuffer."Entity No." := Vendor."No.";
                    BatchCommentUpdateBuffer."Entity Name" := Vendor.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Vendor."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Vendor."Transfer Comment";
                    Clear(BatchCommentUpdateBuffer."New Comment");
                    BatchCommentUpdateBuffer.Insert();
                end;
            until Vendor.Next() = 0;
    end;

    procedure LoadVendors(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Vendor: Record Vendor;
        EntryNo: Integer;
    begin
        if not BatchCommentUpdateBuffer.IsEmpty then
            BatchCommentUpdateBuffer.FindLast();

        EntryNo := BatchCommentUpdateBuffer."Entry No.";

        if Vendor.FindSet() then
            repeat
                // Check if vendor already exists in buffer
                BatchCommentUpdateBuffer.SetRange("Entity Type", BatchCommentUpdateBuffer."Entity Type"::Vendor);
                BatchCommentUpdateBuffer.SetRange("Entity No.", Vendor."No.");
                if BatchCommentUpdateBuffer.IsEmpty then begin
                    EntryNo += 1;
                    BatchCommentUpdateBuffer.Reset();
                    BatchCommentUpdateBuffer.Init();
                    BatchCommentUpdateBuffer."Entry No." := EntryNo;
                    BatchCommentUpdateBuffer."Entity Type" := BatchCommentUpdateBuffer."Entity Type"::Vendor;
                    BatchCommentUpdateBuffer."Entity No." := Vendor."No.";
                    BatchCommentUpdateBuffer."Entity Name" := Vendor.Name;
                    BatchCommentUpdateBuffer."Old Comment" := Vendor."ESD Comment";
                    BatchCommentUpdateBuffer."New Comment" := Vendor."ESD Comment";
                    BatchCommentUpdateBuffer."Transfer Comment" := Vendor."Transfer Comment";
                    BatchCommentUpdateBuffer.Insert();
                end;
                BatchCommentUpdateBuffer.Reset();
            until Vendor.Next() = 0;
    end;

    procedure DeleteComment(var BatchCommentUpdateBuffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmMsg: Label 'Are you sure you want to delete the comments for the selected entities?';
    begin
        if not ConfirmManagement.GetResponseOrDefault(ConfirmMsg, false) then
            exit;

        if BatchCommentUpdateBuffer.FindSet() then
            repeat
                case BatchCommentUpdateBuffer."Entity Type" of
                    BatchCommentUpdateBuffer."Entity Type"::Customer:
                        begin
                            if Customer.Get(BatchCommentUpdateBuffer."Entity No.") then begin
                                Customer."ESD Comment" := '';
                                Customer."Transfer Comment" := false;
                                Customer.Modify(true);
                            end;
                        end;
                    BatchCommentUpdateBuffer."Entity Type"::Vendor:
                        begin
                            if Vendor.Get(BatchCommentUpdateBuffer."Entity No.") then begin

                                Vendor."ESD Comment" := '';
                                Vendor."Transfer Comment" := false;
                                Vendor.Modify(true);
                            end;
                        end;
                end;
                BatchCommentUpdateBuffer.Delete();
            until BatchCommentUpdateBuffer.Next() = 0;
    end;
}
