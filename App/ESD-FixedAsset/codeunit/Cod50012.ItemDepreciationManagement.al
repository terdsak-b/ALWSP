namespace ALWSP.ALWSP;

codeunit 50012 ItemDepreciationManagement
{
    internal procedure FilterItemDepreciationInList(var ItemDepreciation: Record "Item Depreciation"; var FilterList: List of [Text])
    var
        TempItemDepreciation: Record "Item Depreciation";
        FilterPart: Text;
        FilterParts: List of [Text];
        FilterText: Text;
        RangeParts: List of [Text];
    begin
        Clear(FilterList);
        FilterText := ItemDepreciation.GetFilter("Item No.");

        if FilterText = '' then
            exit;

        // Split by pipe to handle multiple filters
        FilterParts := FilterText.Split('|');

        foreach FilterPart in FilterParts do begin
            if FilterPart.Contains('..') then begin
                // Handle range filter (e.g., ABS0002..ABS0005)
                RangeParts := FilterPart.Split('..');
                if RangeParts.Count = 2 then begin
                    TempItemDepreciation.Copy(ItemDepreciation);
                    TempItemDepreciation.SetRange("Item No.", RangeParts.Get(1), RangeParts.Get(2));
                    if TempItemDepreciation.FindSet() then
                        repeat
                            if not FilterList.Contains(TempItemDepreciation."Item No.") then
                                FilterList.Add(TempItemDepreciation."Item No.");
                        until TempItemDepreciation.Next() = 0;
                end;

            end else begin
                // Handle single item filter
                if not FilterList.Contains(FilterPart) then
                    FilterList.Add(FilterPart);
            end;

        end;

    end;

    internal procedure UpdateItemDepreciationRecord(var ItemDepreciation: Record "Item Depreciation"; var TotalPrice: Decimal; var CarcassValue: Decimal; var YearOfDepreciation: Integer; var PurchaseDate: Date; var LastDepreciationDate: Date)
    var
        ItemDepreciationLine: Record ItemDepreciationLine;
        IsFirstYear: Boolean;
        AccumulatedDepreciation: Decimal;
        DepreciationAmount: Decimal;
        MonthlyDepreciation: Decimal;
        CurrentYear: Integer;
        MonthCounter: Integer;
        PurchaseMonth: Integer;
        PurchaseYear: Integer;
        TotalMonths: Integer;
    begin
        if YearOfDepreciation <= 0 then
            exit;

        ItemDepreciation.Validate("Purchase Date", PurchaseDate);
        ItemDepreciation.Validate("Total Price", TotalPrice);
        ItemDepreciation.Validate("Carcass value", CarcassValue);
        ItemDepreciation.Validate("Year of Depreciation", YearOfDepreciation);
        ItemDepreciation.Validate("Last Depreciation Date", WorkDate());
        ItemDepreciation.Modify(true);

        ItemDepreciationLine.SetRange("Source No.", ItemDepreciation."Item No.");
        ItemDepreciationLine.SetRange("Source Type", ItemDepreciation."Item Type");
        ItemDepreciationLine.DeleteAll();

        PurchaseYear := Date2DMY(PurchaseDate, 3);
        PurchaseMonth := Date2DMY(PurchaseDate, 2);

        // Calculate total months of depreciation
        TotalMonths := YearOfDepreciation * 12;
        MonthlyDepreciation := (TotalPrice - CarcassValue) / TotalMonths;

        // Create depreciation lines for each calendar year that will be affected
        CurrentYear := PurchaseYear;

        while MonthCounter < TotalMonths do begin
            // Check if we need a line for this year
            IsFirstYear := (CurrentYear = PurchaseYear);
            ItemDepreciationLine.Init();
            ItemDepreciationLine."Source No." := ItemDepreciation."Item No.";
            ItemDepreciationLine."Source Type" := ItemDepreciation."Item Type";
            ItemDepreciationLine."No. of Year" := CurrentYear;
            ItemDepreciationLine.Insert(true);

            CurrentYear += 1;
            if IsFirstYear then
                MonthCounter := 12 - (PurchaseMonth - 1) // Minus 1 because when we set 1st month we don't want an additional month for the purchase month
            else
                MonthCounter += 12;
        end;

        // Now populate the monthly depreciation values
        ItemDepreciationLine.SetRange("Source No.", ItemDepreciation."Item No.");
        ItemDepreciationLine.SetRange("Source Type", ItemDepreciation."Item Type");
        if ItemDepreciationLine.FindSet() then begin
            AccumulatedDepreciation := 0;
            MonthCounter := 0; // Reset counter for actual month-by-month processing

            repeat
                CurrentYear := ItemDepreciationLine."No. of Year";
                IsFirstYear := (CurrentYear = PurchaseYear);

                // Set monthly depreciation based on purchase date and total months
                // January
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 1)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Jan, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Jan, 0.00);
                end else
                    ItemDepreciationLine.Validate(Jan, 0.00);

                // February
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 2)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Feb, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Feb, 0.00);
                end else
                    ItemDepreciationLine.Validate(Feb, 0.00);

                // March
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 3)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Mar, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Mar, 0.00);
                end else
                    ItemDepreciationLine.Validate(Mar, 0.00);

                // April
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 4)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Apr, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Apr, 0.00);
                end else
                    ItemDepreciationLine.Validate(Apr, 0.00);

                // May
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 5)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(May, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(May, 0.00);
                end else
                    ItemDepreciationLine.Validate(May, 0.00);

                // June
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 6)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Jun, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Jun, 0.00);
                end else
                    ItemDepreciationLine.Validate(Jun, 0.00);

                // July
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 7)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Jul, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Jul, 0.00);
                end else
                    ItemDepreciationLine.Validate(Jul, 0.00);

                // August
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 8)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Aug, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Aug, 0.00);
                end else
                    ItemDepreciationLine.Validate(Aug, 0.00);

                // September
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 9)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Sep, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Sep, 0.00);
                end else
                    ItemDepreciationLine.Validate(Sep, 0.00);

                // October
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 10)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Oct, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Oct, 0.00);
                end else
                    ItemDepreciationLine.Validate(Oct, 0.00);

                // November
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 11)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Nov, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Nov, 0.00);
                end else
                    ItemDepreciationLine.Validate(Nov, 0.00);

                // December
                if (CurrentYear > PurchaseYear) or (IsFirstYear and (PurchaseMonth <= 12)) then begin
                    if MonthCounter < TotalMonths then begin
                        ItemDepreciationLine.Validate(Dec, MonthlyDepreciation);
                        MonthCounter += 1;
                    end else
                        ItemDepreciationLine.Validate(Dec, 0.00);
                end else
                    ItemDepreciationLine.Validate(Dec, 0.00);

                // Calculate yearly depreciation amount for this line
                DepreciationAmount := ItemDepreciationLine.Jan + ItemDepreciationLine.Feb + ItemDepreciationLine.Mar +
                                    ItemDepreciationLine.Apr + ItemDepreciationLine.May + ItemDepreciationLine.Jun +
                                    ItemDepreciationLine.Jul + ItemDepreciationLine.Aug + ItemDepreciationLine.Sep +
                                    ItemDepreciationLine.Oct + ItemDepreciationLine.Nov + ItemDepreciationLine.Dec;

                AccumulatedDepreciation += DepreciationAmount;

                if IsFirstYear then begin
                    ItemDepreciation.Validate("Remaining Amount", TotalPrice - AccumulatedDepreciation);
                    ItemDepreciation.Modify(true);
                end;
                ItemDepreciationLine.Validate("Depreciation Amount", DepreciationAmount);
                ItemDepreciationLine.Validate("Remaining Amount", TotalPrice - AccumulatedDepreciation);
                ItemDepreciationLine.Modify(true);
            until ItemDepreciationLine.Next() = 0;
        end;

    end;
}
