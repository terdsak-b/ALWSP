codeunit 50101 PostedESDComment
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesLine', '', false, false)]
    local procedure CopyToSalesInvoiceLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean)
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        if SalesLine."ESD Comment" <> '' then begin
            SalesInvLine."ESD Comment" := SalesLine."ESD Comment";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesShptLineInsert', '', false, false)]
    local procedure CopyToSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line")
    begin
        if SalesLine."ESD Comment" <> '' then begin
            SalesShipmentLine."ESD Comment" := SalesLine."ESD Comment";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchLine', '', false, false)]
    local procedure CopyToPurchInvoiceLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        if PurchaseLine."ESD Comment" <> '' then begin
            PurchInvLine."ESD Comment" := PurchaseLine."ESD Comment";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchRcptLineInsert', '', false, false)]
    local procedure CopyToPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine."ESD Comment" <> '' then begin
            PurchRcptLine."ESD Comment" := PurchaseLine."ESD Comment";
        end;
    end;
}
