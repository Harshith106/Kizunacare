public without sharing class KizunaAppointmentController {
    
    public class AppointmentWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String appointmentName;
        @AuraEnabled public String otherPersonName;
        @AuraEnabled public String otherPersonRole;
        @AuraEnabled public Datetime appointmentDate;
        @AuraEnabled public String status;
        @AuraEnabled public String appointmentType;
        @AuraEnabled public String notes;
    }

    @AuraEnabled(cacheable=true)
    public static List<AppointmentWrapper> getMyAppointments() {
        List<AppointmentWrapper> results = new List<AppointmentWrapper>();
        
        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) {
            return results;
        }

        Contact currentUser = [SELECT Id, RecordType.Name FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        Boolean isDoctor = currentUser.RecordType.Name.containsIgnoreCase('Doctor');
        
        String query = 'SELECT Id, Name, Patient__c, Patient__r.Name, Doctor__c, Doctor__r.Name, ' +
                       'Appointment_Datetime__c, Status__c, Appointment_Type__c, Notes__c ' +
                       'FROM Appointment__c WHERE ';
        
        if (isDoctor) {
            query += 'Doctor__c = \'' + u.ContactId + '\'';
        } else {
            query += 'Patient__c = \'' + u.ContactId + '\'';
        }

        query += ' ORDER BY Appointment_Datetime__c ASC LIMIT 100';
        
        List<Appointment__c> appts = Database.query(query);
        
        for (Appointment__c a : appts) {
            AppointmentWrapper wrap = new AppointmentWrapper();
            wrap.recordId = a.Id;
            wrap.appointmentName = a.Name;
            wrap.appointmentDate = a.Appointment_Datetime__c;
            wrap.status = a.Status__c;
            wrap.appointmentType = a.Appointment_Type__c;
            wrap.notes = a.Notes__c;
            
            if (isDoctor) {
                wrap.otherPersonName = a.Patient__r != null ? a.Patient__r.Name : 'Unknown Patient';
                wrap.otherPersonRole = 'Patient';
            } else {
                wrap.otherPersonName = a.Doctor__r != null ? a.Doctor__r.Name : 'Unknown Doctor';
                wrap.otherPersonRole = 'Doctor';
            }
            
            results.add(wrap);
        }
        
        return results;
    }
}
