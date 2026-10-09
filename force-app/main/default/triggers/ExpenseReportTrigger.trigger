trigger ExpenseReportTrigger on Expense_Report__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        ExpenseReportTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
