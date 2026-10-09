public with sharing class ExpenseReconciliationBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Integer totalProcessed = 0;
    public Integer exceptionsFound = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, Validation_Status__c, Reimbursement_Status__c, Total_Amount__c
            FROM Expense_Report__c
            WHERE Status__c IN ('Submitted', 'Approved')
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Expense_Report__c> scope) {
        Set<Id> reportIds = new Set<Id>();
        for (Expense_Report__c er : scope) {
            reportIds.add(er.Id);
            totalProcessed++;
            if (er.Validation_Status__c == 'Exception Identified' || er.Validation_Status__c == 'Human Review Required') {
                exceptionsFound++;
            }
        }
        if (!reportIds.isEmpty()) {
            SmartExpenseControlEngine.validateExpenseReports(reportIds);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Integration_Log__c log = new Integration_Log__c(
            Source_System__c = 'TravelEasy Reconciliation Batch',
            Target_System__c = 'TravelEasy Audit',
            Status__c = 'Success',
            Endpoint__c = 'Apex/ExpenseReconciliationBatch',
            Request_Payload__c = '{"jobId":"' + bc.getJobId() + '"}',
            Response_Payload__c = '{"totalProcessed":' + totalProcessed + ',"exceptionsFound":' + exceptionsFound + '}',
            Related_Record_Id__c = bc.getJobId()
        );
        insert as user log;
    }
}
