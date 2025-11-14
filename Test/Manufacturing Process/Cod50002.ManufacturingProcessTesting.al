namespace ALWSP.ALWSP;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

codeunit 50002 "Manufacturing Process Testing"
{
    Subtype = Test;

    var
        GlobalItem: Record Item;
        GlobalItemTemp: Record Item temporary;
        GlobalAssert: Codeunit Assert;
        GlobalLibraryRandom: Codeunit "Library - Random";
        GlobalCreateProdOrder: Codeunit CreateProdOrder;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        GlobalValueShouldBeMatch: Label 'Value should be matched';
        GlobalErrorMsg: Label 'No items found for testing. Please ensure there are items set up with the required manufacturing process settings.';
        GlobalQty: Integer;
        GlobalNegativeQty: Integer;

    local procedure Initialize()
    begin
        GlobalQty := GlobalLibraryRandom.RandDecInDecimalRange(1, 10, 0);
        GlobalNegativeQty := -1;

        SetupItemNumberFilter();
    end;

    [Test]
    [HandlerFunctions('CreateAndNavConfirmHandler,VerifyNavtoProdOrderPageHandler')]
    procedure CreateProductionOrderSelectionTest()
    var
        ManufacturingPage: TestPage "Manufacturing Items";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLine: Record "Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMLine: Record "Production BOM Line";
        CalculatedExpectedQty: Decimal;
        BaseExpectedQty: Decimal;
    begin
        // [GIVEN] Initialize Quantity and setup test items
        Initialize();

        if GlobalItemTemp.FindFirst() then begin
            NegativeQtyInsert();
            GlobalItem.Get(GlobalItemTemp."No.");
            GlobalItem.FindFirst();
            // [WHEN] Open Manufacturing Item page and create new item and Create Production Order from Item
            ManufacturingPage.OpenEdit();
            ManufacturingPage.GoToRecord(GlobalItem);
            ManufacturingPage."Production Quantity".SetValue(GlobalQty);
            ManufacturingPage.GoToRecord(GlobalItem);
            ManufacturingPage.CreateSelectProductionOrder.Invoke();
            // Page close by currpage.close in the action

            // [THEN] Verify item was created with correct setup
            GlobalItem.Get(GlobalItemTemp."No.");
            //GlobalAssert.AreEqual(GlobalQty, GlobalItem."Production Quantity", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Manufacturing Policy"::"Make-to-Order", GlobalItem."Manufacturing Policy", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Replenishment System"::"Prod. Order", GlobalItem."Replenishment System", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Reordering Policy"::Order, GlobalItem."Reordering Policy", GlobalValueShouldBeMatch);

            ProdOrder.SetRange("Source No.", GlobalItem."No.");
            ProdOrder.SetRange("Source Type", ProdOrder."Source Type"::Item);
            ProdOrder.SetRange(Status, ProdOrder.Status::Released);
            ProdOrder.FindLast();
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderLine.FindLast();
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderLine.FindLast();
            ProdOrderRoutingLine.SetRange("Routing No.", ProdOrder."Routing No.");
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
            RoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
            ProductionBOMLine.SetRange("Production BOM No.", GlobalItem."Production BOM No.");

            // Verify Production Order 
            GlobalAssert.AreEqual(GlobalItem."No.", ProdOrder."Source No.", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalQty, ProdOrder.Quantity, GlobalValueShouldBeMatch);

            GlobalAssert.AreEqual(GlobalItem."Routing No.", ProdOrder."Routing No.", GlobalValueShouldBeMatch);
            if ProdOrderRoutingLine.FindSet() and RoutingLine.FindSet() then begin
                repeat
                    GlobalAssert.AreEqual(ProdOrderRoutingLine."Operation No.", RoutingLine."Operation No.", GlobalValueShouldBeMatch);
                    GlobalAssert.AreEqual(ProdOrderRoutingLine.Type, RoutingLine.Type, GlobalValueShouldBeMatch);
                    GlobalAssert.AreEqual(ProdOrderRoutingLine."Setup Time", RoutingLine."Setup Time", GlobalValueShouldBeMatch);
                    GlobalAssert.AreEqual(ProdOrderRoutingLine."Run Time", RoutingLine."Run Time", GlobalValueShouldBeMatch);
                until (ProdOrderRoutingLine.Next() = 0) and (RoutingLine.Next() = 0);
            end;

            GlobalAssert.AreEqual(GlobalItem."Production BOM No.", ProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);
            if ProdOrderComponent.FindSet() and ProductionBOMLine.FindSet() then
                repeat
                    GlobalAssert.AreEqual(ProdOrderComponent."Item No.", ProductionBOMLine."No.", GlobalValueShouldBeMatch);
                    GlobalAssert.AreEqual(ProdOrderComponent.Quantity, ProductionBOMLine.Quantity, GlobalValueShouldBeMatch);

                until (ProdOrderComponent.Next() = 0) and (ProductionBOMLine.Next() = 0);

            // [THEN] Verify Calculation Formula field is set
            // When Calculation Formula = "Fixed Quantity", the quantity is fixed regardless of parent quantity
            if ProdOrderComponent."Calculation Formula" = ProdOrderComponent."Calculation Formula"::" " then begin
                // Standard calculation: Quantity per × Production Order Line Quantity
                BaseExpectedQty := ProdOrderComponent."Quantity per" * ProdOrderLine.Quantity;

                // Expected Quantity includes scrap (if any)
                // Formula: Quantity per × Prod Order Qty × (1 + Scrap %/100)
                if ProdOrderComponent."Scrap %" > 0 then begin
                    CalculatedExpectedQty := BaseExpectedQty * (1 + ProdOrderComponent."Scrap %" / 100);
                    GlobalAssert.IsTrue(
                        Abs(ProdOrderComponent."Expected Quantity" - CalculatedExpectedQty) < 0.01,
                        StrSubstNo('Expected Quantity (%1) should include scrap calculation (%2) for item %3',
                            ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                    );

                    GlobalAssert.AreEqual(
                        CalculatedExpectedQty,
                        ProdOrderComponent."Expected Quantity",
                        StrSubstNo('Expected Quantity (%1) should equal scrap calculation (%2) for item %3',
                            ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                    );
                end else begin
                    // No scrap, should be close to base calculation (allowing for rounding)
                    GlobalAssert.IsTrue(
                        Abs(ProdOrderComponent."Expected Quantity" - BaseExpectedQty) < 1,
                        StrSubstNo('Expected Quantity (%1) should approximate base calculation (%2) for item %3',
                            ProdOrderComponent."Expected Quantity", BaseExpectedQty, ProdOrderComponent."Item No.")
                    );

                    GlobalAssert.AreEqual(
                        BaseExpectedQty,
                        ProdOrderComponent."Expected Quantity",
                        StrSubstNo('Expected Quantity (%1) should equal base calculation (%2) for item %3',
                            ProdOrderComponent."Expected Quantity", BaseExpectedQty, ProdOrderComponent."Item No.")
                    );
                end;
            end else if ProdOrderComponent."Calculation Formula" = ProdOrderComponent."Calculation Formula"::"Fixed Quantity" then begin
                // Fixed Quantity formula: Expected Quantity = Quantity (fixed value)
                BaseExpectedQty := ProdOrderComponent."Quantity";

                // Expected Quantity includes scrap (if any)
                // Formula: Quantity per × Prod Order Qty × (1 + Scrap %/100)
                if ProdOrderComponent."Scrap %" > 0 then begin
                    CalculatedExpectedQty := BaseExpectedQty * (1 + ProdOrderComponent."Scrap %" / 100);
                    GlobalAssert.IsTrue(
                        Abs(ProdOrderComponent."Expected Quantity" - CalculatedExpectedQty) < 0.01,
                        StrSubstNo('Expected Quantity (%1) should include scrap calculation (%2) for item %3',
                            ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                    );

                    GlobalAssert.AreEqual(
                        CalculatedExpectedQty,
                        ProdOrderComponent."Expected Quantity",
                        StrSubstNo('Expected Quantity (%1) should equal scrap calculation (%2) for item %3',
                            ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                    );
                end else begin

                    // [THEN] When Calculation Formula = "Fixed Quantity", Expected Quantity = Quantity (fixed value)
                    // It should NOT multiply by Production Order Line Quantity
                    GlobalAssert.AreEqual(
                        BaseExpectedQty,
                        ProdOrderComponent."Expected Quantity",
                        StrSubstNo('Expected Quantity (%1) should equal fixed Quantity (%2) for item %3 with Fixed Quantity formula',
                            ProdOrderComponent."Expected Quantity", BaseExpectedQty, ProdOrderComponent."Item No.")
                    );

                    // Verify it's not multiplied by production order quantity
                    GlobalAssert.AreNotEqual(
                        ProdOrderComponent."Quantity per" * ProdOrderLine.Quantity,
                        ProdOrderComponent."Expected Quantity",
                        StrSubstNo('Fixed Quantity should not be multiplied by order quantity for item %1', ProdOrderComponent."Item No.")
                    );
                end;
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('CreateAndNavConfirmHandler,VerifyNavtoProdOrderPageHandler')]
    procedure CreateProductionOrderAllTest()
    var
        ManufacturingPage: TestPage "Manufacturing Items";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLine: Record "Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMLine: Record "Production BOM Line";
        CalculatedExpectedQty: Decimal;
        BaseExpectedQty: Decimal;
    begin
        // [GIVEN] Initialize a Quantity and setup test items
        Initialize();

        // [WHEN] Create Production Order from Item
        ManufacturingPage.OpenEdit();
        if GlobalItemTemp.FindSet() then begin
            repeat
                NegativeQtyInsert();
                GlobalItem.SetRange("No.", GlobalItemTemp."No.");
                if GlobalItem.FindSet() then begin
                    ManufacturingPage.GoToRecord(GlobalItem);
                    ManufacturingPage."Production Quantity".SetValue(GlobalQty);
                end;
            until GlobalItemTemp.Next() = 0;
        end;
        ManufacturingPage.CreateAllProductionOrder.Invoke();
        // Page close by currpage.close in the action

        if GlobalItemTemp.Findset() then begin

            repeat
                GlobalItem.SetRange("No.", GlobalItemTemp."No.");
                GlobalItem.Get(GlobalItem."No.");
                // [THEN] Verify item was created with correct setup 
                //GlobalAssert.AreEqual(GlobalQty, GlobalItem."Production Quantity", GlobalValueShouldBeMatch);
                GlobalAssert.AreEqual(GlobalItem."Manufacturing Policy"::"Make-to-Order", GlobalItem."Manufacturing Policy", GlobalValueShouldBeMatch);
                GlobalAssert.AreEqual(GlobalItem."Replenishment System"::"Prod. Order", GlobalItem."Replenishment System", GlobalValueShouldBeMatch);
                GlobalAssert.AreEqual(GlobalItem."Reordering Policy"::Order, GlobalItem."Reordering Policy", GlobalValueShouldBeMatch);

                ProdOrder.SetRange("Source No.", GlobalItem."No.");
                ProdOrder.SetRange("Source Type", ProdOrder."Source Type"::Item);
                ProdOrder.SetRange(Status, ProdOrder.Status::Released);
                ProdOrder.FindLast();
                ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
                ProdOrderLine.FindLast();
                ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
                ProdOrderLine.FindLast();
                ProdOrderRoutingLine.SetRange("Routing No.", ProdOrder."Routing No.");
                ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
                RoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
                ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
                ProductionBOMLine.SetRange("Production BOM No.", GlobalItem."Production BOM No.");

                // // Verify Production Order
                GlobalAssert.AreEqual(GlobalItem."No.", ProdOrder."Source No.", GlobalValueShouldBeMatch);
                GlobalAssert.AreEqual(GlobalQty, ProdOrder.Quantity, GlobalValueShouldBeMatch);

                GlobalAssert.AreEqual(GlobalItem."Routing No.", ProdOrder."Routing No.", GlobalValueShouldBeMatch);
                if ProdOrderRoutingLine.FindSet() and RoutingLine.FindSet() then begin
                    repeat
                        GlobalAssert.AreEqual(ProdOrderRoutingLine."Operation No.", RoutingLine."Operation No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(ProdOrderRoutingLine.Type, RoutingLine.Type, GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(ProdOrderRoutingLine."Setup Time", RoutingLine."Setup Time", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(ProdOrderRoutingLine."Run Time", RoutingLine."Run Time", GlobalValueShouldBeMatch);
                    until (ProdOrderRoutingLine.Next() = 0) and (RoutingLine.Next() = 0);
                end;

                GlobalAssert.AreEqual(GlobalItem."Production BOM No.", ProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);
                if ProdOrderComponent.FindSet() and ProductionBOMLine.FindSet() then
                    repeat
                        GlobalAssert.AreEqual(ProdOrderComponent."Item No.", ProductionBOMLine."No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(ProdOrderComponent.Quantity, ProductionBOMLine.Quantity, GlobalValueShouldBeMatch);

                    until (ProdOrderComponent.Next() = 0) and (ProductionBOMLine.Next() = 0);

                // [THEN] Verify Calculation Formula field is set
                // When Calculation Formula = "Fixed Quantity", the quantity is fixed regardless of parent quantity
                if ProdOrderComponent."Calculation Formula" = ProdOrderComponent."Calculation Formula"::" " then begin
                    // Standard calculation: Quantity per × Production Order Line Quantity
                    BaseExpectedQty := ProdOrderComponent."Quantity per" * ProdOrderLine.Quantity;

                    // Expected Quantity includes scrap (if any)
                    // Formula: Quantity per × Prod Order Qty × (1 + Scrap %/100)
                    if ProdOrderComponent."Scrap %" > 0 then begin
                        CalculatedExpectedQty := BaseExpectedQty * (1 + ProdOrderComponent."Scrap %" / 100);
                        GlobalAssert.IsTrue(
                            Abs(ProdOrderComponent."Expected Quantity" - CalculatedExpectedQty) < 0.01,
                            StrSubstNo('Expected Quantity (%1) should include scrap calculation (%2) for item %3',
                                ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                        );

                        GlobalAssert.AreEqual(
                            CalculatedExpectedQty,
                            ProdOrderComponent."Expected Quantity",
                            StrSubstNo('Expected Quantity (%1) should equal scrap calculation (%2) for item %3',
                                ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                        );
                    end else begin
                        // No scrap, should be close to base calculation (allowing for rounding)
                        GlobalAssert.IsTrue(
                            Abs(ProdOrderComponent."Expected Quantity" - BaseExpectedQty) < 1,
                            StrSubstNo('Expected Quantity (%1) should approximate base calculation (%2) for item %3',
                                ProdOrderComponent."Expected Quantity", BaseExpectedQty, ProdOrderComponent."Item No.")
                        );

                        GlobalAssert.AreEqual(
                            BaseExpectedQty,
                            ProdOrderComponent."Expected Quantity",
                            StrSubstNo('Expected Quantity (%1) should equal base calculation (%2) for item %3',
                                ProdOrderComponent."Expected Quantity", BaseExpectedQty, ProdOrderComponent."Item No.")
                        );
                    end;
                end else if ProdOrderComponent."Calculation Formula" = ProdOrderComponent."Calculation Formula"::"Fixed Quantity" then begin
                    // Fixed Quantity formula: Expected Quantity = Quantity (fixed value)
                    BaseExpectedQty := ProdOrderComponent."Quantity";

                    // Expected Quantity includes scrap (if any)
                    // Formula: Quantity per × Prod Order Qty × (1 + Scrap %/100)
                    if ProdOrderComponent."Scrap %" > 0 then begin
                        CalculatedExpectedQty := BaseExpectedQty * (1 + ProdOrderComponent."Scrap %" / 100);
                        GlobalAssert.IsTrue(
                            Abs(ProdOrderComponent."Expected Quantity" - CalculatedExpectedQty) < 0.01,
                            StrSubstNo('Expected Quantity (%1) should include scrap calculation (%2) for item %3',
                                ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                        );

                        GlobalAssert.AreEqual(
                            CalculatedExpectedQty,
                            ProdOrderComponent."Expected Quantity",
                            StrSubstNo('Expected Quantity (%1) should equal scrap calculation (%2) for item %3',
                                ProdOrderComponent."Expected Quantity", CalculatedExpectedQty, ProdOrderComponent."Item No.")
                        );
                    end else begin

                        // [THEN] When Calculation Formula = "Fixed Quantity", Expected Quantity = Quantity (fixed value)
                        // It should NOT multiply by Production Order Line Quantity
                        GlobalAssert.AreEqual(
                            BaseExpectedQty,
                            ProdOrderComponent."Expected Quantity",
                            StrSubstNo('Expected Quantity (%1) should equal fixed Quantity (%2) for item %3 with Fixed Quantity formula',
                                ProdOrderComponent."Expected Quantity", BaseExpectedQty, ProdOrderComponent."Item No.")
                        );

                        // Verify it's not multiplied by production order quantity
                        GlobalAssert.AreNotEqual(
                            ProdOrderComponent."Quantity per" * ProdOrderLine.Quantity,
                            ProdOrderComponent."Expected Quantity",
                            StrSubstNo('Fixed Quantity should not be multiplied by order quantity for item %1', ProdOrderComponent."Item No.")
                        );
                    end;
                end;
            until GlobalItemTemp.Next() = 0;
        end;
    end;

    local procedure SetupItemNumberFilter()
    var
        LocalItem: Record Item;
    begin
        // Filter items for testing, Protect item for when global item is used in other tests
        LocalItem.Init();
        LocalItem.SetRange(Type, Microsoft.Inventory.Item."Item Type"::Inventory);
        LocalItem.SetRange("Replenishment System", "Replenishment System"::"Prod. Order");
        LocalItem.SetRange("Manufacturing Policy", Microsoft.Manufacturing.Setup."Manufacturing Policy"::"Make-to-Order");
        LocalItem.SetFilter("Routing No.", '<>%1', '');
        LocalItem.SetFilter("Production BOM No.", '<>%1', '');
        LocalItem.SetRange("Reordering Policy", Microsoft.Inventory.Item."Reordering Policy"::Order);
        GlobalItem.Init();
        GlobalItem.SetRange(Type, Microsoft.Inventory.Item."Item Type"::Inventory);
        GlobalItem.SetRange("Replenishment System", Microsoft.Inventory.Item."Replenishment System"::"Prod. Order");
        GlobalItem.SetRange("Manufacturing Policy", Microsoft.Manufacturing.Setup."Manufacturing Policy"::"Make-to-Order");
        GlobalItem.SetFilter("Routing No.", '<>%1', '');
        GlobalItem.SetFilter("Production BOM No.", '<>%1', '');
        GlobalItem.SetRange("Reordering Policy", Microsoft.Inventory.Item."Reordering Policy"::Order);

        GlobalItemTemp.DeleteAll();
        GlobalItemTemp.Reset();

        if LocalItem.FindSet() then begin
            repeat
                GlobalItemTemp := LocalItem;
                GlobalItemTemp.Insert();
            until LocalItem.Next() = 0;
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    local procedure ParseProductionOrders(MessageText: Text; var OrderList: List of [Code[20]])
    var
        NumbersPart: Text;
        StartPos: Integer;
        EndPos: Integer;
        CurrentNum: Text;
    begin
        Clear(OrderList);

        // Extract text between ": " and line break or "Do you want"
        StartPos := MessageText.IndexOf(': ');
        if StartPos = 0 then exit;
        StartPos += 2;

        EndPos := MessageText.IndexOf('\Do you want');

        NumbersPart := CopyStr(MessageText, StartPos, EndPos - StartPos).Trim();

        // Handle ellipsis notation "101534...101537"
        if NumbersPart.Contains('...') then begin
            ParseRangeNotation(NumbersPart, OrderList);
            exit;
        end;

        //  Assign number
        CurrentNum := NumbersPart;

        // Add last number
        if CurrentNum <> '' then begin
            OrderList.Add(CurrentNum);
            CurrentNum := '';
        end;
    end;

    local procedure ParseRangeNotation(RangeText: Text; var OrderList: List of [Code[20]])
    var
        StartNumber: Integer;
        EndNumber: Integer;
        EllipsisPos: Integer;
        BeforeEllipsis: Text;
        AfterEllipsis: Text;
        i: Integer;
    begin
        // "101534...101537" -> extract 101534, 101535, 101536, 101537

        EllipsisPos := RangeText.IndexOf('...');
        BeforeEllipsis := CopyStr(RangeText, 1, EllipsisPos - 1).Trim();
        AfterEllipsis := CopyStr(RangeText, EllipsisPos + 3).Trim();

        // First, add all numbers before the ellipsis
        ParseProductionOrders('Created: ' + BeforeEllipsis + '\Do you want', OrderList);

        // Get the last number added (start of range)
        if OrderList.Count > 0 then begin
            Evaluate(StartNumber, OrderList.Get(OrderList.Count));
            Evaluate(EndNumber, AfterEllipsis);

            // Add remaining numbers in the range
            for i := StartNumber + 1 to EndNumber do
                OrderList.Add(Format(i));
        end;
    end;

    local procedure NegativeQtyInsert()
    var
        ManufacturingItemPage: TestPage "Manufacturing Items";
    begin
        GlobalItem.SetRange("No.", GlobalItemTemp."No.");
        GlobalItem.FindFirst();
        ManufacturingItemPage.OpenEdit();
        ManufacturingItemPage.GoToRecord(GlobalItem);

        // [WHEN] Set negative production quantity
        asserterror ManufacturingItemPage."Production Quantity".SetValue(GlobalNegativeQty);
        ManufacturingItemPage.Close();

        // [THEN] Validation error is raised for negative production quantity
        GlobalAssert.ExpectedError('Production Quantity cannot be less than 0.');

    end;

    [ConfirmHandler]
    procedure CreateAndNavConfirmHandler(Question: Text; var Answer: Boolean)
    var
        OrderNumbers: List of [Code[20]];
        LastOrder: Code[20];
        FirstOrder: Code[20];
        OneProdOrderNoText: Label 'Created production order: %1\Do you want to view the created production orders?';
        MoreProdOrderNoText: Label 'Created %1 production orders: %2...%3\Do you want to view the created production orders?';
        ExpectedText: Text;
        ProductionOrder: Record "Production Order";
    begin
        Answer := true;

        // Get all production order numbers
        ParseProductionOrders(Question, OrderNumbers);
        if OrderNumbers.Count = 0 then exit;

        // Use the numbers
        if OrderNumbers.Count = 1 then begin
            ProductionOrder.SetRange("No.", OrderNumbers.Get(1));
            ProductionOrder.FindLast();
            FirstOrder := ProductionOrder."No.";
            ExpectedText := StrSubstNo(OneProdOrderNoText, FirstOrder);

            GlobalAssert.AreEqual(ExpectedText, Question, GlobalValueShouldBeMatch);
        end else begin
            ProductionOrder.SetRange("No.", OrderNumbers.Get(1));
            ProductionOrder.FindLast();
            FirstOrder := ProductionOrder."No.";
            ProductionOrder.SetRange("No.", OrderNumbers.Get(OrderNumbers.Count));
            ProductionOrder.FindLast();
            LastOrder := ProductionOrder."No.";
            ExpectedText := StrSubstNo(MoreProdOrderNoText, OrderNumbers.Count, FirstOrder, LastOrder);

            GlobalAssert.AreEqual(ExpectedText, Question, GlobalValueShouldBeMatch);
        end;
    end;

    [ModalPageHandler]
    procedure VerifyNavtoProdOrderPageHandler(var ProdOrderPage: TestPage "Production Order List")
    begin
        //GlobalAssert.AreNotEqual('', ProdOrderPage."No.", 'Production Order No should not be empty');
    end;
}
