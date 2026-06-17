public with sharing class KizunaHeroController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getUserInfo() {
        Map<String, String> info = new Map<String, String>();

        User u = [SELECT Id, Name, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        info.put('name', u.Name);
        info.put('role', 'User');
        info.put('subtitle', '');

        if (u.ContactId == null) return info;

        Contact c = [
            SELECT Id, Name, RecordType.Name, specialization__c, doctor_type__c
            FROM Contact WHERE Id = :u.ContactId LIMIT 1
        ];

        String recType = c.RecordType != null ? c.RecordType.Name : '';
        info.put('name', c.Name);

        if (recType.containsIgnoreCase('Doctor')) {
            info.put('role', 'Doctor');
            info.put('subtitle', String.isNotBlank(c.specialization__c) ? c.specialization__c : 'Healthcare Professional');
        } else if (recType.containsIgnoreCase('Patient')) {
            info.put('role', 'Patient');
            info.put('subtitle', 'Your health is our priority');
        }

        return info;
    }
}
