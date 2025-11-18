codeunit 70002 "WhseCreateSourceDocumentEvents"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", 'OnBeforeWhseShptLineInsert', '', false, false)]
    local procedure OnBeforeCreateShptLineFromSalesLineEvent(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Order, WarehouseShipmentLine."Source No.");
        WarehouseShipmentLine."Lookup Value Code" := SalesHeader."Lookup Value Code";
    end;
}