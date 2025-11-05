namespace ALWSP.ALWSP;

page 50000 "Batch Comment Update"
{
    ApplicationArea = All;
    Caption = 'Batch Comment Update';
    PageType = List;
    SourceTable = "Batch Comment Update Buffer";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Status"; Rec."Status Indicator")
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Shows ● when record has been edited but not applied';
                    Style = Attention;
                    StyleExpr = Rec.Modified;
                }
                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Entity No."; Rec."Entity No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Old Comment"; Rec."Old Comment")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("New Comment"; Rec."New Comment")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Rec.Modified;

                    trigger OnValidate()
                    begin
                        Rec.Modified := (Rec."New Comment" <> xRec."New Comment");
                        Rec.CalcFields();
                        CurrPage.Update(false);
                    end;
                }
                field("Transfer Comment"; Rec."Transfer Comment")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = Rec.Modified;

                    trigger OnValidate()
                    begin
                        Rec.Modified := true;
                        Rec.CalcFields();
                        CurrPage.Update(false);
                    end;
                }

            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(LoadCustomers)
            {
                Caption = 'Load Customers';
                Image = Customer;

                trigger OnAction()
                begin
                    LoadEntities("Comment Entity Type"::Customer);
                end;
            }

            action(LoadVendors)
            {
                Caption = 'Load Vendors';
                Image = Vendor;

                trigger OnAction()
                begin
                    LoadEntities("Comment Entity Type"::Vendor);
                end;
            }

            action(ApplyChanges)
            {
                Caption = 'Apply Changes';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TempRec: Record "Batch Comment Update Buffer" temporary;
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    GlobalBatchCommentManagement.ApplyBatchUpdate(Rec);

                    // Clear modified marks after applying
                    if Rec.FindSet() then
                        repeat
                            Rec.Modified := false;
                            Rec.CalcFields();
                            Rec.Modify();
                        until Rec.Next() = 0;
                    CurrPage.Update(true);
                end;
            }
            action(DeleteComment)
            {
                Caption = 'Delete Comment';
                Image = CloseDocument;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Rec);

                    GlobalBatchCommentManagement.DeleteComment(Rec);

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec.Reset();
        Rec.DeleteAll();
        GlobalBatchCommentManagement.LoadDefaultRecords(Rec);
    end;

    var
        GlobalBatchCommentManagement: Codeunit "Batch Comment Management";


    local procedure LoadEntities(EntityType: Enum "Comment Entity Type")
    begin
        if EntityType = EntityType::Customer then begin
            GlobalBatchCommentManagement.LoadCustomers(Rec);
        end else if EntityType = EntityType::Vendor then begin
            GlobalBatchCommentManagement.LoadVendors(Rec);
        end;
    end;
}