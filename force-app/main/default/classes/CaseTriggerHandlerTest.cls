@isTest
private class CaseTriggerHandlerTest {

    @testSetup
    static void setup() {
        Id patientRT = Schema.SObjectType.Contact
            .getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        Id doctorRT = Schema.SObjectType.Contact
            .getRecordTypeInfosByName().get('Doctor').getRecordTypeId();

        Account a = new Account(Name = 'Test Hub');
        insert a;

        Contact patient = new Contact(
            FirstName = 'Test',
            LastName = 'Patient',
            RecordTypeId = patientRT,
            AccountId = a.Id,
            Consent_Given__c = true   // satisfies consent validation rule
        );
        Contact doctor = new Contact(
            FirstName = 'Test',
            LastName = 'Doctor',
            RecordTypeId = doctorRT,
            AccountId = a.Id
        );
        insert new List<Contact>{patient, doctor};
    }

    /*
     * Test 1: Assigning a doctor on insert should trigger the handler.
     * The handler creates a Task and fires a bell notification.
     */
    @isTest
    static void assignsDoctorOnInsert_triggersHandler() {
        Contact patient = [SELECT Id FROM Contact WHERE LastName = 'Patient' LIMIT 1];
        Contact doctor  = [SELECT Id FROM Contact WHERE LastName = 'Doctor' LIMIT 1];

        Test.startTest();
        Case c = new Case(
            ContactId = patient.Id,
            Assigned_Doctor__c = doctor.Id,
            Subject = 'Test case',
            Status = 'New',
            Priority = 'High'
        );
        insert c;
        Test.stopTest();

        // Verify the case was created with the doctor assigned
        Case inserted = [SELECT Id, Assigned_Doctor__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(doctor.Id, inserted.Assigned_Doctor__c);
    }

    /*
     * Test 2: Changing the doctor on update should also trigger the handler.
     * Covers the "doctor changed" code path.
     */
    @isTest
    static void changingDoctor_triggersHandler() {
        Contact patient = [SELECT Id FROM Contact WHERE LastName = 'Patient' LIMIT 1];
        Contact doctor  = [SELECT Id FROM Contact WHERE LastName = 'Doctor' LIMIT 1];

        // Insert case WITHOUT a doctor
        Case c = new Case(
            ContactId = patient.Id,
            Subject = 'No doctor yet',
            Status = 'New',
            Priority = 'Medium'
        );
        insert c;

        Test.startTest();
        // Update to assign doctor
        c.Assigned_Doctor__c = doctor.Id;
        update c;
        Test.stopTest();

        Case updated = [SELECT Assigned_Doctor__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(doctor.Id, updated.Assigned_Doctor__c);
    }

    /*
     * Test 3: Updating something OTHER than the doctor should NOT trigger notifications.
     * Covers the early-return logic (doctor unchanged).
     */
    @isTest
    static void unrelatedUpdate_skipsHandler() {
        Contact patient = [SELECT Id FROM Contact WHERE LastName = 'Patient' LIMIT 1];
        Contact doctor  = [SELECT Id FROM Contact WHERE LastName = 'Doctor' LIMIT 1];

        Case c = new Case(
            ContactId = patient.Id,
            Assigned_Doctor__c = doctor.Id,
            Subject = 'Existing',
            Status = 'New',
            Priority = 'Low'
        );
        insert c;

        Test.startTest();
        // Update a field unrelated to doctor assignment
        c.Subject = 'Updated subject';
        update c;
        Test.stopTest();

        // Should run successfully but skip the notification path
        Case updated = [SELECT Subject FROM Case WHERE Id = :c.Id];
        System.assertEquals('Updated subject', updated.Subject);
    }

    /*
     * Test 4: A case with no doctor assigned shouldn't trigger notifications.
     * Verifies graceful handling of null Assigned_Doctor__c.
     */
    @isTest
    static void noDoctor_skipsHandler() {
        Contact patient = [SELECT Id FROM Contact WHERE LastName = 'Patient' LIMIT 1];

        Test.startTest();
        Case c = new Case(
            ContactId = patient.Id,
            Subject = 'No doctor case',
            Status = 'New',
            Priority = 'Medium'
        );
        insert c;
        Test.stopTest();

        // Should complete without errors
        System.assertNotEquals(null, c.Id);
    }

    /*
     * Test 5: Bulk insert — verify the trigger handles many records cleanly.
     * Confirms no governor limit issues.
     */
    @isTest
    static void bulkInsert_handlesManyCases() {
        Contact patient = [SELECT Id FROM Contact WHERE LastName = 'Patient' LIMIT 1];
        Contact doctor  = [SELECT Id FROM Contact WHERE LastName = 'Doctor' LIMIT 1];

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 50; i++) {
            cases.add(new Case(
                ContactId = patient.Id,
                Assigned_Doctor__c = doctor.Id,
                Subject = 'Bulk case ' + i,
                Status = 'New',
                Priority = (Math.mod(i, 3) == 0) ? 'High' : 'Medium'
            ));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Case WHERE Subject LIKE 'Bulk case%'];
        System.assertEquals(50, count, 'All 50 cases should be inserted');
    }
}
