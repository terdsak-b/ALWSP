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
                        PurchaseLine."Order Status" := PurchaseLine."Order Status"::Completed;
                    PurchaseLine."Quantity Received" > 0:
                        PurchaseLine."Order Status" := PurchaseLine."Order Status"::Partial;
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
                        SalesLine."Order Status" := SalesLine."Order Status"::Completed;
                    SalesLine."Quantity Shipped" > 0:
                        SalesLine."Order Status" := SalesLine."Order Status"::Partial;
                end;
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnAfterRun, '', false, false)]
    local procedure OnAfterRunWhsePostReceipt(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        UpdatePurchaseLineStatus(WarehouseReceiptLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", OnAfterRun, '', false, false)]
    local procedure OnAfterRunWhsePostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PreviewMode: Boolean)
    begin
        UpdateSalesLineStatus(WarehouseShipmentLine);
    end;
}