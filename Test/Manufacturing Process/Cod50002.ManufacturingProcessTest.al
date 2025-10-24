namespace ALWSP.ALWSP;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;

codeunit 50002 "Manufacturing Process Testing"
{
    Subtype = Test;

    var
        GlobalItem: Record Item;
        GlobalItemTemp: Record Item temporary;
        GlobalAssert: Codeunit Assert;
        GlobalCalcProdOrder: Codeunit "CalcProdOrder";
        GlobalProdOrder: Record "Production Order";
        GlobalProdOrderLine: Record "Prod. Order Line";
        GlobalValueShouldBeMatch: Label 'Value should be matched';
        GlobalErrorMsg: Label 'No items found for testing. Please ensure there are items set up with the required manufacturing process settings.';
        GlobalQty: Integer;
        GlobalNegativeQty: Integer;
        ProdOrderPage: TestPage "Released Production Order";

    local procedure Initialize()
    begin

        GlobalItemTemp.DeleteAll();
        GlobalItemTemp.Reset();
        GlobalQty := 4;
        GlobalNegativeQty := -1;

        SetupItemNumberFilter();
    end;
    // [FEATURE] Production Order Creation with Manufacturing Process Setup
    [Test]
    procedure TestItemCreationWithManufacturingSetupSingleProdOrder()
    begin
        // [GIVEN] A manufacturing item with setup
        Initialize();
        // Get first test item from the temporary table
        if GlobalItemTemp.FindFirst() then begin
            GlobalItem.Get(GlobalItemTemp."No.");
            GlobalItem.FindFirst();
            GlobalItem."Production Quantity" := GlobalQty;
            GlobalItem.Modify();

            // [WHEN] Create a single production order
            GlobalCalcProdOrder.CreateProdOrder(GlobalItem, GlobalItem."Production Quantity");

            // [THEN] Production order should be created with correct setup
            GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
            GlobalProdOrder.SetRange("Source Type", GlobalProdOrder."Source Type"::Item);
            GlobalProdOrder.SetRange(Status, GlobalProdOrder.Status::Released);
            GlobalProdOrder.FindLast();
            GlobalProdOrderLine.SetRange("Prod. Order No.", GlobalProdOrder."No.");
            GlobalProdOrderLine.FindLast();

            // Verify production order details
            GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Production Quantity", GlobalProdOrder.Quantity, GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalProdOrder.Status::Released, GlobalProdOrder.Status, GlobalValueShouldBeMatch);

            // Verify Routing No. and BOM No. are correctly assigned
            GlobalAssert.AreEqual(GlobalItem."Routing No.", GlobalProdOrder."Routing No.", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Production BOM No.", GlobalProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);

        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    [Test]
    procedure TestItemCreationWithManufacturingSetupMultipleProdOrder()
    begin
        // [GIVEN] Initialize test items and production quantity of items to create
        Initialize();

        // Get all items from temporary table
        if GlobalItemTemp.FindSet() then begin
            repeat
                GlobalItem.Reset();
                GlobalItem.SetRange("No.", GlobalItemTemp."No.");
                if GlobalItem.FindSet() then begin
                    repeat
                        // [WHEN] Setup and create production orders for test items
                        // Update each item
                        GlobalItem."Production Quantity" := GlobalQty;
                        GlobalItem.Modify();
                        GlobalCalcProdOrder.CreateProdOrder(GlobalItem, GlobalItem."Production Quantity");

                        // [THEN] Production orders are created successfully
                        GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
                        GlobalProdOrder.SetRange("Source Type", GlobalProdOrder."Source Type"::Item);
                        GlobalProdOrder.SetRange(Status, GlobalProdOrder.Status::Released);
                        GlobalProdOrder.FindLast();
                        GlobalProdOrderLine.SetRange("Prod. Order No.", GlobalProdOrder."No.");
                        GlobalProdOrderLine.FindLast();

                        GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Production Quantity", GlobalProdOrder.Quantity, GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalProdOrder."No.", GlobalProdOrderLine."Prod. Order No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalProdOrder.Quantity, GlobalProdOrderLine.Quantity, GlobalValueShouldBeMatch);

                        // Verify Routing No. and BOM No. are correctly assigned
                        GlobalAssert.AreEqual(GlobalItem."Routing No.", GlobalProdOrder."Routing No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Production BOM No.", GlobalProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);
                    until GlobalItem.Next() = 0;
                end;
            until GlobalItemTemp.Next() = 0;
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure TestManufacturingItemUIWorkflowSingleProdOrder()
    var
        ManufacturingPage: TestPage "Manufacturing Item";
    begin
        // [GIVEN] Initialize setup and create test item
        Initialize();
        if GlobalItemTemp.FindFirst() then begin
            GlobalItem.Reset();
            GlobalItem.SetRange("No.", GlobalItemTemp."No.");
            GlobalItem.FindFirst();
            // [WHEN] Open Manufacturing Item page and create new item and Create Production Order from Item
            ManufacturingPage.OpenEdit();
            ManufacturingPage.GoToRecord(GlobalItem);
            ManufacturingPage."Production Quantity".SetValue(GlobalQty);
            ManufacturingPage.GoToRecord(GlobalItem);
            ManufacturingPage.CreateSelectProductionOrder.Invoke();
            ManufacturingPage.Close();

            // [THEN] Verify item was created with correct setup
            GlobalItem.Get(GlobalItemTemp."No.");
            GlobalAssert.AreEqual(GlobalQty, GlobalItem."Production Quantity", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Manufacturing Policy"::"Make-to-Order", GlobalItem."Manufacturing Policy", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Replenishment System"::"Prod. Order", GlobalItem."Replenishment System", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Reordering Policy"::Order, GlobalItem."Reordering Policy", GlobalValueShouldBeMatch);

            GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
            GlobalProdOrder.SetRange("Source Type", GlobalProdOrder."Source Type"::Item);
            GlobalProdOrder.SetRange(Status, GlobalProdOrder.Status::Released);
            GlobalProdOrder.FindLast();
            GlobalProdOrderLine.SetRange("Prod. Order No.", GlobalProdOrder."No.");
            GlobalProdOrderLine.FindLast();

            // Verify Production Order 
            GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Production Quantity", GlobalProdOrder.Quantity, GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Routing No.", GlobalProdOrder."Routing No.", GlobalValueShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Production BOM No.", GlobalProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);

            // Close pages
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure TestManufacturingItemUIWorkflowMultipleProdOrder()
    var
        ManufacturingPage: TestPage "Manufacturing Item";
    begin
        // [GIVEN] Initialize setup and create test items
        Initialize();
        if GlobalItemTemp.FindSet() then begin
            repeat
                GlobalItem.Reset();
                GlobalItem.SetRange("No.", GlobalItemTemp."No.");

                if GlobalItem.FindSet() then begin
                    repeat
                        // [WHEN] Create Production Order from Item
                        ManufacturingPage.OpenEdit();
                        ManufacturingPage.GoToRecord(GlobalItem);
                        ManufacturingPage."Production Quantity".SetValue(GlobalQty);
                        ManufacturingPage.CreateProductionOrder.Invoke();
                        ManufacturingPage.Close();

                        // [THEN] Verify item was created with correct setup 
                        GlobalItem.Get(GlobalItem."No.");
                        GlobalAssert.AreEqual(GlobalQty, GlobalItem."Production Quantity", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Manufacturing Policy"::"Make-to-Order", GlobalItem."Manufacturing Policy", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Replenishment System"::"Prod. Order", GlobalItem."Replenishment System", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Reordering Policy"::Order, GlobalItem."Reordering Policy", GlobalValueShouldBeMatch);

                        GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
                        GlobalProdOrder.SetRange("Source Type", GlobalProdOrder."Source Type"::Item);
                        GlobalProdOrder.SetRange(Status, GlobalProdOrder.Status::Released);
                        GlobalProdOrder.FindLast();
                        GlobalProdOrderLine.SetRange("Prod. Order No.", GlobalProdOrder."No.");
                        GlobalProdOrderLine.FindLast();

                        // Verify Production Order
                        GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Production Quantity", GlobalProdOrder.Quantity, GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Routing No.", GlobalProdOrder."Routing No.", GlobalValueShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Production BOM No.", GlobalProdOrderLine."Production BOM No.", GlobalValueShouldBeMatch);

                    until GlobalItem.Next() = 0;
                end;
            until GlobalItemTemp.Next() = 0;
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    [Test]
    procedure TestProductionQuantityValidation()
    begin
        // [GIVEN] Initialize test items and negative production quantity
        Initialize();
        if GlobalItemTemp.FindFirst() then begin
            GlobalItem.Reset();
            GlobalItem.SetRange("No.", GlobalItemTemp."No.");
            GlobalItem.FindFirst();

            // [WHEN] Set negative production quantity
            asserterror GlobalItem.Validate("Production Quantity", GlobalNegativeQty);

            // [THEN] Validation error is raised for negative production quantity
            GlobalAssert.ExpectedError('Production Quantity cannot be less than 0.');
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    local procedure SetupItemNumberFilter()
    begin
        //Filter items for testing
        GlobalItem.SetRange(Type, GlobalItem.Type::Inventory);
        GlobalItem.SetRange("Replenishment System", GlobalItem."Replenishment System"::"Prod. Order");
        GlobalItem.SetRange("Manufacturing Policy", GlobalItem."Manufacturing Policy"::"Make-to-Order");
        GlobalItem.SetFilter("Routing No.", '<>%1', '');
        GlobalItem.SetFilter("Production BOM No.", '<>%1', '');
        GlobalItem.SetRange("Reordering Policy", GlobalItem."Reordering Policy"::Order);

        if GlobalItem.FindSet() then begin
            repeat
                GlobalItemTemp := GlobalItem;
                GlobalItemTemp.Insert();
            until GlobalItem.Next() = 0;
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
        // Just to handle message pop-ups during tests
    end;
}
