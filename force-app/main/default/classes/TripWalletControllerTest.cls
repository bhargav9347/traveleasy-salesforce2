@isTest
private class TripWalletControllerTest {
    @isTest
    static void testGetTripWalletData() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Goa', 20000);
            Expense_Report__c er = TravelEasyTestDataFactory.createExpenseReport(tr.Id, u.Id);
            TravelEasyTestDataFactory.createExpenseItem(er.Id, 'Meals', 1000, true);

            Test.startTest();
            TripWalletController.TripWalletWrapper wallet = TripWalletController.getTripWalletData(tr.Id);
            Test.stopTest();

            System.assertNotEquals(null, wallet);
            System.assertEquals(20000, wallet.estimatedCost);
            System.assertEquals(1000, wallet.actualCost);
            System.assertEquals(19000, wallet.remainingBudget);
        }
    }
}
