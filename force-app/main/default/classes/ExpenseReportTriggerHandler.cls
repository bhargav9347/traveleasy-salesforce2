public with sharing class ExpenseReportTriggerHandler {
    public static void handleAfterUpdate(List<Expense_Report__c> newList, Map<Id, Expense_Report__c> oldMap) {
        Set<Id> submittedReportIds = new Set<Id>();
        for (Expense_Report__c er : newList) {
            Expense_Report__c oldEr = oldMap.get(er.Id);
            if (er.Status__c == 'Submitted' && oldEr.Status__c != 'Submitted') {
                submittedReportIds.add(er.Id);
            }
        }
        if (!submittedReportIds.isEmpty()) {
            SmartExpenseControlEngine.validateExpenseReports(submittedReportIds);
        }
    }
}
