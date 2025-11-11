namespace ALWSP.ALWSP;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Purchases.Document;

codeunit 50009 OrderStatusManagement
{
    procedure UpdatePurchaseLineStatus(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", WarehouseReceiptLine."Source No.");

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

    procedure UpdateSalesLineStatus(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", WarehouseShipmentLine."Source No.");

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

    [EventSubscriber(ObjectType::Page, Page::"Whse. Receipt Subform", OnAfterWhsePostRcptYesNo, '', false, false)]
    local procedure UpdatePurchaseLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        UpdatePurchaseLineStatus(WarehouseReceiptLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", OnAfterCode, '', false, false)]
    local procedure UpdateSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        UpdateSalesLineStatus(WarehouseShipmentLine);
    end;
}
