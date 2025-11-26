codeunit 50011 "ESD-Fixed Asset Test"
{
    Subtype = Test;

    var
        GlobalAssert: Codeunit Assert;
        GlobalItemNoList: List of [Code[20]];
        GlobalPurchaseDateFullyYear: Date;
        GlobalPurchaseDateHalfYear: Date;
        GlobalCarcassValue: Decimal;
        GlobalTotalPrice: Decimal;
        GlobalYearOfDepreciation: Integer;
        GlobalisInitialized: Boolean;
        GlobalValueShouldBeMatched: Label 'Value should be matched.';

    [Test]
    procedure "01_CreateESDFixedAssetRecord"()
    begin
        // [SCENARIO] Create an 2 new ESD-Fixed Asset record
        Initialize();

        // [GIVEN] Setup No. Series for test data
        SetupNoSeriesForTestData();

        // [WHEN] Create 2 new ESD-Fixed Asset records
        CreateTwoESDFixedAssetItems();

        // [THEN] Verify that ESD-Fixed Asset record is created successfully
        VerifyTwoESDFixedAssetItemsCreated();
    end;

    [Test]
    procedure "02_CalculationDepreciationAndVerify"()
    begin
        // [SCENARIO] Calculate depreciation for ESD-Fixed Asset record and verify the results
        Initialize();

        // [GIVEN] Setup No. Series for test data
        SetupNoSeriesForTestData();
        // [GIVEN] An existing ESD-Fixed Asset record
        CreateTwoESDFixedAssetItems();

        // [WHEN] Calculate depreciation
        CalculateDepreciationForFixedAssets();

        // [THEN] Verify that the depreciation is calculated correctly
        VerifyItemDepreciationLineCalculateCorrectly();
    end;

    local procedure CalculateDepreciationForFixedAssets()
    var
        ItemDepreciation: Record "Item Depreciation";
        ItemDepreciationManagement: Codeunit ItemDepreciationManagement;
        ItemNo: Code[20];
    begin
        foreach ItemNo in GlobalItemNoList do begin
            ItemDepreciation.Reset();
            ItemDepreciation.SetRange("Item No.", ItemNo);
            if ItemDepreciation.FindFirst() then
                ItemDepreciationManagement.UpdateItemDepreciationRecord(ItemDepreciation,
                                                                        ItemDepreciation."Total Price",
                                                                        ItemDepreciation."Carcass value",
                                                                        ItemDepreciation."Year of Depreciation",
                                                                        ItemDepreciation."Purchase Date",
                                                                        ItemDepreciation."Last Depreciation Date");
        end;

    end;

    local procedure CreateESDFixedAssetItem(var PurchaseDate: Date; Name: Text[100])
    var
        ItemDepreciation: Record "Item Depreciation";
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        ItemDepreciation.Init();
        SalesAndReceivablesSetup.Get();
        ItemDepreciation."Item No." := NoSeries.GetNextNo(SalesAndReceivablesSetup."Item Nos.");
        ItemDepreciation."Item Type" := "Depreciation Item Type"::FA;
        ItemDepreciation.Insert();
        ItemDepreciation.Validate("Purchase Date", PurchaseDate);
        ItemDepreciation.Validate("Item Name", Name);
        ItemDepreciation.Validate("Total Price", GlobalTotalPrice);
        ItemDepreciation.Validate("Carcass value", GlobalCarcassValue);
        ItemDepreciation.Validate("Year of Depreciation", GlobalYearOfDepreciation);
        ItemDepreciation.Modify();
    end;

    local procedure CreateTwoESDFixedAssetItems()
    var
        ItemDepreciation: Record "Item Depreciation";
    begin
        ItemDepreciation.SetFilter("Item Name", 'ESD-TEST-ITEM 1');
        if not ItemDepreciation.FindFirst() then
            CreateESDFixedAssetItem(GlobalPurchaseDateFullyYear, 'ESD-TEST-ITEM 1');

        ItemDepreciation.SetFilter("Item Name", 'ESD-TEST-ITEM 2');
        if not ItemDepreciation.FindFirst() then
            CreateESDFixedAssetItem(GlobalPurchaseDateHalfYear, 'ESD-TEST-ITEM 2');

        ItemDepreciation.Reset();
        ItemDepreciation.SetFilter("Item Name", 'ESD-TEST-ITEM *');
        ItemDepreciation.SetCurrentKey("Item Name");
        ItemDepreciation.SetAscending("Item Name", true);
        GlobalAssert.RecordCount(ItemDepreciation, 2);
        if ItemDepreciation.FindSet() then
            repeat
                GlobalItemNoList.Add(ItemDepreciation."Item No.");
            until ItemDepreciation.Next() = 0;
    end;

    local procedure Initialize()
    begin
        if GlobalisInitialized then
            exit;

        // Shere Fixures Lazy Setup
        // If Changing the values below, please remember to delete existing test data first
        GlobalPurchaseDateFullyYear := 20180101D; // Set to Jan Only
        GlobalPurchaseDateHalfYear := 20180701D; // When want to change to other month, please delete existing test data first
        GlobalTotalPrice := 200000.00;
        GlobalCarcassValue := 500.00;
        GlobalYearOfDepreciation := 5;

        GlobalisInitialized := true;

        Commit();

    end;

    local procedure SetupNoSeriesForTestData()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SaleAndReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SaleAndReceivablesSetup.Get();
        if SaleAndReceivablesSetup."Item Nos." = 'ABS' then
            exit;

        NoSeries.Init();
        NoSeries.SetRange(Code, 'ABS');
        if not NoSeries.FindFirst() then begin
            NoSeries.Code := 'ABS';
            NoSeries.Insert(true);
            NoSeries.Validate(Description, 'ESD-Fixed Asset Item.');
            NoSeries.Validate("Default Nos.", true);
            NoSeries.Validate("Manual Nos.", true);
            NoSeries.Validate("Date Order", false);
            NoSeries.Modify(true);

            NoSeriesLine.Init();
            NoSeriesLine.SetRange("Series Code", NoSeries.Code);
            if not NoSeriesLine.FindFirst() then begin
                NoSeriesLine."Series Code" := NoSeries.Code;
                NoSeriesLine."Line No." := 10000;
                NoSeriesLine.Insert(true);
                NoSeriesLine.Validate("Starting No.", 'ABS-0001');
                NoSeriesLine.Validate("Ending No.", 'ABS-9999');
                NoSeriesLine.Validate("Increment-by No.", 1);
                NoSeriesLine.Validate("Implementation", NoSeriesLine.Implementation::Normal);
                NoSeriesLine.Validate(Open, true);
                NoSeriesLine.Modify(true);
            end;

        end;

        SaleAndReceivablesSetup.Validate("Item Nos.", NoSeries.Code);
        SaleAndReceivablesSetup.Modify(true);
    end;

    local procedure VerifyItemDepreciationLineCalculateCorrectly()
    var
        ItemDepreciation: Record "Item Depreciation";
        ItemDepreciationLine: Record ItemDepreciationLine;
        IsFirstYear: Boolean;
        IsLastYear: Boolean;
        ItemNo: Code[20];
        ExpectedDepreciationAmount: Decimal;
        ExpectedMonthlyDepreciation: Decimal;
        ExpectedRemainingAmount: Decimal;
        CurrentMonth: Integer;
        ExpectedNoOfYear: Integer;
    begin
        foreach ItemNo in GlobalItemNoList do begin
            ItemDepreciation.SetRange("Item No.", ItemNo);
            if ItemDepreciation.FindFirst() then begin
                if ItemDepreciation."Purchase Date" = GlobalPurchaseDateFullyYear then begin
                    // Fully Year Depreciation Verification
                    ItemDepreciationLine.SetRange("source No.", ItemDepreciation."Item No.");
                    GlobalAssert.RecordCount(ItemDepreciationLine, GlobalYearOfDepreciation);
                    ExpectedNoOfYear := Date2DMY(GlobalPurchaseDateFullyYear, 3);
                    ExpectedDepreciationAmount := (GlobalTotalPrice - GlobalCarcassValue) / GlobalYearOfDepreciation;
                    ExpectedMonthlyDepreciation := (GlobalTotalPrice - GlobalCarcassValue) / GlobalYearOfDepreciation / 12;
                    ExpectedRemainingAmount := GlobalTotalPrice;
                    if ItemDepreciationLine.FindSet() then
                        repeat
                            VerifyFullyYearDepreciationLineCalculatedCorrectly(ItemDepreciationLine,
                                                                               ExpectedNoOfYear,
                                                                               ExpectedDepreciationAmount,
                                                                               ExpectedMonthlyDepreciation,
                                                                               ExpectedRemainingAmount);
                            ExpectedNoOfYear += 1;
                        until ItemDepreciationLine.Next() = 0;
                end else begin
                    // Half Year Depreciation Verification
                    ItemDepreciationLine.SetRange("source No.", ItemDepreciation."Item No.");
                    GlobalAssert.RecordCount(ItemDepreciationLine, GlobalYearOfDepreciation + 1);
                    ExpectedNoOfYear := Date2DMY(GlobalPurchaseDateHalfYear, 3);
                    CurrentMonth := Date2DMY(GlobalPurchaseDateHalfYear, 2);
                    ExpectedDepreciationAmount := 0.00;
                    ExpectedMonthlyDepreciation := (GlobalTotalPrice - GlobalCarcassValue) / GlobalYearOfDepreciation / 12;
                    ExpectedRemainingAmount := GlobalTotalPrice;
                    if ItemDepreciationLine.FindSet() then
                        repeat
                            IsFirstYear := ExpectedNoOfYear = Date2DMY(GlobalPurchaseDateHalfYear, 3);
                            IsLastYear := ExpectedNoOfYear = Date2DMY(GlobalPurchaseDateHalfYear, 3) + GlobalYearOfDepreciation;
                            GlobalAssert.AreEqual(ExpectedNoOfYear, ItemDepreciationLine."No. of Year", GlobalValueShouldBeMatched);
                            if IsFirstYear then begin
                                VerifyFirstYearDepreciationLineCalculatedCorrectly(ItemDepreciationLine,
                                                                                   ExpectedNoOfYear,
                                                                                   ExpectedDepreciationAmount,
                                                                                   ExpectedMonthlyDepreciation,
                                                                                   ExpectedRemainingAmount,
                                                                                   CurrentMonth);
                            end else if IsLastYear then begin
                                VerifyLastYearDepreciationLineCalculatedCorrectly(ItemDepreciationLine,
                                                                                  ExpectedNoOfYear,
                                                                                  ExpectedDepreciationAmount,
                                                                                  ExpectedMonthlyDepreciation,
                                                                                  ExpectedRemainingAmount,
                                                                                  CurrentMonth);
                            end else begin
                                ExpectedDepreciationAmount := ExpectedMonthlyDepreciation * 12;
                                VerifyFullyYearDepreciationLineCalculatedCorrectly(ItemDepreciationLine,
                                                                                   ExpectedNoOfYear,
                                                                                   ExpectedDepreciationAmount,
                                                                                   ExpectedMonthlyDepreciation,
                                                                                   ExpectedRemainingAmount);
                            end;

                            ExpectedNoOfYear += 1;
                        until ItemDepreciationLine.Next() = 0;
                end;

            end;

        end;

    end;

    local procedure VerifyTwoESDFixedAssetItemsCreated()
    var
        ItemDepreciation: Record "Item Depreciation";
        ItemNo: Code[20];
        Index: Integer;
    begin
        Index := 1;
        foreach ItemNo in GlobalItemNoList do begin
            ItemDepreciation.Reset();
            ItemDepreciation.SetRange("Item No.", ItemNo);
            GlobalAssert.RecordCount(ItemDepreciation, 1);
            ItemDepreciation.FindFirst();
            if Index = 1 then begin
                GlobalAssert.AreEqual('ESD-TEST-ITEM 1', ItemDepreciation."Item Name", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseDateFullyYear, ItemDepreciation."Purchase Date", GlobalValueShouldBeMatched);
            end else begin
                GlobalAssert.AreEqual('ESD-TEST-ITEM 2', ItemDepreciation."Item Name", GlobalValueShouldBeMatched);
                GlobalAssert.AreEqual(GlobalPurchaseDateHalfYear, ItemDepreciation."Purchase Date", GlobalValueShouldBeMatched);
            end;

            GlobalAssert.AreEqual(ItemNo, ItemDepreciation."Item No.", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalTotalPrice, ItemDepreciation."Total Price", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalCarcassValue, ItemDepreciation."Carcass value", GlobalValueShouldBeMatched);
            GlobalAssert.AreEqual(GlobalYearOfDepreciation, ItemDepreciation."Year of Depreciation", GlobalValueShouldBeMatched);
            Index += 1;
        end;

    end;

    local procedure VerifyFullyYearDepreciationLineCalculatedCorrectly(var ItemDepreciationLine: Record ItemDepreciationLine;
                                                                    var ExpectedNoOfYear: Integer;
                                                                    var ExpectedDepreciationAmount: Decimal;
                                                                    var ExpectedMonthlyDepreciation: Decimal;
                                                                    var ExpectedRemainingAmount: Decimal)
    begin
        ExpectedRemainingAmount -= ExpectedDepreciationAmount;
        GlobalAssert.AreEqual(ExpectedNoOfYear, ItemDepreciationLine."No. of Year", GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedDepreciationAmount, ItemDepreciationLine."Depreciation Amount", GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedRemainingAmount, ItemDepreciationLine."Remaining Amount", GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jan, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Feb, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Mar, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Apr, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.May, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jun, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jul, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Aug, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Sep, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Oct, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Nov, GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Dec, GlobalValueShouldBeMatched);
    end;

    local procedure VerifyFirstYearDepreciationLineCalculatedCorrectly(var ItemDepreciationLine: Record ItemDepreciationLine;
                                                                    var ExpectedNoOfYear: Integer;
                                                                    var ExpectedDepreciationAmount: Decimal;
                                                                    var ExpectedMonthlyDepreciation: Decimal;
                                                                    var ExpectedRemainingAmount: Decimal;
                                                                    var CurrentMonth: Integer)
    begin
        ExpectedDepreciationAmount := ExpectedMonthlyDepreciation * (12 - (CurrentMonth - 1));
        ExpectedRemainingAmount -= ExpectedDepreciationAmount;
        GlobalAssert.AreEqual(ExpectedDepreciationAmount, ItemDepreciationLine."Depreciation Amount", GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedRemainingAmount, ItemDepreciationLine."Remaining Amount", GlobalValueShouldBeMatched);
        if CurrentMonth <= 1 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jan, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Jan, GlobalValueShouldBeMatched);
        if CurrentMonth <= 2 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Feb, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Feb, GlobalValueShouldBeMatched);
        if CurrentMonth <= 3 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Mar, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Mar, GlobalValueShouldBeMatched);
        if CurrentMonth <= 4 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Apr, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Apr, GlobalValueShouldBeMatched);
        if CurrentMonth <= 5 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.May, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.May, GlobalValueShouldBeMatched);
        if CurrentMonth <= 6 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jun, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Jun, GlobalValueShouldBeMatched);
        if CurrentMonth <= 7 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jul, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Jul, GlobalValueShouldBeMatched);
        if CurrentMonth <= 8 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Aug, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Aug, GlobalValueShouldBeMatched);
        if CurrentMonth <= 9 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Sep, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Sep, GlobalValueShouldBeMatched);
        if CurrentMonth <= 10 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Oct, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Oct, GlobalValueShouldBeMatched);
        if CurrentMonth <= 11 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Nov, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Nov, GlobalValueShouldBeMatched);
        if CurrentMonth <= 12 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Dec, GlobalValueShouldBeMatched);
    end;

    local procedure VerifyLastYearDepreciationLineCalculatedCorrectly(var ItemDepreciationLine: Record ItemDepreciationLine;
                                                                   var ExpectedNoOfYear: Integer;
                                                                   var ExpectedDepreciationAmount: Decimal;
                                                                   var ExpectedMonthlyDepreciation: Decimal;
                                                                   var ExpectedRemainingAmount: Decimal;
                                                                   var CurrentMonth: Integer)
    begin
        ExpectedDepreciationAmount := ExpectedMonthlyDepreciation * (CurrentMonth - 1);
        ExpectedRemainingAmount -= ExpectedDepreciationAmount;
        GlobalAssert.AreEqual(ExpectedDepreciationAmount, ItemDepreciationLine."Depreciation Amount", GlobalValueShouldBeMatched);
        GlobalAssert.AreEqual(ExpectedRemainingAmount, ItemDepreciationLine."Remaining Amount", GlobalValueShouldBeMatched);
        if CurrentMonth > 1 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jan, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Jan, GlobalValueShouldBeMatched);
        if CurrentMonth > 2 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Feb, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Feb, GlobalValueShouldBeMatched);
        if CurrentMonth > 3 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Mar, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Mar, GlobalValueShouldBeMatched);
        if CurrentMonth > 4 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Apr, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Apr, GlobalValueShouldBeMatched);
        if CurrentMonth > 5 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.May, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.May, GlobalValueShouldBeMatched);
        if CurrentMonth > 6 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jun, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Jun, GlobalValueShouldBeMatched);
        if CurrentMonth > 7 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Jul, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Jul, GlobalValueShouldBeMatched);
        if CurrentMonth > 8 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Aug, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Aug, GlobalValueShouldBeMatched);
        if CurrentMonth > 9 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Sep, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Sep, GlobalValueShouldBeMatched);
        if CurrentMonth > 10 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Oct, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Oct, GlobalValueShouldBeMatched);
        if CurrentMonth > 11 then
            GlobalAssert.AreEqual(ExpectedMonthlyDepreciation, ItemDepreciationLine.Nov, GlobalValueShouldBeMatched)
        else
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Nov, GlobalValueShouldBeMatched);
        if CurrentMonth > 12 then
            GlobalAssert.AreEqual(0.00, ItemDepreciationLine.Dec, GlobalValueShouldBeMatched);
    end;
}