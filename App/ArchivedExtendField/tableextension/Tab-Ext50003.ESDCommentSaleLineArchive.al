namespace ALWSP.ALWSP;

using Microsoft.Sales.Archive;

tableextension 50003 ESDCommentSaleLineArchive extends "Sales Line Archive"
{
    fields
    {
        field(50100; "ESD Comment"; Text[100])
        {
            Caption = 'ESD Comment';
            DataClassification = ToBeClassified;
        }
    }
}
