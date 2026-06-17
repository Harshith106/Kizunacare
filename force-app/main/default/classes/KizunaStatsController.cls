public with sharing class KizunaStatsController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getStats() {
        Map<String, String> stats = new Map<String, String>();

        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.ContactId == null) return stats;

        Contact c = [
            SELECT Id, RecordType.Name, active_cases__c
            FROM Contact WHERE Id = :u.ContactId LIMIT 1
        ];

        String role = c.RecordType != null ? c.RecordType.Name : '';
        stats.put('role', role);

        if (role.containsIgnoreCase('Patient')) {
            buildPatientStats(stats, c);
        } else if (role.containsIgnoreCase('Doctor')) {
            buildDoctorStats(stats, c);
        }

        return stats;
    }

    private static void buildPatientStats(Map<String, String> stats, Contact c) {
        // 1. Active cases count
        Integer activeCases = c.active_cases__c != null ? Integer.valueOf(c.active_cases__c) : 0;
        stats.put('activeCases', String.valueOf(activeCases));

        
        List<Case> cases = [
            SELECT ClosedDate FROM Case
            WHERE ContactId = :c.Id AND IsClosed = true
            ORDER BY ClosedDate DESC LIMIT 1
        ];
        stats.put('lastVisit', cases.isEmpty() ? '--' : String.valueOf(cases[0].ClosedDate));

        
        List<Appointment__c> appts = [
            SELECT appointment_datetime__c FROM Appointment__c
            WHERE patient__c = :c.Id
              AND status__c = 'Scheduled'
              AND appointment_datetime__c >= :System.now()
            ORDER BY appointment_datetime__c ASC LIMIT 1
        ];
        String nextAppt = appts.isEmpty() ? 'None scheduled'
            : appts[0].appointment_datetime__c.format('dd MMM yyyy', 'Asia/Kolkata');
        stats.put('nextAppointment', nextAppt);
    }

    private static void buildDoctorStats(Map<String, String> stats, Contact c) {
        Date today = Date.today();

        
        Integer apptCount = [
            SELECT COUNT() FROM Appointment__c
            WHERE doctor__c = :c.Id AND DAY_ONLY(appointment_datetime__c) = :today
        ];
        stats.put('todayAppointments', String.valueOf(apptCount));

        
        List<AggregateResult> caseAgg = [
            SELECT COUNT_DISTINCT(case__c) caseTotal
            FROM Medical_Record__c
            WHERE doctor__c = :c.Id AND record_date__c = :today
        ];
        Integer caseCount = caseAgg.isEmpty() ? 0 : Integer.valueOf(caseAgg[0].get('caseTotal'));
        stats.put('todayCases', String.valueOf(caseCount));

        // 3. Next camp date
        List<Healthcare_Event__c> camps = [
            SELECT event_date__c FROM Healthcare_Event__c
            WHERE camp_doctor__c = :c.Id AND event_date__c >= :today
            ORDER BY event_date__c ASC LIMIT 1
        ];
        stats.put('nextCamp', camps.isEmpty() ? 'None scheduled' : String.valueOf(camps[0].event_date__c));
    }
}
