import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyMedicalRecords from '@salesforce/apex/KizunaMedicalRecordController.getMyMedicalRecords';
import isDoctorUser from '@salesforce/apex/KizunaMedicalRecordController.isDoctorUser';

export default class KizunaMedicalRecords extends NavigationMixin(LightningElement) {
    @track isDoctor = false;
    @track categoryFilter = 'All';
    @track dateFilter = 'All';
    
    @track allRecords = [];

    get categoryOptions() {
        return [
            { label: 'All Categories', value: 'All' },
            { label: 'Prescription',   value: 'Prescription' },
            { label: 'Lab Test',       value: 'Lab Test' },
            { label: 'Immunization',   value: 'Immunization' }
        ];
    }

    get dateOptions() {
        return [
            { label: 'All Time',      value: 'All' },
            { label: 'Last 30 Days',  value: 'Last30' },
            { label: 'Last Year',     value: 'LastYear' }
        ];
    }

    @wire(isDoctorUser)
    wiredIsDoctor({ error, data }) {
        if (data !== undefined) {
            this.isDoctor = data;
        } else if (error) {
            console.error('Error checking user type:', error);
        }
    }

    @wire(getMyMedicalRecords)
    wiredRecords({ error, data }) {
        if (data) {
            this.allRecords = data.map(rec => {
                let categoryClass = 'category-badge ';
                if (rec.category === 'Prescription') categoryClass += 'cat-prescription';
                else if (rec.category === 'Lab Test') categoryClass += 'cat-lab';
                else if (rec.category === 'Immunization') categoryClass += 'cat-vaccine';
                else categoryClass += 'cat-default';

                let displayDate = '—';
                let adjDate = null;
                if (rec.recordDate) {
                    const dt = new Date(rec.recordDate);
                    const offset = dt.getTimezoneOffset() * 60000;
                    adjDate = new Date(dt.getTime() + offset);
                    displayDate = adjDate.toLocaleDateString();
                }

                return { ...rec, categoryClass, displayDate, _dateObj: adjDate };
            });
        } else if (error) {
            console.error('Error loading medical records:', error);
            this.allRecords = [];
        }
    }

    get filteredRecords() {
        if (!this.allRecords) return [];
        const today = new Date(); today.setHours(0, 0, 0, 0);
        
        const thirtyDaysAgo = new Date(today);
        thirtyDaysAgo.setDate(today.getDate() - 30);
        
        const oneYearAgo = new Date(today);
        oneYearAgo.setFullYear(today.getFullYear() - 1);

        return this.allRecords.filter(rec => {
            if (this.categoryFilter !== 'All' && rec.category !== this.categoryFilter) return false;
            if (this.dateFilter !== 'All' && rec._dateObj) {
                if (this.dateFilter === 'Last30' && rec._dateObj < thirtyDaysAgo) return false;
                if (this.dateFilter === 'LastYear' && rec._dateObj < oneYearAgo) return false;
            }
            return true;
        });
    }

    get hasRecords() {
        return this.filteredRecords.length > 0;
    }

    handleCategoryChange(event) { this.categoryFilter = event.detail.value; }
    handleDateChange(event)     { this.dateFilter = event.detail.value; }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId, objectApiName: 'Medical_Record__c', actionName: 'view' }
            });
        }
    }

    handleNewRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Medical_Record__c', actionName: 'new' }
        });
    }
}
