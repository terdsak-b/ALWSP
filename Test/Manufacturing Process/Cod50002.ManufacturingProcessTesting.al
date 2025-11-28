codeunit 50002 "Manufacturing Process Testing"
{
    Subtype = Test;

    var
        GlobalItem: Record Item;
        GlobalAssert: Codeunit Assert;
        GlobalNegativeQty: Integer;
        GlobalQty: Integer;
        GlobalExpectedConfirm: Text;
        GlobalValueShouldBeMatch: Label 'Value should be matched';

    [Test]
    [HandlerFunctions('ConfirmHandler,ModalPageHandler')]
    procedure "01__CreateSingleProductionOrderAndVerify"()
    begin
        // [SCENARIO] Create Production Order from Item
        Initialize();

        // [GIVEN] Item with required manufacturing process setup exists
        CreateItemWithItemBOM();

        // [WHEN] Create Production Order from Item
        CreateProductionOrder(1);

        // [THEN] Verify item was created with correct setup
        CheckProductionOrderCreatedCorrectly();
    end;

    [Test]
    procedure "02__CreateProductionOrderWithQuantityLessThanZeroAndVerifyError"()
    var
        ErrorMessage: Label 'Production Quantity cannot be less than 0.';
    begin
        // [SCENARIO] Create Production Order with negative quantity and verify error is raised
        Initialize();

        // [GIVEN] Initialize a Quantity and setup test items
        CreateItemWithItemBOM();

        // [WHEN] Create Production Orders for all items on the page and set negative production quantity
        CreateProductionOrder(2);

        // [THEN] Validation error is raised for negative production quantity 
        GlobalAssert.ExpectedError(ErrorMessage);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
        if GlobalExpectedConfirm = '' then
            exit;

        if not Question.Contains(':') then
            exit;

        GlobalAssert.ExpectedConfirm(GlobalExpectedConfirm, Question);
    end;

    [ModalPageHandler]
    procedure ModalPageHandler(var ProdOrderPage: TestPage "Production Order List")
    begin
    end;

    local procedure CreateItemWithItemBOM(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryInventory.CreateItem(GlobalItem);
        GlobalItem.Validate("Replenishment System", "Replenishment System"::"Prod. Order");
        GlobalItem.Validate("Manufacturing Policy", "Manufacturing Policy"::"Make-to-Order");
        GlobalItem.Validate("Reordering Policy", "Reordering Policy"::Order);
        GlobalItem.Modify();

        LibraryManufacturing.CreateRouting(RoutingHeader, GlobalItem, '', 0.00);
        RoutingHeader.Get(GlobalItem."Routing No.");
        RoutingHeader.Validate(Status, "Routing Status"::New);
        RoutingHeader.Rename(GlobalItem."No.");
        RoutingHeader.Validate(Status, "Routing Status"::Certified);
        RoutingHeader.Modify();

        GlobalItem.Validate("Routing No.", GlobalItem."No.");
        GlobalItem.Modify();
        LibraryManufacturing.CreateProductionBOM(GlobalItem, 3);

        exit(GlobalItem."No.");
    end;

    local procedure CreateProductionOrder(CaseNumber: Integer)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        NoSeries: Codeunit "No. Series";
        ExpectedProdOrderNo: Code[20];
        ProdOrderMessageSinglePart: Label 'Created production order: %1\Do you want to view the created production orders?';
        ProdOrderMessageMultiPart: Label 'Created production orders: %1..%2\Do you want to view the created production orders?';
        ManufacturingItems: TestPage "Manufacturing Items";
    begin
        ManufacturingItems.OpenEdit();


        case CaseNumber of
            1:
                begin
                    ManufacturingItems.GoToRecord(GlobalItem);
                    ManufacturingItems."Production Quantity".SetValue(GlobalQty);
                    ManufacturingItems.CreateSelectProductionOrder.Invoke();

                    ManufacturingSetup.Get();
                    ExpectedProdOrderNo := IncStr(NoSeries.GetLastNoUsed(ManufacturingSetup."Released Order Nos."));
                    GlobalExpectedConfirm := StrSubstNo(ProdOrderMessageSinglePart, ExpectedProdOrderNo);
                end;
            2:
                begin
                    ManufacturingItems.GoToRecord(GlobalItem);

                    Commit();

                    asserterror ManufacturingItems."Production Quantity".SetValue(GlobalNegativeQty);
                    ManufacturingItems.Close();
                end;

        end;

    end;

    local procedure Initialize()
    begin
        GlobalQty := 3;
        GlobalNegativeQty := -1;
    end;

    local procedure CheckProductionOrderCreatedCorrectly()
    var
        ProdOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
        CalculatedExpectedQty: Decimal;
    begin
        GlobalAssert.AreEqual("Manufacturing Policy"::"Make-to-Order", GlobalItem."Manufacturing Policy", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual("Replenishment System"::"Prod. Order", GlobalItem."Replenishment System", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual("Reordering Policy"::Order, GlobalItem."Reordering Policy", GlobalValueShouldBeMatch);

        ProdOrder.SetCurrentKey("Source No.", "Source Type");
        ProdOrder.SetRange("Source No.", GlobalItem."No.");
        ProdOrder.SetRange("Source Type", "Prod. Order Source Type"::Item);
        ProdOrder.SetRange(Status, "Production Order Status"::Released);
        GlobalAssert.RecordCount(ProdOrder, 1);
        ProdOrder.FindFirst();
        GlobalAssert.AreEqual(GlobalItem."No.", ProdOrder."Source No.", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(GlobalQty, ProdOrder.Quantity, GlobalValueShouldBeMatch);

        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        GlobalAssert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.FindFirst();
        GlobalAssert.AreEqual(GlobalItem."No.", ProdOrderLine."Item No.", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(GlobalQty, ProdOrderLine.Quantity, GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(GlobalItem."Routing No.", ProdOrderLine."Routing No.", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(GlobalItem."Production BOM No.", ProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);

        RoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        GlobalAssert.RecordCount(RoutingLine, 1);
        RoutingLine.FindFirst();
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrder."Routing No.");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        GlobalAssert.RecordCount(ProdOrderRoutingLine, 1);
        ProdOrderRoutingLine.FindFirst();
        GlobalAssert.AreEqual(GlobalItem."Routing No.", ProdOrder."Routing No.", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(ProdOrderRoutingLine."Operation No.", RoutingLine."Operation No.", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(ProdOrderRoutingLine.Type, RoutingLine.Type, GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(ProdOrderRoutingLine."Setup Time", RoutingLine."Setup Time", GlobalValueShouldBeMatch);
        GlobalAssert.AreEqual(ProdOrderRoutingLine."Run Time", RoutingLine."Run Time", GlobalValueShouldBeMatch);

        ProductionBOMLine.SetRange("Production BOM No.", GlobalItem."Production BOM No.");
        GlobalAssert.RecordCount(ProductionBOMLine, 3);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        GlobalAssert.RecordCount(ProdOrderComponent, 3);
        GlobalAssert.AreEqual(GlobalItem."Production BOM No.", ProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);
        if ProdOrderComponent.FindSet() and ProductionBOMLine.FindSet() then
            repeat
                CalculatedExpectedQty := ProdOrderComponent."Quantity per" * ProdOrderLine.Quantity;
                GlobalAssert.AreEqual(ProdOrderComponent."Item No.", ProductionBOMLine."No.", GlobalValueShouldBeMatch);
                GlobalAssert.AreEqual(ProdOrderComponent.Quantity, ProductionBOMLine.Quantity, GlobalValueShouldBeMatch);
                GlobalAssert.AreEqual(CalculatedExpectedQty, ProdOrderComponent."Expected Quantity", GlobalValueShouldBeMatch);
            until (ProdOrderComponent.Next() = 0) and (ProductionBOMLine.Next() = 0);
    end;
}
