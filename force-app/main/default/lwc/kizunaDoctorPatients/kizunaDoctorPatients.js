import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyPatients from '@salesforce/apex/KizunaPatientController.getMyPatients';

export default class KizunaDoctorPatients extends NavigationMixin(LightningElement) {
    @track patients = [];
    @wire(getMyPatients)
    wiredPatients({ error, data }) {
        if (data) {
            this.patients = data;
        } else if (error) {
            this.patients = [];
        }
    }

    get hasPatients() {
        return this.patients && this.patients.length > 0;
    }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'My_Patients__c',
                    actionName: 'view'
                }
            });
        }
    }
}
