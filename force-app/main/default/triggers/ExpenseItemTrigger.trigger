trigger ExpenseItemTrigger on Expense_Item__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ExpenseItemTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ExpenseItemTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
