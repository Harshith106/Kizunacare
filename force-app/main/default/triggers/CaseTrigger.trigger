trigger CaseTrigger on Case (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            CaseTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}
