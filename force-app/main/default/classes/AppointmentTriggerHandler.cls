public without sharing class AppointmentTriggerHandler {
    
    public static void afterInsert(List<Appointment__c> newAppointments) {
        sendNewAppointmentEmails(newAppointments);
    }
    
    private static void sendNewAppointmentEmails(List<Appointment__c> newAppointments) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        EmailTemplate template;
        try {
            template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'New_Appointment_Notification' LIMIT 1];
        } catch (Exception e) {
            System.debug('Email template New_Appointment_Notification not found.');
            return;
        }
        
        for (Appointment__c appt : newAppointments) {
            if (appt.Patient__c != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(template.Id);
                mail.setTargetObjectId(appt.Patient__c);
                mail.setWhatId(appt.Id);
                mail.setSaveAsActivity(true); 
                
                emails.add(mail);
            }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Failed to send appointment emails: ' + e.getMessage());
            }
        }
    }
}
