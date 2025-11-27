# Business Central AL Development Workshop
## Complete Guide to Building Custom Extensions

---

## 📚 Workshop Overview

This workshop is based on a real-world Business Central AL extension project (ALWSP) that demonstrates multiple custom features and best practices for AL development. The project showcases essential patterns for extending Business Central functionality including table extensions, page extensions, custom business logic, and comprehensive testing.

**Target Audience**: Intermediate AL Developers  
**Duration**: 8-12 hours (self-paced)  
**Prerequisites**: 
- Basic AL syntax knowledge
- Business Central development environment setup
- Understanding of Business Central base tables (Customer, Vendor, Item, Sales, Purchase)

---

## 🎯 Workshop Objectives

By completing this workshop, you will learn to:

1. ✅ Extend Business Central base tables with custom fields
2. ✅ Create custom business logic using codeunits and event subscribers
3. ✅ Build user interfaces with pages and page extensions
4. ✅ Implement data validation and business rules
5. ✅ Create temporary tables for UI buffers
6. ✅ Write comprehensive unit tests
7. ✅ Organize AL projects with proper folder structure
8. ✅ Use enums for type-safe options
9. ✅ Implement batch operations
10. ✅ Handle data transfer between related entities

---

## 📁 Project Structure

```
ALWSP/
├── App/                              # Main application code
│   ├── BatchCommentUpdate/          # Feature: Batch update ESD comments
│   ├── ESDComment/                  # Feature: ESD comment tracking
│   ├── LookupValue/                 # Feature: Custom lookup values
│   ├── OrderStatus/                 # Feature: Order status tracking
│   ├── ReplacementItem/             # Feature: Replacement item management
│   ├── InventorybyLocation/         # Feature: Inventory location views
│   ├── Manufacturing Process/       # Feature: Manufacturing workflows
│   ├── ESD-FixedAsset/             # Feature: Fixed asset extensions
│   └── AssemblyOrderItem/          # Feature: Assembly order management
├── Test/                            # Test codeunits
├── Libraries/                       # Reusable test libraries
├── app.json                        # Extension manifest
└── REQUIREMENTS.md                 # Detailed requirements
```

**Key Patterns**:
- Each feature has its own folder with subfolders: `table/`, `tableextension/`, `page/`, `pageextension/`, `codeunit/`, `enum/`
- Consistent naming conventions: `Tab-Ext50100`, `Pag-Ext50100`, `Cod50100`
- Clear separation between app code, tests, and libraries

---

## 🧩 Module 1: ESD Comment System
### Building a Comment Transfer System

**Feature Overview**: Automatically transfer comments from Customers/Vendors to their Sales/Purchase Lines.

### 📋 What You'll Build

1. **Table Extensions** - Add comment fields to Customer and Vendor tables
2. **Event Subscribers** - Listen to line creation events and copy comments
3. **Page Extensions** - Display comment fields on Customer/Vendor cards
4. **Configuration** - Add optional confirmation dialog

### Step-by-Step Implementation

#### 1.1 Extend Customer Table

```al
tableextension 50100 ESDCommentCustomer extends Customer
{
    fields
    {
        field(50100; "Transfer Comment"; Boolean)
        {
            Caption = 'Transfer Comment';
            DataClassification = ToBeClassified;
        }
        field(50101; "ESD Comment"; Text[100])
        {
            Caption = 'ESD Comment';
            DataClassification = ToBeClassified;
        }
    }
}
```

**Key Concepts**:
- Table extensions add fields without modifying base tables
- Field IDs must be within your assigned range (50000-90000)
- DataClassification is mandatory for data privacy compliance

#### 1.2 Extend Vendor Table

```al
tableextension 50101 ESDCommentVendor extends Vendor
{
    fields
    {
        field(50100; "Transfer Comment"; Boolean)
        {
            Caption = 'Transfer Comment';
            DataClassification = ToBeClassified;
        }
        field(50101; "ESD Comment"; Text[100])
        {
            Caption = 'ESD Comment';
            DataClassification = ToBeClassified;
        }
    }
}
```

#### 1.3 Extend Sales Line and Purchase Line

```al
tableextension 50102 ESDCommentSalesLine extends "Sales Line"
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

tableextension 50103 ESDCommentPurchaseLine extends "Purchase Line"
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
```

#### 1.4 Create Transfer Logic (Codeunit)

