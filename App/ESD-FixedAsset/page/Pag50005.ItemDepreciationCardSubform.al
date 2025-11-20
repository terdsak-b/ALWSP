namespace ALWSP.ALWSP;

page 50005 "Item Depreciation Card Subform"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = ItemDepreciationLine;
    SourceTableView = where("Source Type" = const(FA));

    layout
    {
        area(Content)
        {
            repeater(Control)
            {
                ShowCaption = false;
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Year"; Rec."No. of Year")
                {
                    ApplicationArea = All;
                }
                field("Depreciation Amount"; Rec."Depreciation Amount")
                {
                    ApplicationArea = All;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = All;
                }
                field(Jan; Rec.Jan)
                {
                    ApplicationArea = All;
                }
                field(Feb; Rec.Feb)
                {
                    ApplicationArea = All;
                }
                field(Mar; Rec.Mar)
                {
                    ApplicationArea = All;
                }
                field(Apr; Rec.Apr)
                {
                    ApplicationArea = All;
                }
                field(May; Rec.May)
                {
                    ApplicationArea = All;
                }
                field(Jun; Rec.Jun)
                {
                    ApplicationArea = All;
                }
                field(Jul; Rec.Jul)
                {
                    ApplicationArea = All;
                }
                field(Aug; Rec.Aug)
                {
                    ApplicationArea = All;
                }
                field(Sep; Rec.Sep)
                {
                    ApplicationArea = All;
                }
                field(Oct; Rec.Oct)
                {
                    ApplicationArea = All;
                }
                field(Nov; Rec.Nov)
                {
                    ApplicationArea = All;
                }
                field(Dec; Rec.Dec)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
