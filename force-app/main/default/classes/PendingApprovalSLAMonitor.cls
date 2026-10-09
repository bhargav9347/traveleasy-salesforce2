public with sharing class PendingApprovalSLAMonitor implements Schedulable {
    public void execute(SchedulableContext sc) {
        List<Travel_Request__c> pendingRequests = [
            SELECT Id, Name, Status__c, Approval_Status__c, CreatedDate
            FROM Travel_Request__c
            WHERE Status__c = 'Pending Approval'
            WITH USER_MODE
        ];

        List<Integration_Log__c> slaLogs = new List<Integration_Log__c>();
        for (Travel_Request__c tr : pendingRequests) {
            slaLogs.add(new Integration_Log__c(
                Source_System__c = 'SLA Monitor',
                Target_System__c = 'TravelEasy Notifications',
                Status__c = 'Warning',
                Endpoint__c = 'Apex/PendingApprovalSLAMonitor',
                Request_Payload__c = '{"recordId":"' + tr.Id + '","createdDate":"' + tr.CreatedDate + '"}',
                Response_Payload__c = '{"slaAlert":"Pending approval exceeds SLA threshold"}',
                Related_Record_Id__c = tr.Id
            ));
        }

        if (!slaLogs.isEmpty()) {
            insert as user slaLogs;
        }
    }
}
