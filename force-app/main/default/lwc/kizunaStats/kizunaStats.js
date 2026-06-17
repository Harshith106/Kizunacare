import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getStats from '@salesforce/apex/KizunaStatsController.getStats';
import getHealthworkerId from '@salesforce/apex/KizunaCommunityController.getHealthworkerId';

const HW_FIELDS = [
    'Contact.Name',
    'Contact.Phone',
    'Contact.MobilePhone',
    'Contact.Email',
    'Contact.Languages__c',
    'Contact.Qualification__c'
];

export default class KizunaStats extends LightningElement {
    @track role          = '';
    @track errorMessage  = '';

    // Patient stats
    @track activeCases     = '0';
    @track lastVisit       = '--';
    @track nextAppointment = '--';

    // Doctor stats
    @track todayCases        = '0';
    @track todayAppointments = '0';
    @track nextCamp          = '--';

    // Healthworker (patient only)
    @track hwId = null;

    @wire(getStats)
    wiredStats({ data, error }) {
        if (data) {
            this.role              = data.role              || '';
            this.activeCases       = data.activeCases       || '0';
            this.lastVisit         = data.lastVisit         || '--';
            this.nextAppointment   = data.nextAppointment   || '--';
            this.todayCases        = data.todayCases        || '0';
            this.todayAppointments = data.todayAppointments || '0';
            this.nextCamp          = data.nextCamp          || '--';
        }
        if (error) {
            this.errorMessage = error.body ? error.body.message : JSON.stringify(error);
        }
    }

    @wire(getHealthworkerId)
    wiredHwId({ data, error }) {
        if (data) {
            this.hwId = data;
        } else if (error) {
            console.error('getHealthworkerId error:', error);
        }
    }

    @wire(getRecord, { recordId: '$hwId', fields: HW_FIELDS })
    hwRecord;

    get healthworker() {
        if (!this.hwRecord || !this.hwRecord.data) return null;
        const f = this.hwRecord.data.fields;
        return {
            Name:           f.Name           ? f.Name.value           : '',
            Phone:          f.Phone          ? f.Phone.value          : (f.MobilePhone ? f.MobilePhone.value : ''),
            Email:          f.Email          ? f.Email.value          : '',
            Languages__c:   f.Languages__c   ? f.Languages__c.value   : '',
            Qualification__c: f.Qualification__c ? f.Qualification__c.value : ''
        };
    }

    get hasHealthworker() { return this.isPatient && !!this.healthworker; }

    get isPatient() { return this.role.toLowerCase().includes('patient'); }
    get isDoctor()  { return this.role.toLowerCase().includes('doctor');  }
    get hasError()  { return !!this.errorMessage; }
    get noRole()    { return !this.isPatient && !this.isDoctor && !this.hasError; }
}
