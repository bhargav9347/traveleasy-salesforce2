@isTest
private class ExpenseReconciliationBatchTest {
    @isTest
    static void testBatchExecution() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Pune', 25000);
            Expense_Report__c er = TravelEasyTestDataFactory.createExpenseReport(tr.Id, u.Id);
            TravelEasyTestDataFactory.createExpenseItem(er.Id, 'Meals', 400, true);

            Test.startTest();
            ExpenseReconciliationBatch batch = new ExpenseReconciliationBatch();
            Database.executeBatch(batch, 10);
            Test.stopTest();

            List<Integration_Log__c> logs = [SELECT Source_System__c FROM Integration_Log__c WHERE Source_System__c = 'TravelEasy Reconciliation Batch'];
            System.assertEquals(1, logs.size());
        }
    }
}
