# App & Test Requirements - Batch Comment Update Feature

## 🎯 New Feature to Build

**Feature Name**: Batch ESD Comment Update  
**Purpose**: Update ESD comments for multiple customers/vendors at once  
**Skill Level**: Intermediate  
**Estimated Time**: 4-6 hours

---

## 📝 App Requirements

### 1. Create Table: Batch Comment Update Buffer (Table 50110)
```al
table 50110 "Batch Comment Update Buffer"
{
    TableType = Temporary;
    
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Entity Type"; Enum "Comment Entity Type") { }  // Customer, Vendor
        field(3; "Entity No."; Code[20]) { }
        field(4; "Entity Name"; Text[100]) { }
        field(5; "Old Comment"; Text[100]) { }
        field(6; "New Comment"; Text[100]) { }
        field(7; "Transfer Comment"; Boolean) { }
        field(8; Selected; Boolean) { }
    }
}
```

### 2. Create Enum: Comment Entity Type (Enum 50100)
```al
enum 50100 "Comment Entity Type"
{
    value(0; Customer) { }
    value(1; Vendor) { }
}
```

### 3. Create Page: Batch Comment Update (Page 50110)
```al
page 50110 "Batch Comment Update"
{
    PageType = List;
    SourceTable = "Batch Comment Update Buffer";
    
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Selected; Rec.Selected) { }
                field("Entity Type"; Rec."Entity Type") { Editable = false; }
                field("Entity No."; Rec."Entity No.") { Editable = false; }
                field("Entity Name"; Rec."Entity Name") { Editable = false; }
                field("Old Comment"; Rec."Old Comment") { Editable = false; }
                field("New Comment"; Rec."New Comment") { }
                field("Transfer Comment"; Rec."Transfer Comment") { }
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
            
            action(SelectAll)
            {
                Caption = 'Select All';
                Image = SelectAll;
                
                trigger OnAction()
                begin
                    SelectAllLines(true);
                end;
            }
            
            action(DeselectAll)
            {
                Caption = 'Deselect All';
                Image = CancelAllLines;
                
                trigger OnAction()
                begin
                    SelectAllLines(false);
                end;
            }
            
            action(ApplyChanges)
            {
                Caption = 'Apply Changes';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                
                trigger OnAction()
                begin
                    ApplyBatchUpdate();
                end;
            }
        }
    }
    
    local procedure LoadEntities(EntityType: Enum "Comment Entity Type")
    begin
        // TODO: Implement loading logic
    end;
    
    local procedure SelectAllLines(DoSelect: Boolean)
    begin
        // TODO: Implement select/deselect all
    end;
    
    local procedure ApplyBatchUpdate()
    begin
        // TODO: Implement batch update
    end;
}
```

### 4. Create Codeunit: Batch Comment Management (Codeunit 50110)
```al
codeunit 50110 "Batch Comment Management"
{
    procedure LoadCustomers(var Buffer: Record "Batch Comment Update Buffer")
    var
        Customer: Record Customer;
        EntryNo: Integer;
    begin
        Buffer.DeleteAll();
        EntryNo := 0;
        
        if Customer.FindSet() then
            repeat
                EntryNo += 1;
                Buffer.Init();
                Buffer."Entry No." := EntryNo;
                Buffer."Entity Type" := Buffer."Entity Type"::Customer;
                Buffer."Entity No." := Customer."No.";
                Buffer."Entity Name" := Customer.Name;
                Buffer."Old Comment" := Customer."ESD Comment";
                Buffer."New Comment" := Customer."ESD Comment";
                Buffer."Transfer Comment" := Customer."Transfer Comment";
                Buffer.Selected := false;
                Buffer.Insert();
            until Customer.Next() = 0;
    end;
    
    procedure LoadVendors(var Buffer: Record "Batch Comment Update Buffer")
    var
        Vendor: Record Vendor;
        EntryNo: Integer;
    begin
        Buffer.DeleteAll();
        EntryNo := 0;
        
        if Vendor.FindSet() then
            repeat
                EntryNo += 1;
                Buffer.Init();
                Buffer."Entry No." := EntryNo;
                Buffer."Entity Type" := Buffer."Entity Type"::Vendor;
                Buffer."Entity No." := Vendor."No.";
                Buffer."Entity Name" := Vendor.Name;
                Buffer."Old Comment" := Vendor."ESD Comment";
                Buffer."New Comment" := Vendor."ESD Comment";
                Buffer."Transfer Comment" := Vendor."Transfer Comment";
                Buffer.Selected := false;
                Buffer.Insert();
            until Vendor.Next() = 0;
    end;
    
    procedure ApplyUpdates(var Buffer: Record "Batch Comment Update Buffer"): Integer
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        UpdateCount: Integer;
    begin
        UpdateCount := 0;
        
        Buffer.SetRange(Selected, true);
        if Buffer.FindSet() then
            repeat
                case Buffer."Entity Type" of
                    Buffer."Entity Type"::Customer:
                        if Customer.Get(Buffer."Entity No.") then begin
                            Customer.Validate("ESD Comment", Buffer."New Comment");
                            Customer.Validate("Transfer Comment", Buffer."Transfer Comment");
                            Customer.Modify(true);
                            UpdateCount += 1;
                        end;
                        
                    Buffer."Entity Type"::Vendor:
                        if Vendor.Get(Buffer."Entity No.") then begin
                            Vendor.Validate("ESD Comment", Buffer."New Comment");
                            Vendor.Validate("Transfer Comment", Buffer."Transfer Comment");
                            Vendor.Modify(true);
                            UpdateCount += 1;
                        end;
                end;
            until Buffer.Next() = 0;
            
        exit(UpdateCount);
    end;
    
    procedure ValidateCommentLength(Comment: Text[100]): Boolean
    begin
        exit(StrLen(Comment) <= 100);
    end;
    
    procedure ValidateHasSelection(var Buffer: Record "Batch Comment Update Buffer"): Boolean
    begin
        Buffer.SetRange(Selected, true);
        exit(not Buffer.IsEmpty);
    end;
}
```

