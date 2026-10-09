@isTest
public class TravelEasyTestDataFactory {

    public static Travel_Request__c createTravelRequest(Id employeeId, String dest, Decimal estCost) {
        Travel_Request__c tr = new Travel_Request__c(
            Employee__c = employeeId,
            Destination__c = dest,
            Purpose__c = 'Business Meeting',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(3),
            Estimated_Cost__c = estCost,
            Travel_Type__c = 'Domestic',
            Department__c = 'Sales',
            Status__c = 'Draft'
        );
        insert tr;
        return tr;
    }

    public static Expense_Report__c createExpenseReport(Id trId, Id employeeId) {
        Expense_Report__c er = new Expense_Report__c(
            Travel_Request__c = trId,
            Employee__c = employeeId,
            Report_Date__c = Date.today(),
            Status__c = 'Draft'
        );
        insert er;
        return er;
    }

    public static Expense_Item__c createExpenseItem(Id erId, String category, Decimal amount, Boolean receiptAttached) {
        Expense_Item__c item = new Expense_Item__c(
            Expense_Report__c = erId,
            Expense_Category__c = category,
            Amount__c = amount,
            Expense_Date__c = Date.today(),
            Vendor__c = 'Sample Vendor',
            Paid_By__c = 'Employee Personal',
            Receipt_Attached__c = receiptAttached
        );
        insert item;
        return item;
    }
}
