trigger TravelRequestTrigger on Travel_Request__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TravelRequestTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            TravelRequestTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
