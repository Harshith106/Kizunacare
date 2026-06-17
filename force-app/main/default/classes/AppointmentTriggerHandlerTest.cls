@isTest
private class AppointmentTriggerHandlerTest {

    @testSetup
    static void setupData() {

        Id patientRtId = Schema.SObjectType.Contact
            .getRecordTypeInfosByName()
            .get('Patient')
            .getRecordTypeId();
            
        Id doctorRtId = Schema.SObjectType.Contact
            .getRecordTypeInfosByName()
            .get('Doctor')
            .getRecordTypeId();

        Contact patient = new Contact(
            LastName = 'Test Patient',
            Email = 'patient@test.com',
            RecordTypeId = patientRtId
        );
        
        Contact doctor = new Contact(
            LastName = 'Test Doctor',
            Email = 'doctor@test.com',
            RecordTypeId = doctorRtId
        );

        insert new List<Contact>{patient, doctor};
    }

    @isTest
    static void testAppointmentWithPatient() {

        Contact patient = [
            SELECT Id
            FROM Contact
            WHERE Email = 'patient@test.com'
            LIMIT 1
        ];
        
        Contact doctor = [
            SELECT Id
            FROM Contact
            WHERE Email = 'doctor@test.com'
            LIMIT 1
        ];

        Test.startTest();

        Appointment__c appt = new Appointment__c(
            Patient__c = patient.Id,
            Doctor__c = doctor.Id
        );

        insert appt;

        Test.stopTest();

        System.assertNotEquals(
            null,
            appt.Id,
            'Appointment should be inserted successfully'
        );
    }

    @isTest
    static void testAppointmentWithoutPatient() {

        Test.startTest();

        Appointment__c appt = new Appointment__c();

        insert appt;

        Test.stopTest();

        System.assertNotEquals(
            null,
            appt.Id,
            'Appointment should be inserted successfully'
        );
    }

    @isTest
    static void testBulkInsertAppointments() {

        Contact patient = [
            SELECT Id
            FROM Contact
            WHERE Email = 'patient@test.com'
            LIMIT 1
        ];
        
        Contact doctor = [
            SELECT Id
            FROM Contact
            WHERE Email = 'doctor@test.com'
            LIMIT 1
        ];

        List<Appointment__c> appointments = new List<Appointment__c>();

        for(Integer i = 0; i < 200; i++) {
            appointments.add(
                new Appointment__c(
                    Patient__c = patient.Id,
                    Doctor__c = doctor.Id
                )
            );
        }

        Test.startTest();
        insert appointments;
        Test.stopTest();

        System.assertEquals(
            200,
            appointments.size(),
            'All appointments should be inserted'
        );
    }
}