public without sharing class CaseTriggerHandler {
    
    public static void afterInsert(List<Case> newCases) {
        handleDoctorAssignment(null, newCases);
    }
    
    public static void afterUpdate(Map<Id, Case> oldCases, Map<Id, Case> newCases) {
        handleDoctorAssignment(oldCases, newCases.values());
        handleFollowUpNotifications(oldCases, newCases);
    }

    private static void handleDoctorAssignment(Map<Id, Case> oldCases, List<Case> newCases) {
        Set<Id> doctorContactIds = new Set<Id>();
        List<Case> casesWithNewDoctors = new List<Case>();
        
        for (Case c : newCases) {
            Case oldCase = (oldCases != null) ? oldCases.get(c.Id) : null;
            if (c.Assigned_Doctor__c != null && (oldCase == null || c.Assigned_Doctor__c != oldCase.Assigned_Doctor__c)) {
                casesWithNewDoctors.add(c);
                doctorContactIds.add(c.Assigned_Doctor__c);
            }
        }
        
        if (casesWithNewDoctors.isEmpty()) return;
        
        // Find users for doctors
        Map<Id, Id> contactToUserId = new Map<Id, Id>();
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :doctorContactIds AND IsActive = true]) {
            contactToUserId.put(u.ContactId, u.Id);
        }
        
        CustomNotificationType notificationType;
        try {
            notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Kizuna_Notification' LIMIT 1];
        } catch (Exception e) {}

        List<Task> tasksToInsert = new List<Task>();
        
        for (Case c : casesWithNewDoctors) {
            Id doctorUserId = contactToUserId.get(c.Assigned_Doctor__c);
            
            if (doctorUserId != null) {
                Task t = new Task();
                t.OwnerId = doctorUserId;
                t.Subject = 'New Case Assigned: ' + c.Subject;
                t.WhatId = c.Id;
                t.WhoId = c.ContactId;
                t.Status = 'Not Started';
                t.Priority = c.Priority != null ? c.Priority : 'Normal';
                tasksToInsert.add(t);
                
                if (notificationType != null) {
                    Messaging.CustomNotification notif = new Messaging.CustomNotification();
                    notif.setTitle('New Case Assigned');
                    notif.setBody('You have been assigned to case: ' + c.Subject);
                    notif.setNotificationTypeId(notificationType.Id);
                    notif.setTargetId(c.Id);
                    try {
                        notif.send(new Set<String>{ doctorUserId });
                    } catch (Exception e) {
                        System.debug('Failed to send doctor notification: ' + e.getMessage());
                    }
                }
            }
        }
        
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    private static void handleFollowUpNotifications(Map<Id, Case> oldCases, Map<Id, Case> newCases) {
        List<Case> casesToNotify = new List<Case>();
        Set<Id> patientContactIds = new Set<Id>();
        
        for (Case c : newCases.values()) {
            Case oldCase = oldCases.get(c.Id);
            if ((c.Status == 'Follow Up' || c.Status == 'Follow_Up' || c.Type == 'Follow Up' || c.Type == 'Follow_Up') 
                && (oldCase.Status != c.Status || oldCase.Type != c.Type)) {
                
                if (c.Patient__c != null) {
                    casesToNotify.add(c);
                    patientContactIds.add(c.Patient__c);
                }
            }
        }
        
        if (casesToNotify.isEmpty()) {
            return;
        }
        
        Map<Id, Id> contactToUserId = new Map<Id, Id>();
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :patientContactIds AND IsActive = true]) {
            contactToUserId.put(u.ContactId, u.Id);
        }
        
        EmailTemplate emailTemplate;
        try {
            emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Follow_Up_Notification' LIMIT 1];
        } catch (Exception e) {}
        
        CustomNotificationType notificationType;
        try {
            notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Kizuna_Notification' LIMIT 1];
        } catch (Exception e) {}
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Case c : casesToNotify) {
            Id userId = contactToUserId.get(c.Patient__c);
            
            if (userId != null && notificationType != null) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Follow Up Required');
                notification.setBody('Your case ' + c.CaseNumber + ' requires a follow up.');
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(c.Id);
                try {
                    notification.send(new Set<String>{ userId });
                } catch (Exception e) {}
            }
            
            if (emailTemplate != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(emailTemplate.Id);
                mail.setTargetObjectId(c.Patient__c);
                mail.setWhatId(c.Id);
                mail.setSaveAsActivity(true);
                emails.add(mail);
            }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {}
        }
    }
}