---

## 🧪 Test Requirements

### Create Test Codeunit: Batch Comment Update Test (Codeunit 50110)

```al
codeunit 50110 "Batch Comment Update Test"
{
    Subtype = Test;
    
    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        
    [Test]
    procedure TestLoadCustomersIntoBuffer()
    var
        Customer: Record Customer;
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
        CustomerCount: Integer;
    begin
        // [SCENARIO] Load customers into batch update buffer
        
        // [GIVEN] 3 customers with ESD comments
        CreateCustomersWithComments(3);
        Customer.SetFilter("ESD Comment", '<>%1', '');
        CustomerCount := Customer.Count();
        
        // [WHEN] Loading customers into buffer
        BatchMgt.LoadCustomers(Buffer);
        
        // [THEN] Buffer should contain all customers
        Assert.AreEqual(CustomerCount, Buffer.Count(), 'Buffer should have same count as customers');
        
        // [THEN] Each buffer entry should have correct entity type
        if Buffer.FindSet() then
            repeat
                Assert.AreEqual(Buffer."Entity Type"::Customer, Buffer."Entity Type", 'Entity type should be Customer');
            until Buffer.Next() = 0;
    end;
    
    [Test]
    procedure TestLoadVendorsIntoBuffer()
    var
        Vendor: Record Vendor;
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
        VendorCount: Integer;
    begin
        // [SCENARIO] Load vendors into batch update buffer
        
        // [GIVEN] 3 vendors with ESD comments
        CreateVendorsWithComments(3);
        Vendor.SetFilter("ESD Comment", '<>%1', '');
        VendorCount := Vendor.Count();
        
        // [WHEN] Loading vendors into buffer
        BatchMgt.LoadVendors(Buffer);
        
        // [THEN] Buffer should contain all vendors
        Assert.AreEqual(VendorCount, Buffer.Count(), 'Buffer should have same count as vendors');
        
        // [THEN] Each buffer entry should have correct entity type
        if Buffer.FindSet() then
            repeat
                Assert.AreEqual(Buffer."Entity Type"::Vendor, Buffer."Entity Type", 'Entity type should be Vendor');
            until Buffer.Next() = 0;
    end;
    
    [Test]
    procedure TestApplyBatchUpdateToCustomers()
    var
        Customer: Record Customer;
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
        NewComment: Text[100];
        UpdateCount: Integer;
    begin
        // [SCENARIO] Apply batch update changes to selected customers
        
        // [GIVEN] Customers in buffer with new comments
        CreateCustomersWithComments(5);
        BatchMgt.LoadCustomers(Buffer);
        
        NewComment := 'Updated Comment ' + LibraryUtility.GenerateRandomText(20);
        
        // Select first 3 records
        Buffer.FindSet();
        repeat
            Buffer.Selected := Buffer."Entry No." <= 3;
            Buffer."New Comment" := NewComment;
            Buffer.Modify();
        until Buffer.Next() = 0;
        
        // [WHEN] Applying batch update
        UpdateCount := BatchMgt.ApplyUpdates(Buffer);
        
        // [THEN] Only 3 records should be updated
        Assert.AreEqual(3, UpdateCount, 'Should update 3 customers');
        
        // [THEN] Updated customers should have new comment
        Customer.SetRange("ESD Comment", NewComment);
        Assert.AreEqual(3, Customer.Count(), 'Should have 3 customers with new comment');
    end;
    
    [Test]
    procedure TestApplyBatchUpdateToVendors()
    var
        Vendor: Record Vendor;
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
        NewComment: Text[100];
        UpdateCount: Integer;
    begin
        // [SCENARIO] Apply batch update changes to selected vendors
        
        // [GIVEN] Vendors in buffer with new comments
        CreateVendorsWithComments(5);
        BatchMgt.LoadVendors(Buffer);
        
        NewComment := 'Updated Comment ' + LibraryUtility.GenerateRandomText(20);
        
        // Select all records
        Buffer.ModifyAll(Selected, true);
        Buffer.ModifyAll("New Comment", NewComment);
        
        // [WHEN] Applying batch update
        UpdateCount := BatchMgt.ApplyUpdates(Buffer);
        
        // [THEN] All 5 records should be updated
        Assert.AreEqual(5, UpdateCount, 'Should update 5 vendors');
        
        // [THEN] All vendors should have new comment
        Vendor.SetRange("ESD Comment", NewComment);
        Assert.AreEqual(5, Vendor.Count(), 'Should have 5 vendors with new comment');
    end;
    
    [Test]
    procedure TestValidateCommentMaxLength()
    var
        BatchMgt: Codeunit "Batch Comment Management";
        ValidComment: Text[100];
        InvalidComment: Text[150];
    begin
        // [SCENARIO] Validate comment length does not exceed 100 characters
        
        // [GIVEN] Valid and invalid comments
        ValidComment := LibraryUtility.GenerateRandomText(100);
        InvalidComment := LibraryUtility.GenerateRandomText(101);
        
        // [WHEN] Validating comments
        // [THEN] Valid comment should pass
        Assert.IsTrue(BatchMgt.ValidateCommentLength(ValidComment), 'Valid comment should pass');
        
        // [THEN] Invalid comment should fail
        Assert.IsFalse(BatchMgt.ValidateCommentLength(InvalidComment), 'Invalid comment should fail');
    end;
    
    [Test]
    procedure TestValidateHasSelection()
    var
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
    begin
        // [SCENARIO] Validate at least one record is selected
        
        // [GIVEN] Buffer with records
        CreateBufferRecords(Buffer, 3, false);
        
        // [WHEN] No records selected
        // [THEN] Should return false
        Assert.IsFalse(BatchMgt.ValidateHasSelection(Buffer), 'Should return false when nothing selected');
        
        // [WHEN] One record selected
        Buffer.FindFirst();
        Buffer.Selected := true;
        Buffer.Modify();
        
        // [THEN] Should return true
        Assert.IsTrue(BatchMgt.ValidateHasSelection(Buffer), 'Should return true when at least one selected');
    end;
    
    [Test]
    procedure TestTransferCommentFlagUpdate()
    var
        Customer: Record Customer;
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
    begin
        // [SCENARIO] Update Transfer Comment flag in batch update
        
        // [GIVEN] Customer with Transfer Comment = false
        LibrarySales.CreateCustomer(Customer);
        Customer."Transfer Comment" := false;
        Customer.Modify();
        
        // [WHEN] Loading and updating via buffer
        BatchMgt.LoadCustomers(Buffer);
        Buffer.FindFirst();
        Buffer.Selected := true;
        Buffer."Transfer Comment" := true;
        Buffer.Modify();
        
        BatchMgt.ApplyUpdates(Buffer);
        
        // [THEN] Customer should have Transfer Comment = true
        Customer.Get(Customer."No.");
        Assert.IsTrue(Customer."Transfer Comment", 'Transfer Comment should be updated to true');
    end;
    
    [Test]
    procedure TestBatchUpdatePreservesOtherFields()
    var
        Customer: Record Customer;
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
        OriginalName: Text[100];
        OriginalAddress: Text[100];
    begin
        // [SCENARIO] Batch update should only modify comment fields, not other data
        
        // [GIVEN] Customer with various fields populated
        LibrarySales.CreateCustomer(Customer);
        OriginalName := Customer.Name;
        OriginalAddress := Customer.Address;
        
        // [WHEN] Updating comment via batch
        BatchMgt.LoadCustomers(Buffer);
        Buffer.FindFirst();
        Buffer.Selected := true;
        Buffer."New Comment" := 'New Comment';
        Buffer.Modify();
        
        BatchMgt.ApplyUpdates(Buffer);
        
        // [THEN] Other fields should remain unchanged
        Customer.Get(Customer."No.");
        Assert.AreEqual(OriginalName, Customer.Name, 'Name should not change');
        Assert.AreEqual(OriginalAddress, Customer.Address, 'Address should not change');
        Assert.AreEqual('New Comment', Customer."ESD Comment", 'Comment should be updated');
    end;
    
    // Helper procedures
    local procedure CreateCustomersWithComments(Count: Integer)
    var
        Customer: Record Customer;
        i: Integer;
    begin
        for i := 1 to Count do begin
            LibrarySales.CreateCustomer(Customer);
            Customer."ESD Comment" := 'Comment ' + Format(i);
            Customer."Transfer Comment" := true;
            Customer.Modify();
        end;
    end;
    
    local procedure CreateVendorsWithComments(Count: Integer)
    var
        Vendor: Record Vendor;
        i: Integer;
    begin
        for i := 1 to Count do begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor."ESD Comment" := 'Comment ' + Format(i);
            Vendor."Transfer Comment" := true;
            Vendor.Modify();
        end;
    end;
    
    local procedure CreateBufferRecords(var Buffer: Record "Batch Comment Update Buffer"; Count: Integer; Selected: Boolean)
    var
        i: Integer;
    begin
        Buffer.DeleteAll();
        for i := 1 to Count do begin
            Buffer.Init();
            Buffer."Entry No." := i;
            Buffer."Entity Type" := Buffer."Entity Type"::Customer;
            Buffer."Entity No." := Format(i);
            Buffer.Selected := Selected;
            Buffer.Insert();
        end;
    end;
}
```

