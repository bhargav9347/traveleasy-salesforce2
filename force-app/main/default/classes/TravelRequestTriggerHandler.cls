public with sharing class TravelRequestTriggerHandler {
    public static void handleBeforeInsert(List<Travel_Request__c> newList) {
        for (Travel_Request__c tr : newList) {
            if (tr.Employee__c == null) {
                tr.Employee__c = UserInfo.getUserId();
            }
            if (tr.Status__c == null) {
                tr.Status__c = 'Draft';
            }
            if (tr.Approval_Status__c == null) {
                tr.Approval_Status__c = 'Not Submitted';
            }
        }
    }

    public static void handleBeforeUpdate(List<Travel_Request__c> newList, Map<Id, Travel_Request__c> oldMap) {
        for (Travel_Request__c tr : newList) {
            Travel_Request__c oldTr = oldMap.get(tr.Id);
            if (tr.Status__c == 'Submitted' && oldTr.Status__c == 'Draft') {
                tr.Approval_Status__c = 'Pending';
            }
        }
    }
}
