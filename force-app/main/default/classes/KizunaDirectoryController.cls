public with sharing class KizunaDirectoryController {
    
    @AuraEnabled(cacheable=true)
    public static List<Healthcare_Event__c> getFilteredEvents(String searchTerm, String statusFilter) {
        String query = 'SELECT Id, Name, Event_Date__c, Venue__c, Status__c FROM Healthcare_Event__c WHERE Id != null';
        
        if (String.isNotBlank(searchTerm)) {
            String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            query += ' AND (Name LIKE :likeTerm OR Venue__c LIKE :likeTerm)';
        }
        
        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            query += ' AND Status__c = :statusFilter';
        }
        
        query += ' ORDER BY Event_Date__c ASC LIMIT 50';
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Health_Program__c> getFilteredPrograms(String searchTerm, String statusFilter) {
        String query = 'SELECT Id, Name, Program_Type__c, Start_Date__c, End_Date__c, Status__c, Description__c FROM Health_Program__c WHERE Id != null';
        
        if (String.isNotBlank(searchTerm)) {
            String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            query += ' AND (Name LIKE :likeTerm OR Description__c LIKE :likeTerm)';
        }
        
        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            query += ' AND Status__c = :statusFilter';
        }
        
        query += ' ORDER BY Start_Date__c ASC LIMIT 50';
        return Database.query(query);
    }
}
