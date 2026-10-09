@isTest
private class SmartExpenseControlEngineTest {

    @isTest
    static void testNormalExpenseValidationAndReimbursement() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Mumbai', 30000);
            Expense_Report__c er = TravelEasyTestDataFactory.createExpenseReport(tr.Id, u.Id);

            // Valid meal item (below 2000 limit, receipt attached for > 500)
            TravelEasyTestDataFactory.createExpenseItem(er.Id, 'Meals', 800, true);

            Test.startTest();
            er.Status__c = 'Submitted';
            update er;
            Test.stopTest();

            Expense_Report__c updatedEr = [SELECT Validation_Status__c, Status__c, Reimbursement_Status__c FROM Expense_Report__c WHERE Id = :er.Id];
            System.assertEquals('Validated', updatedEr.Validation_Status__c);
            System.assertEquals('Completed', updatedEr.Reimbursement_Status__c);
        }
    }

    @isTest
    static void testPolicyLimitException() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Delhi', 50000);
            Expense_Report__c er = TravelEasyTestDataFactory.createExpenseReport(tr.Id, u.Id);

            // Excess meal item (3000 exceeds 2000 limit)
            TravelEasyTestDataFactory.createExpenseItem(er.Id, 'Meals', 3000, true);

            er.Status__c = 'Submitted';
            update er;

            Expense_Report__c updatedEr = [SELECT Validation_Status__c, Has_Exceptions__c FROM Expense_Report__c WHERE Id = :er.Id];
            System.assertEquals('Human Review Required', updatedEr.Validation_Status__c);
            System.assertEquals(true, updatedEr.Has_Exceptions__c);

            List<Expense_Exception__c> excs = [SELECT Exception_Type__c, Severity__c FROM Expense_Exception__c WHERE Expense_Report__c = :er.Id];
            System.assert(excs.size() > 0);
            System.assertEquals('POLICY_EXCEPTION', excs[0].Exception_Type__c);
        }
    }

    @isTest
    static void testMissingReceiptException() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Hyderabad', 20000);
            Expense_Report__c er = TravelEasyTestDataFactory.createExpenseReport(tr.Id, u.Id);

            // Meal > 500 without receipt
            TravelEasyTestDataFactory.createExpenseItem(er.Id, 'Meals', 1200, false);

            er.Status__c = 'Submitted';
            update er;

            List<Expense_Exception__c> excs = [SELECT Exception_Type__c FROM Expense_Exception__c WHERE Expense_Report__c = :er.Id];
            System.assert(excs.size() > 0);
            System.assertEquals('MISSING_RECEIPT', excs[0].Exception_Type__c);
        }
    }
}
