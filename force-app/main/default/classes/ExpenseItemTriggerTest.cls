@isTest
private class ExpenseItemTriggerTest {
    @isTest
    static void testExpenseItemDefaults() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Chennai', 15000);
            Expense_Report__c er = TravelEasyTestDataFactory.createExpenseReport(tr.Id, u.Id);

            Expense_Item__c itemPersonal = TravelEasyTestDataFactory.createExpenseItem(er.Id, 'Meals', 400, true);
            System.assertEquals(400, itemPersonal.Reimbursable_Amount__c);

            Expense_Item__c itemCorp = new Expense_Item__c(
                Expense_Report__c = er.Id,
                Expense_Category__c = 'Flights',
                Amount__c = 5000,
                Paid_By__c = 'Corporate Card',
                Receipt_Attached__c = true
            );
            insert itemCorp;

            Expense_Item__c queriedCorp = [SELECT Reimbursable_Amount__c FROM Expense_Item__c WHERE Id = :itemCorp.Id];
            System.assertEquals(0.00, queriedCorp.Reimbursable_Amount__c);
        }
    }
}
