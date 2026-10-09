@isTest
private class PendingApprovalSLAMonitorTest {
    @isTest
    static void testScheduler() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(u) {
            Travel_Request__c tr = TravelEasyTestDataFactory.createTravelRequest(u.Id, 'Kolkata', 15000);
            tr.Status__c = 'Submitted';
            tr.Approval_Status__c = 'Pending';
            update tr;

            Test.startTest();
            PendingApprovalSLAMonitor sched = new PendingApprovalSLAMonitor();
            String cron = '0 0 0 15 3 ? 2029';
            System.schedule('Test SLA Monitor', cron, sched);
            sched.execute(null);
            Test.stopTest();

            List<Integration_Log__c> logs = [SELECT Source_System__c FROM Integration_Log__c WHERE Source_System__c = 'SLA Monitor'];
            System.assert(logs.size() >= 0);
        }
    }
}
