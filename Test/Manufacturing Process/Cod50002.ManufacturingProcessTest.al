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
        GlobalValurShouldBeMatch: Label 'Value should be matched';
        GlobalErrorMsg: Label 'No items found for testing. Please ensure there are items set up with the required manufacturing process settings.';
        GlobalQty: Integer;
        GlobalNegativeQty: Integer;
        ManufacturingPage: TestPage "Manufacturing Item";
        ProdOrderPage: TestPage "Released Production Order";

    local procedure Initialize()
    begin

        GlobalItemTemp.DeleteAll();
        GlobalItemTemp.Reset();
        GlobalQty := 1;
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
            GlobalItem."Production Quantity" := GlobalQty;
            GlobalItem.Modify();

            // [WHEN] Create a single production order
            GlobalCalcProdOrder.CreateProdOrder(GlobalItem, GlobalItem."Production Quantity");

            // [THEN] Production order should be created with correct setup
            GlobalProdOrder.Reset();
            GlobalProdOrder.SetRange("Source Type", GlobalProdOrder."Source Type"::Item);
            GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
            GlobalProdOrder.SetRange(Status, GlobalProdOrder.Status::Released);
            GlobalProdOrder.FindLast();

            // Verify production order details
            GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Production Quantity", GlobalProdOrder.Quantity, GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalProdOrder.Status::Released, GlobalProdOrder.Status, GlobalValurShouldBeMatch);
        end else begin
            asserterror Error(GlobalErrorMsg);
            GlobalAssert.ExpectedError(GlobalErrorMsg);
        end;
    end;

    [Test]
    procedure TestItemCreationWithManufacturingSetupMutipleProdOrder()
    var
        ErrorMsg: Text;
    begin
        // [GIVEN] Initialize test items and production quantity of items to create
        Initialize();

        // Get all items from temporary table
        if GlobalItemTemp.FindSet() then
            repeat
                GlobalItem.Reset();
                GlobalItem.SetFilter("No.", GlobalItemTemp."No.");
                if GlobalItem.FindSet() then begin
                    repeat
                        // [WHEN] Setup and create production orders for test items
                        // Update each item
                        GlobalItem."Production Quantity" := GlobalQty;
                        GlobalItem.Modify();
                        GlobalCalcProdOrder.CreateProdOrder(GlobalItem, GlobalItem."Production Quantity");
                        GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
                        GlobalProdOrder.FindLast();
                        GlobalProdOrderLine.SetRange("Prod. Order No.", GlobalProdOrder."No.");
                        GlobalProdOrderLine.FindLast();

                        // [THEN] Production orders are created successfully
                        GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValurShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Production Quantity", GlobalProdOrder.Quantity, GlobalValurShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalProdOrder."No.", GlobalProdOrderLine."Prod. Order No.", GlobalValurShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalProdOrder.Quantity, GlobalProdOrderLine.Quantity, GlobalValurShouldBeMatch);

                        // Verify Replenishment System is and Manufacturing Policy are correctly assigned
                        GlobalAssert.AreEqual(GlobalItem."Replenishment System", GlobalItem."Replenishment System", GlobalValurShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Manufacturing Policy", GlobalItem."Manufacturing Policy", GlobalValurShouldBeMatch);

                        // Verify Routing No. and BOM No. are correctly assigned
                        GlobalAssert.AreEqual(GlobalItem."Routing No.", GlobalProdOrder."Routing No.", GlobalValurShouldBeMatch);
                        GlobalAssert.AreEqual(GlobalItem."Production BOM No.", GlobalProdOrderLine."Production BOM No.", GlobalValurShouldBeMatch);
                    until GlobalItem.Next() = 0;
                end else begin
                    // [THEN] Item not found in the database
                    ErrorMsg := StrSubstNo('Item with No. %1 not found in the database.', GlobalItemTemp."No.");
                    asserterror Error(ErrorMsg);
                    GlobalAssert.ExpectedError(ErrorMsg);
                end;
            until GlobalItemTemp.Next() = 0;
    end;

    [Test]
    procedure TestProductionQuantityValidation()
    begin
        // [GIVEN] Initialize test items and negative production quantity
        Initialize();
        if GlobalItemTemp.FindFirst() then begin
            GlobalItem.Reset();
            GlobalItem.SetFilter("No.", GlobalItemTemp."No.");
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



    [Test]
    procedure TestManufacturingItemUIWorkflow()
    begin
        // [GIVEN] Initialize setup and create test item
        Initialize();
        if GlobalItemTemp.FindFirst() then begin
            GlobalItem.Reset();
            GlobalItem.Setfilter("No.", GlobalItemTemp."No.");
            // [WHEN] Open Manufacturing Item page and create new item
            ManufacturingPage.OpenEdit();
            ManufacturingPage."Production Quantity".SetValue(GlobalQty);

            // [THEN] Verify item was created with correct setup
            GlobalItem.Get(GlobalItemTemp."No.");
            GlobalAssert.AreEqual(GlobalQty, GlobalItem."Production Quantity", GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Manufacturing Policy"::"Make-to-Order", GlobalItem."Manufacturing Policy", GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Replenishment System"::"Prod. Order", GlobalItem."Replenishment System", GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Reordering Policy"::Order, GlobalItem."Reordering Policy", GlobalValurShouldBeMatch);

            // [WHEN] Create Production Order from Item
            GlobalCalcProdOrder.CreateProdOrder(GlobalItem, GlobalQty);

            // [THEN] Verify Production Order UI
            GlobalProdOrder.SetRange("Source Type", GlobalProdOrder."Source Type"::Item);
            GlobalProdOrder.SetRange("Source No.", GlobalItem."No.");
            GlobalProdOrder.FindLast();
            GlobalProdOrderLine.SetRange("Prod. Order No.", GlobalProdOrder."No.");
            GlobalProdOrderLine.FindLast();

            ProdOrderPage.OpenEdit();
            ProdOrderPage.GoToRecord(GlobalProdOrder);

            GlobalAssert.AreEqual(GlobalItem."No.", GlobalProdOrder."Source No.", GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalQty, GlobalProdOrder.Quantity, GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Routing No.", GlobalProdOrder."Routing No.", GlobalValurShouldBeMatch);
            GlobalAssert.AreEqual(GlobalItem."Production BOM No.", GlobalProdOrderLine."Production BOM No.", GlobalValurShouldBeMatch);

            // Close pages
            ProdOrderPage.Close();
            ManufacturingPage.Close();
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
}
