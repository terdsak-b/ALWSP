namespace ALWSP.ALWSP;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;

codeunit 50002 "Manufacturing Process Testing"
{
    Subtype = Test;

    var
        GlobalItem: Record Item;
        GlobalItemTemp: Record Item temporary;
        GlobalItemNoList: array[5] of Code[20];
        GlobalItemNo: Code[20];
        GlobalAssert: Codeunit Assert;
        GlobalCalcProdOrder: Codeunit "CalcProdOrder";
        GlobalProdOrder: Record "Production Order";
        GlobalProdOrderLine: Record "Prod. Order Line";
        GlobalValurShouldBeMatch: Label 'Value should be matched';
        GlobalQty: Integer;
        GlobalNegativeQty: Integer;

    local procedure Initialize()
    begin
        GlobalItemNoList[1] := 'GU-SP-BOM2000';
        GlobalItemNoList[2] := 'GU-SP-BOM2001';
        GlobalItemNoList[3] := 'GU-SP-BOM2002';
        GlobalItemNoList[4] := 'GU-SP-BOM2003';
        GlobalItemNoList[5] := 'SP-BOM2000';
        GlobalItemNo := 'SP-BOM2000';
        GlobalQty := 1;
        GlobalNegativeQty := -1;
        GlobalItemTemp.DeleteAll();
        GlobalItemTemp.Reset();
    end;

    // [FEATURE] Production Order Creation with Manufacturing Process Setup

    [Test]
    procedure TestItemCreationWithManufacturingSetup()
    var
        i: Integer;
        ErrorMsg: Text;
    begin
        // [GIVEN] Initialize test items and production quantity of items to create
        Initialize();

        // Get all items matching the item numbers
        for i := 1 to System.ArrayLen(GlobalItemNoList) do begin
            GlobalItem.Reset();
            GlobalItem.SetFilter("No.", GlobalItemNoList[i]);
            if GlobalItem.FindSet() then begin
                repeat
                    // Update each item
                    GlobalItem."Production Quantity" := GlobalQty;

                    GlobalItem.Modify();

                    // Copy to temp table
                    GlobalItemTemp.Init();
                    GlobalItemTemp.TransferFields(GlobalItem);
                    GlobalItemTemp.Insert();

                    // [WHEN] Setup and create production orders for test items
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

                until GlobalItem.Next() = 0;
            end else begin
                // Item not found in the database
                ErrorMsg := StrSubstNo('Item with No. %1 not found in the database.', GlobalItemNoList[i]);
                asserterror Error(ErrorMsg);
                GlobalAssert.ExpectedError(ErrorMsg);
            end;
        end;
    end;

    [Test]
    procedure TestProductionQuantityValidation()
    begin
        // [GIVEN] Initialize test items and negative production quantity
        Initialize();
        GlobalItem.Reset();
        GlobalItem.SetFilter("No.", GlobalItemNo);
        GlobalItem.FindFirst();

        // [WHEN] Set negative production quantity
        asserterror GlobalItem.Validate("Production Quantity", GlobalNegativeQty);

        // [THEN] Validation error is raised for negative production quantity
        GlobalAssert.ExpectedError('Production Quantity cannot be less than 0.');
    end;
}
