@isTest
private class TravelRequestTriggerTest {
    @isTest
    static void testTravelRequestLifecycle() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Bangalore', 20000);
            System.assertEquals('Draft', tr.Status__c);
            System.assertEquals('Not Submitted', tr.Approval_Status__c);

            tr.Status__c = 'Submitted';
            update tr;

            Travel_Request__c updatedTr = [SELECT Approval_Status__c FROM Travel_Request__c WHERE Id = :tr.Id];
            System.assertEquals('Pending', updatedTr.Approval_Status__c);
        }
    }
}
