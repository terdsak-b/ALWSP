namespace ALWSP.ALWSP;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Document;

codeunit 50009 OrderStatusManegement
{
    procedure UpdatePurchaseLineStatus(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");

        if PurchaseLine.FindSet(true) then
            repeat
                case true of
                    PurchaseLine."Quantity Received" = PurchaseLine.Quantity:
                        PurchaseLine.Status := PurchaseLine.Status::Completed;
                    PurchaseLine."Quantity Received" > 0:
                        PurchaseLine.Status := PurchaseLine.Status::Partial;
                end;
                PurchaseLine.Modify();
            until PurchaseLine.Next() = 0;
    end;

    procedure UpdateSalesLineStatus(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if SalesLine.FindSet(true) then
            repeat
                case true of
                    SalesLine."Quantity Shipped" = SalesLine.Quantity:
                        SalesLine.Status := SalesLine.Status::Completed;
                    SalesLine."Quantity Shipped" > 0:
                        SalesLine.Status := SalesLine.Status::Partial;
                end;
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", OnAfterPost, '', false, false)]
    local procedure UpdatePurchaseLine(var PurchaseHeader: Record "Purchase Header")
    begin
        UpdatePurchaseLineStatus(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", OnAfterPost, '', false, false)]
    local procedure UpdateSalesLine(var SalesHeader: Record "Sales Header"; PostAndSend: Boolean)
    begin
        UpdateSalesLineStatus(SalesHeader);
    end;
}