```al
codeunit 50100 TransferESDComment
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInitHeaderDefaults', '', false, false)]
    local procedure CopyCustomerComments(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        if not Customer."Transfer Comment" then
            exit;

        SalesLine."ESD Comment" := Customer."ESD Comment";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitHeaderDefaults', '', false, false)]
    local procedure CopyVendorComments(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(PurchHeader."Buy-from Vendor No.") then
            exit;

        if not Vendor."Transfer Comment" then
            exit;

        PurchLine."ESD Comment" := Vendor."ESD Comment";
    end;
}
```

**Key Concepts**:
- Event Subscribers listen to standard BC events without modifying base code
- `OnAfterInitHeaderDefaults` fires when a new line is created from a header
- Check if transfer is enabled before copying comments

#### 1.5 Add UI Extensions

```al
pageextension 50100 ESDCommentCustomer extends "Customer Card"
{
    layout
    {
        addafter(Name)
        {
            field("ESD Comment"; Rec."ESD Comment")
            {
                ApplicationArea = All;
            }
            field("Transfer Comment"; Rec."Transfer Comment")
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 50102 ESDCmtSalesOrderSubform extends "Sales Order Subform"
{
    layout
    {
        addafter(Description)
        {
            field("ESD Comment"; Rec."ESD Comment")
            {
                ApplicationArea = All;
            }
        }
    }
}
```

### 🎯 Exercise 1: Enhance the Comment System

**Tasks**:
1. Add a comment history table to track all comment changes
2. Implement validation to prevent empty comments when "Transfer Comment" is true
3. Add a page action to bulk enable/disable "Transfer Comment" for multiple customers
4. Create a report showing all customers/vendors with comments

---

## 🧩 Module 2: Batch Comment Update System
### Building a Batch Processing UI

**Feature Overview**: Update ESD comments for multiple customers or vendors simultaneously through a batch update interface.

### 📋 What You'll Build

1. **Enum** - Entity type selector (Customer/Vendor)
2. **Temporary Table** - UI buffer for batch operations
3. **Codeunit** - Business logic for loading and updating
4. **Page** - Interactive list page with actions

### Step-by-Step Implementation

#### 2.1 Create Entity Type Enum

```al
enum 50100 "Comment Entity Type"
{
    Extensible = true;
    
    value(0; Customer)
    {
        Caption = 'Customer';
    }
    value(1; Vendor)
    {
        Caption = 'Vendor';
    }
}
```

**Key Concepts**:
- Enums provide type-safe option fields
- `Extensible = true` allows other extensions to add values
- Better than Option fields (easier to maintain, refactor-friendly)

#### 2.2 Create Temporary Buffer Table

```al
table 50000 "Batch Comment Update Buffer"
{
    Caption = 'Batch Comment Update Buffer';
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Entity Type"; Enum "Comment Entity Type")
        {
            Caption = 'Entity Type';
        }
        field(3; "Entity No."; Code[20])
        {
            Caption = 'Entity No.';
        }
        field(4; "Entity Name"; Text[100])
        {
            Caption = 'Entity Name';
        }
        field(5; "Old Comment"; Text[100])
        {
            Caption = 'Old Comment';
        }
        field(6; "New Comment"; Text[100])
        {
            Caption = 'New Comment';
        }
        field(7; "Transfer Comment"; Boolean)
        {
            Caption = 'Transfer Comment';
        }
        field(8; "Modified"; Boolean)
        {
            Caption = 'Modified';
        }
        field(9; "Status Indicator"; Text[10])
        {
            Caption = 'Status';
            Editable = false;
        }
    }
    
    keys
    {
        key(PK; "Entry No.", "Entity Type", "Entity No.")
        {
            Clustered = true;
        }
    }

    procedure CalcFields()
    begin
        if Rec.Modified then
            Rec."Status Indicator" := '● Modified'
        else
            Rec."Status Indicator" := '';
    end;
}
```

**Key Concepts**:
- `TableType = Temporary` - exists only in memory, not in database
- Perfect for UI buffers and intermediate processing
- Includes status tracking for user feedback

