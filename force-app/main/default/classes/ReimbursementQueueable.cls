public with sharing class ReimbursementQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> reportIds;

    public ReimbursementQueueable(Set<Id> reportIds) {
        this.reportIds = reportIds;
    }

    public void execute(QueueableContext context) {
        if (reportIds == null || reportIds.isEmpty()) {
            return;
        }

        List<Expense_Report__c> reports = [
            SELECT Id, Employee__c, Total_Reimbursable_Amount__c, Reimbursement_Status__c, Status__c
            FROM Expense_Report__c
            WHERE Id IN :reportIds AND Reimbursement_Status__c = 'Eligible'
            WITH USER_MODE
        ];

        List<Reimbursement__c> reimbursementsToInsert = new List<Reimbursement__c>();
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();
        List<Expense_Report__c> reportsToUpdate = new List<Expense_Report__c>();

        for (Expense_Report__c er : reports) {
            String payRef = 'PAY-TRV-' + String.valueOf(System.currentTimeMillis()).substring(3) + '-' + er.Id.toString().substring(12);
            Decimal amount = er.Total_Reimbursable_Amount__c != null ? er.Total_Reimbursable_Amount__c : 0.00;

            Reimbursement__c reim = new Reimbursement__c(
                Expense_Report__c = er.Id,
                Employee__c = er.Employee__c,
                Approved_Amount__c = amount,
                Reimbursement_Status__c = 'Completed',
                Payment_Reference__c = payRef,
                Processing_Date__c = Date.today(),
                Completion_Date__c = Date.today(),
                Comments__c = 'Automated travel reimbursement processed via TravelEasy Spend Control Engine.'
            );
            reimbursementsToInsert.add(reim);

            Integration_Log__c log = new Integration_Log__c(
                Source_System__c = 'TravelEasy Spend Control',
                Target_System__c = 'Corporate Finance ERP',
                Status__c = 'Success',
                Endpoint__c = 'https://api.traveleasy.internal/v1/reimbursements/payout',
                Request_Payload__c = '{"expenseReportId":"' + er.Id + '","amount":' + amount + ',"employeeId":"' + er.Employee__c + '"}',
                Response_Payload__c = '{"status":"200","message":"Reimbursement payout queued","paymentRef":"' + payRef + '"}',
                Related_Record_Id__c = er.Id
            );
            logsToInsert.add(log);

            er.Reimbursement_Status__c = 'Completed';
            er.Status__c = 'Reimbursed';
            reportsToUpdate.add(er);
        }

        if (!reimbursementsToInsert.isEmpty()) {
            insert as user reimbursementsToInsert;
        }
        if (!logsToInsert.isEmpty()) {
            insert as user logsToInsert;
        }
        if (!reportsToUpdate.isEmpty()) {
            update as user reportsToUpdate;
        }
    }
}
