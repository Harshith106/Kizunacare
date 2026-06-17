public without sharing class KizunaMedicalRecordController {

    public class MedicalRecordWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String recordName;
        @AuraEnabled public String category;
        @AuraEnabled public Date recordDate;
        @AuraEnabled public String doctorName;
        @AuraEnabled public String patientName;
        @AuraEnabled public String medicineName;
        @AuraEnabled public String testName;
        @AuraEnabled public String vaccineName;
        @AuraEnabled public String detailsSnippet;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isDoctorUser() {
        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) return false;
        Contact currentUser = [SELECT Id, RecordType.Name FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        return currentUser.RecordType.Name.containsIgnoreCase('Doctor');
    }

    @AuraEnabled(cacheable=true)
    public static List<MedicalRecordWrapper> getMyMedicalRecords() {
        List<MedicalRecordWrapper> results = new List<MedicalRecordWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) {
            return results;
        }

        Contact currentUser = [SELECT Id, RecordType.Name FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        Boolean isDoctor = currentUser.RecordType.Name.containsIgnoreCase('Doctor');

        String query = 'SELECT Id, Name, Record_Category__c, Record_Date__c, Details__c, ' +
                       'Doctor__c, Doctor__r.Name, ' +
                       'Medicine_Name__c, Test_Name__c, Vaccine_Name__c, ' +
                       'Case__r.Patient__r.Name ' +
                       'FROM Medical_Record__c WHERE ';

        if (isDoctor) {
            query += 'Doctor__c = \'' + u.ContactId + '\'';
        } else {
            // Patient: traverse Case -> Patient lookup
            // Find Cases where this contact is the patient, then match records
            List<Case> patientCases = [SELECT Id FROM Case WHERE Patient__c = :u.ContactId];
            Set<Id> caseIds = new Set<Id>();
            for (Case c : patientCases) {
                caseIds.add(c.Id);
            }
            if (caseIds.isEmpty()) {
                return results;
            }
            // Use the Case__c master-detail to filter
            query += 'Case__c IN (\'' + String.join(new List<Id>(caseIds), '\',\'') + '\')';
        }

        query += ' ORDER BY Record_Date__c DESC LIMIT 100';

        List<Medical_Record__c> records = Database.query(query);

        for (Medical_Record__c r : records) {
            MedicalRecordWrapper wrap = new MedicalRecordWrapper();
            wrap.recordId       = r.Id;
            wrap.recordName     = r.Name;
            wrap.category       = r.Record_Category__c;
            wrap.recordDate     = r.Record_Date__c;
            wrap.doctorName     = r.Doctor__r != null ? r.Doctor__r.Name : 'Unknown Doctor';
            wrap.patientName    = (r.Case__r != null && r.Case__r.Patient__r != null)
                                    ? r.Case__r.Patient__r.Name
                                    : 'Unknown Patient';
            wrap.medicineName   = r.Medicine_Name__c;
            wrap.testName       = r.Test_Name__c;
            wrap.vaccineName    = r.Vaccine_Name__c;
            // Truncate Details for card snippet
            if (String.isNotBlank(r.Details__c)) {
                String stripped = r.Details__c.stripHtmlTags();
                wrap.detailsSnippet = stripped.length() > 120 ? stripped.substring(0, 120) + '…' : stripped;
            }
            results.add(wrap);
        }

        return results;
    }
}