#### 2.3 Create Management Codeunit

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
                Buffer."Modified" := false;
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
                Buffer."Modified" := false;
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
        
        Buffer.SetRange(Modified, true);
        if Buffer.FindSet() then
            repeat
                case Buffer."Entity Type" of
                    Buffer."Entity Type"::Customer:
                        if Customer.Get(Buffer."Entity No.") then begin
                            Customer."ESD Comment" := Buffer."New Comment";
                            Customer."Transfer Comment" := Buffer."Transfer Comment";
                            Customer.Modify(true);
                            UpdateCount += 1;
                        end;
                    Buffer."Entity Type"::Vendor:
                        if Vendor.Get(Buffer."Entity No.") then begin
                            Vendor."ESD Comment" := Buffer."New Comment";
                            Vendor."Transfer Comment" := Buffer."Transfer Comment";
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
        Buffer.SetRange(Modified, true);
        exit(not Buffer.IsEmpty);
    end;
}
```

**Key Concepts**:
- Separate loading logic by entity type
- Track modifications explicitly
- Return counts for user feedback
- Include validation methods

#### 2.4 Create Batch Update Page

```al
page 50110 "Batch Comment Update"
{
    PageType = List;
    SourceTable = "Batch Comment Update Buffer";
    SourceTableTemporary = true;
    Caption = 'Batch Comment Update';
    
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Status Indicator"; Rec."Status Indicator")
                {
                    ApplicationArea = All;
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
                    Style = Attention;
                }
                field("New Comment"; Rec."New Comment")
                {
                    ApplicationArea = All;
                    
                    trigger OnValidate()
                    begin
                        if Rec."New Comment" <> Rec."Old Comment" then
                            Rec."Modified" := true
                        else
                            Rec."Modified" := false;
                        Rec.CalcFields();
                    end;
                }
                field("Transfer Comment"; Rec."Transfer Comment")
                {
                    ApplicationArea = All;
                    
                    trigger OnValidate()
                    begin
                        Rec."Modified" := true;
                        Rec.CalcFields();
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
                Promoted = true;
                PromotedCategory = Process;
                
                trigger OnAction()
                var
                    BatchMgt: Codeunit "Batch Comment Management";
                begin
                    BatchMgt.LoadCustomers(Rec);
                    CurrPage.Update(false);
                end;
            }
            
            action(LoadVendors)
            {
                Caption = 'Load Vendors';
                Image = Vendor;
                Promoted = true;
                PromotedCategory = Process;
                
                trigger OnAction()
                var
                    BatchMgt: Codeunit "Batch Comment Management";
                begin
                    BatchMgt.LoadVendors(Rec);
                    CurrPage.Update(false);
                end;
            }
            
            action(ApplyChanges)
            {
                Caption = 'Apply Changes';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                
                trigger OnAction()
                var
                    BatchMgt: Codeunit "Batch Comment Management";
                    UpdateCount: Integer;
                begin
                    if not BatchMgt.ValidateHasSelection(Rec) then
                        Error('No records have been modified. Please make changes before applying.');
                    
                    if not Confirm('Do you want to apply changes to %1 record(s)?', false, GetModifiedCount()) then
                        exit;
                    
                    UpdateCount := BatchMgt.ApplyUpdates(Rec);
                    Message('%1 record(s) updated successfully.', UpdateCount);
                    
                    CurrPage.Close();
                end;
            }
        }
    }
    
    local procedure GetModifiedCount(): Integer
    var
        TempBuffer: Record "Batch Comment Update Buffer" temporary;
    begin
        TempBuffer.Copy(Rec, true);
        TempBuffer.SetRange(Modified, true);
        exit(TempBuffer.Count);
    end;
}
```

**Key Concepts**:
- `SourceTableTemporary = true` for temporary tables
- Field validation triggers mark records as modified
- Actions load data and apply changes
- User confirmation before applying updates
- Visual feedback with status indicators

### 🎯 Exercise 2: Enhance Batch Operations

**Tasks**:
1. Add filtering capabilities (by name, by existing comment)
2. Add a "Clear All Comments" bulk action
3. Add undo functionality to revert changes
4. Export buffer to Excel for offline editing
5. Add a preview mode showing what will change

---

## 🧩 Module 3: Lookup Value System
### Building Custom Dropdown Lists

**Feature Overview**: Create a reusable lookup value system that can be used across multiple entities.

### 📋 What You'll Build

1. **Master Table** - Store lookup values
2. **Table Extensions** - Add lookup fields to various entities
3. **Event Subscribers** - Auto-populate lookup values during transactions
4. **Page** - Manage lookup values

### Implementation Highlights

```al
table 70000 "LookupValue"
{
    Caption = 'Lookup Value';
    DataClassification = ToBeClassified;
    LookupPageId = "LookupValues";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
    }
    
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
```

**Use Cases**:
- Customer classifications
- Sales categories
- Priority levels
- Custom status codes

### 🎯 Exercise 3: Extend Lookup System

**Tasks**:
1. Add a "Type" field to categorize lookup values
2. Create different lookup pages for different types
3. Add validation to prevent deletion of in-use values
4. Create a report showing lookup value usage statistics

---

## 🧩 Module 4: Order Status Tracking
### Enum-Based Status Management

**Feature Overview**: Track order status (Open/Partial/Completed) on sales and purchase lines.

### Step-by-Step Implementation

#### 4.1 Create Status Enum

```al
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
```

#### 4.2 Extend Sales and Purchase Lines

```al
tableextension 50001 SalesLineStatus extends "Sales Line"
{
    fields
    {
        field(50001; "Order Status"; Enum "Order Status")
        {
            Caption = 'Order Status';
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }
}

tableextension 50002 PurchLineStatus extends "Purchase Line"
{
    fields
    {
        field(50001; "Order Status"; Enum "Order Status")
        {
            Caption = 'Order Status';
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }
}
```

#### 4.3 Auto-Calculate Status

```al
codeunit 50009 "Order Status Management"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'Quantity Shipped', false, false)]
    local procedure UpdateSalesLineStatus(var Rec: Record "Sales Line")
    begin
        if Rec."Quantity Shipped" = 0 then
            Rec."Order Status" := Rec."Order Status"::Open
        else if Rec."Quantity Shipped" < Rec.Quantity then
            Rec."Order Status" := Rec."Order Status"::Partial
        else
            Rec."Order Status" := Rec."Order Status"::Completed;
    end;
    
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'Quantity Received', false, false)]
    local procedure UpdatePurchLineStatus(var Rec: Record "Purchase Line")
    begin
        if Rec."Quantity Received" = 0 then
            Rec."Order Status" := Rec."Order Status"::Open
        else if Rec."Quantity Received" < Rec.Quantity then
            Rec."Order Status" := Rec."Order Status"::Partial
        else
            Rec."Order Status" := Rec."Order Status"::Completed;
    end;
}
```

### 🎯 Exercise 4: Enhance Status Tracking

**Tasks**:
1. Add more status values (Cancelled, On Hold, Backordered)
2. Create a statistics page showing order status summary
3. Add filtering by status on order list pages
4. Create alerts when orders stay in Partial status too long

---

## 🧩 Module 5: Replacement Item Management
### Building Item Relationships

**Feature Overview**: Define replacement items and suggest them when original items are out of stock.

### Implementation

```al
tableextension 50000 ReplacementItem extends Item
{
    fields
    {
        field(50000; "Replacement Item"; Code[20])
        {
            Caption = 'Replacement Item';
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
    }
}

codeunit 50007 "Replacement Item Mgt"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure SuggestReplacementItem(var Rec: Record "Sales Line")
    var
        Item: Record Item;
        ReplacementItem: Record Item;
    begin
        if Rec.Type <> Rec.Type::Item then
            exit;
            
        if not Item.Get(Rec."No.") then
            exit;
            
        if Item."Replacement Item" = '' then
            exit;
            
        // Check if current item is out of stock
        Item.CalcFields(Inventory);
        if Item.Inventory >= Rec.Quantity then
            exit;
            
        if not ReplacementItem.Get(Item."Replacement Item") then
            exit;
            
        // Check if replacement has stock
        ReplacementItem.CalcFields(Inventory);
        if ReplacementItem.Inventory < Rec.Quantity then
            exit;
            
        if Confirm('Item %1 is out of stock. Would you like to use replacement item %2?', 
                   false, Item."No.", ReplacementItem."No.") then begin
            Rec.Validate("No.", ReplacementItem."No.");
        end;
    end;
}
```

### 🎯 Exercise 5: Enhance Replacement System

**Tasks**:
1. Support multiple replacement items with priority levels
2. Create a report showing replacement item chains
3. Add automatic substitution rules based on customer preferences
4. Build a page showing alternative items side-by-side

---

## 🧪 Module 6: Testing Best Practices
### Writing Comprehensive Unit Tests

### Test Structure

```al
codeunit 50110 "Batch Comment Update Test"
{
    Subtype = Test;

    [Test]
    procedure TestLoadCustomersIntoBuffer()
    var
        Buffer: Record "Batch Comment Update Buffer";
        BatchMgt: Codeunit "Batch Comment Management";
    begin
        // [SCENARIO] Load customers into buffer for batch update
        
        // [GIVEN] 5 customers with comments
        CreateCustomersWithComments(5);
        
        // [WHEN] Loading customers
        BatchMgt.LoadCustomers(Buffer);
        
        // [THEN] Buffer should contain 5 records
        Assert.AreEqual(5, Buffer.Count, 'Buffer should contain 5 customers');
        
        // [THEN] Each record should have correct data
        Buffer.FindFirst();
        Assert.AreEqual(Buffer."Entity Type"::Customer, Buffer."Entity Type", 'Entity type should be Customer');
        Assert.AreNotEqual('', Buffer."Entity No.", 'Entity No should be populated');
    end;

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
}
```

### Testing Principles

1. **GIVEN-WHEN-THEN Pattern** - Clear test structure
2. **Helper Procedures** - Reusable test data creation
3. **Assertions** - Verify expected outcomes
4. **Isolation** - Each test is independent
5. **Coverage** - Test all scenarios (happy path, edge cases, errors)

### 🎯 Exercise 6: Expand Test Coverage

**Tasks**:
1. Write tests for error conditions
2. Add performance tests for large datasets
3. Create integration tests between modules
4. Add tests for UI validation logic

---

## 🔧 Module 7: Advanced Patterns

### Pattern 1: Factory Pattern for Test Data

```al
codeunit 50200 "Test Data Factory"
{
    procedure CreateCustomerWithComment(CommentText: Text[100]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."ESD Comment" := CommentText;
        Customer."Transfer Comment" := true;
        Customer.Modify();
        exit(Customer."No.");
    end;
    
    procedure CreateSalesOrderWithLines(CustomerNo: Code[20]; LineCount: Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        
        for i := 1 to LineCount do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, 
                                        LibraryInventory.CreateItemNo(), 1);
        end;
        
        exit(SalesHeader."No.");
    end;
}
```

### Pattern 2: Fluent Interface for Test Builders

```al
codeunit 50201 "Sales Order Builder"
{
    var
        SalesHeader: Record "Sales Header";
        
    procedure New(CustomerNo: Code[20]): Codeunit "Sales Order Builder"
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        exit(this);
    end;
    
    procedure AddLine(ItemNo: Code[20]; Qty: Decimal): Codeunit "Sales Order Builder"
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        exit(this);
    end;
    
    procedure Build(): Code[20]
    begin
        exit(SalesHeader."No.");
    end;
}

// Usage:
OrderNo := SalesOrderBuilder.New(CustomerNo)
                .AddLine(Item1, 10)
                .AddLine(Item2, 5)
                .Build();
```

### Pattern 3: Event-Driven Architecture

```al
codeunit 50202 "Comment Events"
{
    [IntegrationEvent(false, false)]
    procedure OnBeforeTransferComment(var SalesLine: Record "Sales Line"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;
    
    [IntegrationEvent(false, false)]
    procedure OnAfterTransferComment(var SalesLine: Record "Sales Line"; Customer: Record Customer)
    begin
    end;
}

// In TransferESDComment codeunit:
procedure TransferWithEvents(var SalesLine: Record "Sales Line"; Customer: Record Customer)
var
    CommentEvents: Codeunit "Comment Events";
    IsHandled: Boolean;
begin
    CommentEvents.OnBeforeTransferComment(SalesLine, Customer, IsHandled);
    if IsHandled then
        exit;
        
    SalesLine."ESD Comment" := Customer."ESD Comment";
    
    CommentEvents.OnAfterTransferComment(SalesLine, Customer);
end;
```

---

## 📊 Module 8: Performance Optimization

### Best Practices

1. **Use SetLoadFields** for partial record loading:
```al
Customer.SetLoadFields("No.", Name, "ESD Comment");
if Customer.FindSet() then
    repeat
        // Process only loaded fields
    until Customer.Next() = 0;
```

2. **Bulk Operations** instead of row-by-row:
```al
// BAD
if Customer.FindSet() then
    repeat
        Customer."ESD Comment" := 'New Value';
        Customer.Modify();
    until Customer.Next() = 0;

// GOOD
Customer.ModifyAll("ESD Comment", 'New Value', true);
```

3. **Use Temporary Tables** for UI operations:
```al
// Avoid direct table queries in pages
// Use temporary buffer tables loaded once
```

4. **Index Keys Properly**:
```al
keys
{
    key(PK; "No.") { Clustered = true; }
    key(Idx1; "ESD Comment") { }  // For filtering/sorting
}
```

---

## 🎓 Final Project: Build Your Own Feature

### Project Requirements

Choose one of these features to build from scratch:

#### Option A: Customer Segmentation System
- Create customer segments (VIP, Regular, Inactive)
- Auto-assign segments based on sales history
- Add segment field to customer and filter customers by segment
- Create a report showing segment statistics

#### Option B: Item Substitute Manager
- Support multiple substitute items per item
- Add priority and availability dates
- Auto-suggest substitutes during order entry
- Build UI to manage substitute relationships

#### Option C: Comment Template System
- Create predefined comment templates
- Quick-insert templates on customer/vendor cards
- Track template usage
- Support variables in templates (customer name, date, etc.)

### Deliverables

1. ✅ Complete AL source code
2. ✅ Comprehensive unit tests (minimum 80% coverage)
3. ✅ User documentation
4. ✅ Demo video or screenshots
5. ✅ Code review checklist

---

## 📚 Additional Resources

### Official Documentation
- [Microsoft AL Language Reference](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-reference-overview)
- [Business Central Extension Development](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview)
- [AL Testing Framework](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-application)

### Code Samples
- This ALWSP repository serves as a complete reference implementation
- Review `Libraries/` folder for reusable test patterns
- Study `REQUIREMENTS.md` for detailed specifications

### Community
- [Business Central Community](https://community.dynamics.com/forums/thread/?partialUrl=business)
- [AL Developer Forum](https://github.com/microsoft/AL/discussions)
- [Stack Overflow - Business Central](https://stackoverflow.com/questions/tagged/dynamics-365-business-central)

---

## ✅ Completion Checklist

### Module 1: ESD Comment System
- [ ] Extend Customer and Vendor tables
- [ ] Extend Sales and Purchase Line tables
- [ ] Create event subscriber codeunit
- [ ] Add page extensions
- [ ] Test comment transfer functionality

### Module 2: Batch Update System
- [ ] Create Comment Entity Type enum
- [ ] Create Batch Comment Update Buffer table
- [ ] Implement Batch Comment Management codeunit
- [ ] Build Batch Comment Update page
- [ ] Test batch operations

### Module 3: Lookup Value System
- [ ] Create LookupValue table
- [ ] Extend entities with lookup fields
- [ ] Create lookup page
- [ ] Test lookup relationships

### Module 4: Order Status Tracking
- [ ] Create Order Status enum
- [ ] Extend order line tables
- [ ] Implement auto-calculation logic
- [ ] Test status updates

### Module 5: Replacement Item
- [ ] Extend Item table
- [ ] Implement suggestion logic
- [ ] Add page extensions
- [ ] Test replacement suggestions

### Module 6: Testing
- [ ] Write unit tests for all features
- [ ] Create helper procedures
- [ ] Achieve >80% code coverage
- [ ] Document test scenarios

### Module 7: Advanced Patterns
- [ ] Implement factory pattern
- [ ] Create fluent builders
- [ ] Add integration events
- [ ] Refactor existing code

### Module 8: Optimization
- [ ] Profile performance
- [ ] Optimize slow operations
- [ ] Add proper indexes
- [ ] Use bulk operations

### Final Project
- [ ] Choose and design feature
- [ ] Implement complete solution
- [ ] Write comprehensive tests
- [ ] Create documentation
- [ ] Present demo

---

## 🏆 Certification

Upon completing this workshop:
1. Submit your final project for review
2. Pass the code quality assessment
3. Demonstrate your solution
4. Receive workshop completion certificate

**Assessment Criteria**:
- Code Quality (30%)
- Test Coverage (25%)
- Best Practices (25%)
- Documentation (10%)
- Presentation (10%)

---

## 🤝 Support

If you have questions:
1. Review the REQUIREMENTS.md file in this repository
2. Study the existing implementations in the App/ folder
3. Check the Libraries/ folder for test patterns
4. Consult Microsoft documentation
5. Ask in the community forums

---

**Good luck with your Business Central AL development journey!** 🚀

---

*This workshop is based on ALWSP v1.0.0.0 - Business Central Version 27.0*
