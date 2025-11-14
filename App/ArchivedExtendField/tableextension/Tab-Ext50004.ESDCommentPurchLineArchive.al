namespace ALWSP.ALWSP;

using Microsoft.Purchases.Archive;

tableextension 50004 ESDCommentPurchLineArchive extends "Purchase Line Archive"
{
    fields
    {
        field(50100; "ESD Commnet"; Text[100])
        {
            Caption = 'ESD Commnet';
            DataClassification = ToBeClassified;
        }
    }
}
