codeunit 50007 ReplacementItemMgt
{
    procedure ReplaceItemsInSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConfirmMsgPart: Label 'Current item does not have enough stock.\Do you want to replace item %1 to %2 in this sales order?';
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if SalesLine.FindSet() then
            repeat
                if Item.Get(SalesLine."No.") then begin
                    ItemLedgerEntry.SetRange("Item No.", Item."No.");
                    ItemLedgerEntry.CalcSums(Quantity);
                    if (Item."Replacement Item" <> '') and (ItemLedgerEntry.Quantity < SalesLine.Quantity) then
                        if Confirm(StrSubstNo(ConfirmMsgPart, Item."No.", Item."Replacement Item")) then
                            if SalesLine.FindSet(true) then
                                repeat
                                    if Item.Get(SalesLine."No.") then begin
                                        SalesLine."No." := Item."Replacement Item";
                                        SalesLine.Modify();
                                    end;
                                until SalesLine.Next() = 0;
                    SalesHeader.Modify(true);
                end;
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforePostSalesDoc, '', false, false)]
    local procedure OnBeforePostSalesDoc(var Sender: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean; var IsHandled: Boolean; var CalledBy: Integer)
    begin
        ReplaceItemsInSalesOrder(SalesHeader);
    end;
}
