trigger AppointmentTrigger on Appointment__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        AppointmentTriggerHandler.afterInsert(Trigger.new);
    }
}
