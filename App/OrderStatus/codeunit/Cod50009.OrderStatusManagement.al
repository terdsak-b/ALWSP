codeunit 50009 OrderStatusManagement
{

    local procedure UpdatePurchaseLineStatus(var PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine.FindSet(true) then
            repeat
                case true of
                    PurchaseLine."Quantity Received" = PurchaseLine.Quantity:
                        PurchaseLine.Validate("Order Status", "Order Status"::Completed);
                    PurchaseLine."Quantity Received" > 0:
                        PurchaseLine.Validate("Order Status", "Order Status"::Partial);
                end;

                PurchaseLine.Modify();
            until PurchaseLine.Next() = 0;
    end;

    local procedure UpdatePurchaseLineStatusWithPostedReceipt(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        UpdatePurchaseLineStatus(PurchaseLine);
    end;

    local procedure UpdatePurchaseLineStatusWithWarehouseReceipt(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", WarehouseReceiptLine."Source No.");
        UpdatePurchaseLineStatus(PurchaseLine);
    end;

    local procedure UpdateSalesLineStatus(var SalesLine: Record "Sales Line")
    begin
        if SalesLine.FindSet(true) then
            repeat
                case true of
                    SalesLine."Quantity Shipped" = SalesLine.Quantity:
                        SalesLine.Validate("Order Status", "Order Status"::Completed);
                    SalesLine."Quantity Shipped" > 0:
                        SalesLine.Validate("Order Status", "Order Status"::Partial);
                end;

                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    local procedure UpdateSalesLineStatusWithPostedShipment(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        UpdateSalesLineStatus(SalesLine);
    end;

    local procedure UpdateSalesLineStatusWithWarehouseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", WarehouseShipmentLine."Source No.");
        UpdateSalesLineStatus(SalesLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterPostPurchaseDoc, '', false, false)]
    local procedure OnAfterPostPurchase(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    begin
        UpdatePurchaseLineStatusWithPostedReceipt(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterPostSalesDoc, '', false, false)]
    local procedure OnAfterPostSales(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    begin
        UpdateSalesLineStatusWithPostedShipment(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnAfterRun, '', false, false)]
    local procedure OnAfterRunWhsePostReceipt(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        UpdatePurchaseLineStatusWithWarehouseReceipt(WarehouseReceiptLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", OnAfterRun, '', false, false)]
    local procedure OnAfterRunWhsePostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; PreviewMode: Boolean)
    begin
        UpdateSalesLineStatusWithWarehouseShipment(WarehouseShipmentLine);
    end;
}