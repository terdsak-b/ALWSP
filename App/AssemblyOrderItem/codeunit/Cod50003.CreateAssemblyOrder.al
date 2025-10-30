namespace ALWSP.ALWSP;
using Microsoft.Assembly.Document;

codeunit 50003 CreateAssemblyOrder
{
    procedure CreateAssemblyOrder(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        AssemblyOrder: Record "Assembly Header";
        Window: Dialog;
        ProcessingMsg: Label 'Creating Assembly Order for #1###############\\Status: @2@@@@@@@@@@@@@';
    begin
        Window.Open(ProcessingMsg);
        Window.Update(1, ItemNo);

        Window.Update(2, 'Initializing...');
        AssemblyOrder.Init();
        AssemblyOrder."Document Type" := AssemblyOrder."Document Type"::Order;
        AssemblyOrder.Insert(true);
        AssemblyOrder.Validate("Due Date", WorkDate() + 1);

        // Set Due Date to next day

        Window.Update(2, 'Validating...');
        AssemblyOrder.Validate("Item No.", ItemNo);


        Window.Update(2, 'Creating Assembly Order...');
        AssemblyOrder.Validate(Quantity, Quantity);
        AssemblyOrder.Modify(true);

        Window.Update(2, StrSubstNo('Completed - Order No. %1', AssemblyOrder."No."));
        Sleep(500);
        Window.Close();

        exit(AssemblyOrder."No."); // Return Assembly Order No
    end;

}
