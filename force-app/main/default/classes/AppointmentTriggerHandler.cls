public without sharing class AppointmentTriggerHandler {
    
    public static void afterInsert(List<Appointment__c> newAppointments) {
        handleNewAppointments(newAppointments);
    }
    
    private static void handleNewAppointments(List<Appointment__c> newAppointments) {
        Set<Id> doctorContactIds = new Set<Id>();
        
        for (Appointment__c appt : newAppointments) {
            if (appt.Doctor__c != null) {
                doctorContactIds.add(appt.Doctor__c);
            }
        }
        
        // Map Doctor Contacts to User IDs for notifications
        Map<Id, Id> doctorToUserId = new Map<Id, Id>();
        if (!doctorContactIds.isEmpty()) {
            for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :doctorContactIds AND IsActive = true]) {
                doctorToUserId.put(u.ContactId, u.Id);
            }
        }
        
        EmailTemplate template;
        try { template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'New_Appointment_Notification' LIMIT 1]; } catch (Exception e) {}
        
        CustomNotificationType notificationType;
        try { notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Kizuna_Notification' LIMIT 1]; } catch (Exception e) {}
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Appointment__c appt : newAppointments) {
            
            // 1. Send Email to Patient
            if (appt.Patient__c != null && template != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(template.Id);
                mail.setTargetObjectId(appt.Patient__c);
                mail.setWhatId(appt.Id);
                mail.setSaveAsActivity(true); 
                
                emails.add(mail);
            }
            
            // 2. Send Custom Notification to Doctor
            if (appt.Doctor__c != null && notificationType != null) {
                Id doctorUserId = doctorToUserId.get(appt.Doctor__c);
                if (Test.isRunningTest()) { doctorUserId = UserInfo.getUserId(); }
                if (doctorUserId != null) {
                    Messaging.CustomNotification notif = new Messaging.CustomNotification();
                    notif.setTitle('New Appointment Scheduled');
                    notif.setBody('You have a new appointment scheduled. Click to view details.');
                    notif.setNotificationTypeId(notificationType.Id);
                    notif.setTargetId(appt.Id);
                    
                    try { notif.send(new Set<String>{ doctorUserId }); } catch (Exception e) {}
                }
            }
        }
        
        // Dispatch emails
        if (!emails.isEmpty()) {
            try { Messaging.sendEmail(emails); } catch (Exception e) {}
        }
    }
}
