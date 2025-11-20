namespace ALWSP.ALWSP;
page 50003 "Item Depreciation List"
{
    ApplicationArea = All;
    Caption = 'ESD-Fixed Asset List';
    CardPageId = ItemDepreciationCard;
    PageType = List;
    SourceTable = "Item Depreciation";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Control)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Item Type"; Rec."Item Type")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        UpdateEditableFields();
                    end;
                }
                field("Item Name"; Rec."Item Name")
                {
                    ApplicationArea = All;
                }
                field("Purchase Date"; Rec."Purchase Date")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    trigger OnValidate()
                    var
                        ErrorMsg: Label 'Purchase Date cannot be blank.';
                    begin
                        if Rec."Purchase Date" = 0D then
                            Error(ErrorMsg);
                    end;
                }
                field("Last Depreciation Date"; Rec."Last Depreciation Date")
                {
                    ApplicationArea = All;
                    Editable = GlobalCheckItemType;
                }
                field("Total Price"; Rec."Total Price")
                {
                    ApplicationArea = All;
                }
                field("Carcass value"; Rec."Carcass value")
                {
                    ApplicationArea = All;
                    Editable = GlobalCheckItemType;
                }
                field("Year of Depreciation"; Rec."Year of Depreciation")
                {
                    ApplicationArea = All;
                    Editable = GlobalCheckItemType;
                }
                field("Remainning Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = All;
                }
            }
        }

    }
    actions
    {
        area(Processing)
        {
            action(CalculateDepreciation)
            {
                ApplicationArea = Planning;
                Caption = 'Calculate Depreciation';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    CalculateDepreciationReport: Report "Calculate Depreciation";
                    ErrorMsg: Label 'Depreciation calculation is only available for Fixed Assets (FA) item type.';
                begin
                    if Rec."Item Type" <> Rec."Item Type"::FA then
                        Error(ErrorMsg);

                    CurrPage.SetSelectionFilter(Rec);
                    CalculateDepreciationReport.SetSourcePage(Page::"Item Depreciation List");
                    CalculateDepreciationReport.SetTableView(Rec);
                    CalculateDepreciationReport.RunModal();
                    CurrPage.Close();
                end;
            }

        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEditableFields();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateEditableFields();
    end;

    var
        GlobalCheckItemType: Boolean;

    local procedure ClearData()
    begin
        Rec."Carcass value" := 0;
        Rec."Year of Depreciation" := 0;
        Rec."Last Depreciation Date" := 0D;
        Rec."Remaining Amount" := 0;
        Rec.Modify();
    end;

    local procedure UpdateEditableFields()
    begin
        if Rec."Item Type" = Rec."Item Type"::FA then
            GlobalCheckItemType := true
        else begin
            GlobalCheckItemType := false;
            ClearData();
        end;

    end;
}