---

## ✅ Checklist

### App Implementation
- [ ] Create Enum 50100 "Comment Entity Type"
- [ ] Create Table 50110 "Batch Comment Update Buffer"
- [ ] Create Codeunit 50110 "Batch Comment Management"
- [ ] Implement LoadCustomers procedure
- [ ] Implement LoadVendors procedure
- [ ] Implement ApplyUpdates procedure with validation
- [ ] Implement ValidateCommentLength procedure
- [ ] Implement ValidateHasSelection procedure
- [ ] Create Page 50110 "Batch Comment Update"
- [ ] Wire up all page actions
- [ ] Add error handling for edge cases
- [ ] Test manually in UI

### Test Implementation
- [ ] Create Test Codeunit 50110 "Batch Comment Update Test"
- [ ] Test: TestLoadCustomersIntoBuffer
- [ ] Test: TestLoadVendorsIntoBuffer
- [ ] Test: TestApplyBatchUpdateToCustomers
- [ ] Test: TestApplyBatchUpdateToVendors
- [ ] Test: TestValidateCommentMaxLength
- [ ] Test: TestValidateHasSelection
- [ ] Test: TestTransferCommentFlagUpdate
- [ ] Test: TestBatchUpdatePreservesOtherFields
- [ ] Add helper procedures
- [ ] Run all tests and verify they pass

---

## 🎯 Learning Objectives

By completing this feature, you will learn:

1. **Temporary Tables** - How to use temporary buffers for UI operations
2. **Enums** - Creating and using enumerations
3. **Batch Operations** - Processing multiple records efficiently
4. **Validation** - Implementing business logic validation
5. **Test Coverage** - Writing comprehensive tests for all scenarios
6. **Helper Methods** - Creating reusable test helper procedures
7. **Page Actions** - Building interactive list pages with actions

---

## 🚀 Bonus Challenges

Once you complete the basic implementation:

1. **Add Filtering**: Allow filtering customers/vendors by specific criteria before loading
2. **Add Undo**: Implement an undo feature to revert changes
3. **Add Preview**: Show preview of changes before applying
4. **Add Logging**: Log all batch updates to a history table
5. **Add Export/Import**: Export buffer to Excel, modify, and import back

---

## 📊 Success Criteria

- ✅ All 8 test cases pass
- ✅ Can load customers and vendors into buffer
- ✅ Can select/deselect records
- ✅ Can update multiple records at once
- ✅ Validation prevents invalid data
- ✅ Other fields are not affected by batch update
- ✅ UI is responsive and user-friendly
