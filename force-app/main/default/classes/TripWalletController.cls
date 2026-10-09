public with sharing class TripWalletController {

    public class TripWalletWrapper {
        @AuraEnabled public Travel_Request__c travelRequest { get; set; }
        @AuraEnabled public Decimal estimatedCost { get; set; }
        @AuraEnabled public Decimal actualCost { get; set; }
        @AuraEnabled public Decimal remainingBudget { get; set; }
        @AuraEnabled public Decimal variancePercentage { get; set; }
        @AuraEnabled public List<Expense_Item__c> expenseItems { get; set; }
        @AuraEnabled public String reimbursementStatus { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static TripWalletWrapper getTripWalletData(Id travelRequestId) {
        if (travelRequestId == null) {
            throw new AuraHandledException('Travel Request ID is required.');
        }

        Travel_Request__c tr = [
            SELECT Id, Name, Destination__c, Purpose__c, Start_Date__c, End_Date__c,
                   Estimated_Cost__c, Actual_Cost__c, Status__c, Approval_Status__c,
                   Employee__r.Name
            FROM Travel_Request__c
            WHERE Id = :travelRequestId
            WITH USER_MODE
            LIMIT 1
        ];

        List<Expense_Report__c> reports = [
            SELECT Id, Total_Amount__c, Reimbursement_Status__c,
                   (SELECT Id, Name, Expense_Category__c, Amount__c, Expense_Date__c, Vendor__c,
                           Policy_Result__c, Validation_Status__c, Receipt_Attached__c, Exception_Status__c
                    FROM Expense_Items__r)
            FROM Expense_Report__c
            WHERE Travel_Request__c = :travelRequestId
            WITH USER_MODE
        ];

        Decimal totalActual = 0.00;
        String reimbStatus = 'Not Eligible';
        List<Expense_Item__c> allItems = new List<Expense_Item__c>();

        for (Expense_Report__c er : reports) {
            if (er.Total_Amount__c != null) {
                totalActual += er.Total_Amount__c;
            }
            if (er.Reimbursement_Status__c != null) {
                reimbStatus = er.Reimbursement_Status__c;
            }
            if (er.Expense_Items__r != null) {
                allItems.addAll(er.Expense_Items__r);
            }
        }

        Decimal est = tr.Estimated_Cost__c != null ? tr.Estimated_Cost__c : 0.00;
        Decimal remaining = est - totalActual;
        Decimal pct = (est > 0) ? ((totalActual - est) / est) * 100 : 0.00;

        TripWalletWrapper wallet = new TripWalletWrapper();
        wallet.travelRequest = tr;
        wallet.estimatedCost = est;
        wallet.actualCost = totalActual;
        wallet.remainingBudget = remaining;
        wallet.variancePercentage = pct;
        wallet.expenseItems = allItems;
        wallet.reimbursementStatus = reimbStatus;

        return wallet;
    }
}
