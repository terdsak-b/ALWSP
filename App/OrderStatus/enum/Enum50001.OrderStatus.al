namespace ALWSP.ALWSP;

enum 50001 "Order Status"
{
    Extensible = true;
    
    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Partial)
    {
        Caption = 'Partial';
    }
    value(2; Completed)
    {
        Caption = 'Completed';
    }
}
