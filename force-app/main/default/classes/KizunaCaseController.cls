public without sharing class KizunaCaseController {
    
    public class CaseWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String subject;
        @AuraEnabled public String otherPersonName;
        @AuraEnabled public String otherPersonRole;
        @AuraEnabled public Date visitDate;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public String type;
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> results = new List<CaseWrapper>();
        
        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) return results;

        Contact currentUser = [SELECT Id, RecordType.Name FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        Boolean isDoctor = currentUser.RecordType.Name.containsIgnoreCase('Doctor');
        
        String filter = isDoctor
            ? 'Assigned_Doctor__c = \'' + u.ContactId + '\''
            : 'Patient__c = \'' + u.ContactId + '\'';

        List<Case> cases = Database.query(
            'SELECT Id, Subject, Patient__r.Name, Assigned_Doctor__r.Name, ' +
            'Visit_Date__c, Status, Priority, Type ' +
            'FROM Case WHERE ' + filter +
            ' ORDER BY Visit_Date__c ASC LIMIT 100'
        );
        
        for (Case c : cases) {
            CaseWrapper wrap     = new CaseWrapper();
            wrap.recordId        = c.Id;
            wrap.subject         = c.Subject;
            wrap.visitDate       = c.Visit_Date__c;
            wrap.status          = c.Status == 'In_Progress' ? 'In Progress' : c.Status;
            wrap.priority        = c.Priority;
            wrap.type            = c.Type;
            wrap.otherPersonName = isDoctor
                ? (c.Patient__r != null ? c.Patient__r.Name : 'Unknown Patient')
                : (c.Assigned_Doctor__r != null ? c.Assigned_Doctor__r.Name : 'Unknown Doctor');
            wrap.otherPersonRole = isDoctor ? 'Patient' : 'Doctor';
            results.add(wrap);
        }
        return results;
    }
}
