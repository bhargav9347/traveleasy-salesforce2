public with sharing class ExpenseItemTriggerHandler {
    public static void handleBeforeInsert(List<Expense_Item__c> newList) {
        for (Expense_Item__c ei : newList) {
            if (ei.Paid_By__c == 'Corporate Card') {
                ei.Reimbursable_Amount__c = 0.00;
            } else if (ei.Reimbursable_Amount__c == null || ei.Reimbursable_Amount__c == 0) {
                ei.Reimbursable_Amount__c = ei.Amount__c;
            }
            if (ei.Validation_Status__c == null) {
                ei.Validation_Status__c = 'Pending';
            }
            if (ei.Exception_Status__c == null) {
                ei.Exception_Status__c = 'None';
            }
            if (ei.Policy_Result__c == null) {
                ei.Policy_Result__c = 'PASS';
            }
        }
    }

    public static void handleBeforeUpdate(List<Expense_Item__c> newList, Map<Id, Expense_Item__c> oldMap) {
        for (Expense_Item__c ei : newList) {
            if (ei.Paid_By__c == 'Corporate Card') {
                ei.Reimbursable_Amount__c = 0.00;
            } else if (ei.Paid_By__c == 'Employee Personal' && (ei.Reimbursable_Amount__c == null || ei.Reimbursable_Amount__c == 0)) {
                ei.Reimbursable_Amount__c = ei.Amount__c;
            }
        }
    }
}
