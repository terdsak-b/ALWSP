codeunit 70001 "WhsePostShipmentEvents"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostSourceHeader', '', false, false)]
    local procedure OnBeforePostSourceDocumentEvent(var WhseShptLine: Record "Warehouse Shipment Line"; GlobalSourceHeader: Variant; WhsePostParameters: Record "Whse. Post Parameters")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Order, WhseShptLine."Source No.");
        if SalesHeader."No." <> '' then
            SalesHeader.TestField("Lookup Value Code");
    end;
}