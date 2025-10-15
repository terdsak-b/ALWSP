codeunit 50100 TransferESDComment
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitHeaderDefaults', '', false, false)]
    local procedure CopyCustomerComments(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        GlobalSalesandReceivableSetup.Get();
        if not Confirm(GlobalConfirmQst) then begin
            GlobalSalesandReceivableSetup."Confirmation for ESD Comment" := false;
            exit;
        end;

        GlobalSalesandReceivableSetup."Confirmation for ESD Comment" := true;
        if not GlobalSalesandReceivableSetup."Confirmation for ESD Comment" then
            exit;

        if not Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        if not Customer."Transfer Comment" then
            exit;

        SalesLine."ESD Comment" := Customer."ESD Comment";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitHeaderDefaults', '', false, false)]
    local procedure CopyVendorComments(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        GlobalSalesandReceivableSetup.Get();
        if not Confirm(GlobalConfirmQst) then begin
            GlobalSalesandReceivableSetup."Confirmation for ESD Comment" := false;
            exit;
        end;

        GlobalSalesandReceivableSetup."Confirmation for ESD Comment" := true;
        if not GlobalSalesandReceivableSetup."Confirmation for ESD Comment" then
            exit;

        if not Vendor.Get(PurchHeader."Buy-from Vendor No.") then
            exit;

        if not Vendor."Transfer Comment" then
            exit;

        PurchLine."ESD Comment" := Vendor."ESD Comment";
    end;

    var
        GlobalConfirmQst: Label 'Do you want to insert the comment Yes/No?';
        GlobalSalesandReceivableSetup: Record "Sales & Receivables Setup";
}
