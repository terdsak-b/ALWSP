namespace ALWSP.ALWSP;

report 50000 "Calculate Depreciation"
{
    Caption = 'Calculate Depreciation';
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(ItemDepreciation; "Item Depreciation")
        {
            column(Total_Price; "Total Price") { }
            column(Carcass_value; "Carcass value") { }
            column(Year_of_Depreciation; "Year of Depreciation") { }
            column(Purchase_Date; "Purchase Date") { }
            column(Last_Depreciation_Date; "Last Depreciation Date") { }

            trigger OnPreDataItem()
            begin
                GlobalItemDepreciationManagement.FilterItemDepreciationInList(ItemDepreciation, GlobalFilterList);
            end;

            trigger OnPostDataItem()
            var
                ItemNo: Text;
                CompletionMessage: Label 'Processing completed. Record updated.';
                ErrorMsg: Label 'No records found for the given criteria.';
            begin
                if not GlobalFilterList.Contains(ItemDepreciation."Item No.") then begin
                    Error(ErrorMsg);
                    Page.Run(Page::"Item Depreciation List");
                    exit;

                end;

                if GlobalFilterList.Count = 1 then begin
                    GlobalItemDepreciationManagement.UpdateItemDepreciationRecordHeader(ItemDepreciation,
                                                                           GlobalTotalPrice,
                                                                           GlobalCarcassValue,
                                                                           GlobalYearOfDepreciation,
                                                                           GlobalPurchaseDate,
                                                                           GlobalLastDepreciationDate);
                    GlobalItemDepreciationManagement.UpdateItemDepreciationRecordLineAndCalculationRemainingAmountHeader(ItemDepreciation,
                                                                            GlobalTotalPrice,
                                                                            GlobalCarcassValue,
                                                                            GlobalYearOfDepreciation,
                                                                            GlobalPurchaseDate);

                    Page.Run(Page::ItemDepreciationCard, ItemDepreciation);
                end else begin
                    foreach ItemNo in GlobalFilterList do begin
                        ItemDepreciation.SetRange("Item No.", ItemNo);
                        if ItemDepreciation.FindFirst() then begin
                            if ItemDepreciation."Item Type" <> "Depreciation Item Type"::FA then
                                continue; // Skip non-fixed asset items

                            GlobalItemDepreciationManagement.UpdateItemDepreciationRecordHeader(ItemDepreciation,
                                                                           ItemDepreciation."Total Price",
                                                                           ItemDepreciation."Carcass value",
                                                                           ItemDepreciation."Year of Depreciation",
                                                                           ItemDepreciation."Purchase Date",
                                                                           ItemDepreciation."Last Depreciation Date");
                            GlobalItemDepreciationManagement.UpdateItemDepreciationRecordLineAndCalculationRemainingAmountHeader(ItemDepreciation,
                                                                            ItemDepreciation."Total Price",
                                                                            ItemDepreciation."Carcass value",
                                                                            ItemDepreciation."Year of Depreciation",
                                                                            ItemDepreciation."Purchase Date");
                        end;

                    end;

                    Page.Run(Page::"Item Depreciation List");
                end;

                Message(CompletionMessage);
            end;

        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {
                group(ItemDepreciation)
                {
                    Caption = 'ESD-Fixed Asset';
                    field("Total Price"; GlobalTotalPrice)
                    {
                        ApplicationArea = All;
                    }
                    field("Carcass value"; GlobalCarcassValue)
                    {
                        ApplicationArea = All;
                    }
                    field("Year of Depreciation"; GlobalYearOfDepreciation)
                    {
                        ApplicationArea = All;
                    }
                    field("Purchase Date"; GlobalPurchaseDate)
                    {
                        ApplicationArea = All;
                    }
                    field("Last Depreciation Date"; GlobalLastDepreciationDate)
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if ItemDepreciation.FindFirst() then begin
                GlobalPurchaseDate := ItemDepreciation."Purchase Date";
                GlobalTotalPrice := ItemDepreciation."Total Price";
                GlobalCarcassValue := ItemDepreciation."Carcass value";
                GlobalYearOfDepreciation := ItemDepreciation."Year of Depreciation";
                GlobalLastDepreciationDate := ItemDepreciation."Last Depreciation Date";
            end;

        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = Action::Cancel then begin
                if GlobalSourcePageID = Page::ItemDepreciationCard then
                    Page.Run(Page::ItemDepreciationCard, ItemDepreciation)
                else
                    Page.Run(Page::"Item Depreciation List");
            end;
        end;
    }

    procedure SetSourcePage(SourcePageID: Integer)
    begin
        GlobalSourcePageID := SourcePageID;
    end;

    var
        GlobalItemDepreciationManagement: Codeunit "ItemDepreciationManagement";
        GlobalLastDepreciationDate: Date;
        GlobalPurchaseDate: Date;
        GlobalCarcassValue: Decimal;
        GlobalTotalPrice: Decimal;
        GlobalSourcePageID: Integer;
        GlobalYearOfDepreciation: Integer;
        GlobalFilterList: List of [Text];
}
