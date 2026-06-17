public without sharing class KizunaTaskController {
    
    public class TaskWrapper {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public Date activityDate { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String whoName { get; set; }
        @AuraEnabled public String whatName { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<TaskWrapper> getDoctorTasks() {
        List<TaskWrapper> wrappers = new List<TaskWrapper>();
        
        try {
            // Query all tasks (as HW creates them and Doctor views them)
            List<Task> tasks = [
                SELECT Id, Subject, Status, Priority, ActivityDate, Description, Who.Name, What.Name 
                FROM Task 
                ORDER BY ActivityDate DESC NULLS LAST
                LIMIT 50
            ];

            for(Task t : tasks) {
                TaskWrapper w = new TaskWrapper();
                w.recordId = t.Id;
                w.subject = t.Subject;
                w.status = t.Status;
                w.priority = t.Priority;
                w.activityDate = t.ActivityDate;
                w.description = t.Description;
                w.whoName = t.Who != null ? t.Who.Name : '';
                w.whatName = t.What != null ? t.What.Name : '';
                wrappers.add(w);
            }
        } catch (Exception e) {
            System.debug('Error fetching tasks: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
        return wrappers;
    }
}
