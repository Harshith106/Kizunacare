public without sharing class KizunaCommunityController {

    /* --- All Events (with optional filters) --- */
    @AuraEnabled(cacheable=true)
    public static List<Healthcare_Event__c> getAllEvents(String searchTerm, String statusFilter) {
        String q = 'SELECT Id, Name, Event_Date__c, Venue__c, Status__c, Expected_Patients__c FROM Healthcare_Event__c WHERE Id != null';
        if (String.isNotBlank(statusFilter) && statusFilter != 'All')
            q += ' AND Status__c = :statusFilter';
        if (String.isNotBlank(searchTerm)) {
            String lt = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            q += ' AND (Name LIKE :lt OR Venue__c LIKE :lt)';
        }
        q += ' ORDER BY Event_Date__c ASC LIMIT 50';
        return Database.query(q);
    }

    /* --- All Programs (with optional filters) --- */
    @AuraEnabled(cacheable=true)
    public static List<Health_Program__c> getAllPrograms(String searchTerm, String statusFilter, String typeFilter) {
        String q = 'SELECT Id, Name, Program_Type__c, Start_Date__c, End_Date__c, Status__c, Description__c FROM Health_Program__c WHERE Id != null';
        if (String.isNotBlank(statusFilter) && statusFilter != 'All')
            q += ' AND Status__c = :statusFilter';
        if (String.isNotBlank(typeFilter) && typeFilter != 'All')
            q += ' AND Program_Type__c = :typeFilter';
        if (String.isNotBlank(searchTerm)) {
            String lt = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            q += ' AND (Name LIKE :lt OR Description__c LIKE :lt)';
        }
        q += ' ORDER BY Start_Date__c ASC LIMIT 50';
        return Database.query(q);
    }

    /* --- Return Healthworker Contact Id for the current patient --- */
    @AuraEnabled(cacheable=true)
    public static Id getHealthworkerId() {
        try {
            User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (u.ContactId == null) return null;

            Contact patient = [SELECT Id, Village__c, RecordType.Name
                               FROM Contact WHERE Id = :u.ContactId LIMIT 1];

            Boolean isPatient = patient.RecordType != null
                && patient.RecordType.Name.containsIgnoreCase('Patient');
            if (!isPatient || patient.Village__c == null) return null;

            List<Contact> hwList = [
                SELECT Id FROM Contact
                WHERE Assigned_Village__c = :patient.Village__c
                  AND RecordType.Name LIKE '%Healthworker%'
                LIMIT 1
            ];
            return hwList.isEmpty() ? null : hwList[0].Id;
        } catch (Exception e) {
            System.debug('getHealthworkerId error: ' + e.getMessage());
            return null;
        }
    }
}
