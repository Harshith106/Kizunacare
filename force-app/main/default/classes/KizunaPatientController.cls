public without sharing class KizunaPatientController {

    public class PatientWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String gender;
        @AuraEnabled public Decimal age;
        @AuraEnabled public String bloodGroup;
        @AuraEnabled public String knownAllergies;
        @AuraEnabled public String chronicConditions;
    }

    @AuraEnabled(cacheable=true)
    public static List<PatientWrapper> getMyPatients() {
        List<PatientWrapper> results = new List<PatientWrapper>();

        // 1. Get the current user's ContactId
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) {
            return results;
        }

        // 2. Find all unique Patient IDs who have an Appointment with this Doctor
        List<Appointment__c> appts = [
            SELECT Patient__c
            FROM Appointment__c
            WHERE Doctor__c = :u.ContactId AND Patient__c != null
        ];

        Set<Id> patientIds = new Set<Id>();
        for (Appointment__c a : appts) {
            patientIds.add(a.Patient__c);
        }

        if (patientIds.isEmpty()) {
            return results;
        }

        // 3. Query and map to wrapper
        List<Contact> patients = [
            SELECT Id, Name, Phone, Gender__c, Age__c, Blood_Group__c,
                   known_allergies__c, chronic_conditions__c
            FROM Contact
            WHERE Id IN :patientIds
            ORDER BY Name ASC
        ];

        for (Contact c : patients) {
            PatientWrapper wrap = new PatientWrapper();
            wrap.recordId         = c.Id;
            wrap.name             = c.Name;
            wrap.phone            = c.Phone;
            wrap.gender           = c.Gender__c;
            wrap.age              = c.Age__c;
            wrap.bloodGroup       = c.Blood_Group__c;
            wrap.knownAllergies   = c.known_allergies__c;
            wrap.chronicConditions = c.chronic_conditions__c;
            results.add(wrap);
        }

        return results;
    }
}
