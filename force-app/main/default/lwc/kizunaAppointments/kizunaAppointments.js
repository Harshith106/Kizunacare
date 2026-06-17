import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyAppointments from '@salesforce/apex/KizunaAppointmentController.getMyAppointments';

export default class KizunaAppointments extends NavigationMixin(LightningElement) {
    @track statusFilter = 'All';
    @track typeFilter = 'All';
    @track dateFilter = 'All';
    
    @track allAppointments = [];

    get statusOptions() {
        return [
            { label: 'All Statuses', value: 'All' },
            { label: 'Scheduled', value: 'Scheduled' },
            { label: 'Confirmed', value: 'Confirmed' },
            { label: 'Completed', value: 'Completed' },
            { label: 'Cancelled', value: 'Cancelled' },
            { label: 'No-Show', value: 'No-Show' }
        ];
    }

    get typeOptions() {
        return [
            { label: 'All Types', value: 'All' },
            { label: 'Follow-Up', value: 'Follow-Up' },
            { label: 'Camp Visit', value: 'Camp Visit' },
            { label: 'Specialist Consultation', value: 'Specialist Consultation' }
        ];
    }

    get dateOptions() {
        return [
            { label: 'All Time', value: 'All' },
            { label: 'Upcoming', value: 'Upcoming' },
            { label: 'Past', value: 'Past' }
        ];
    }

    @wire(getMyAppointments)
    wiredAppointments({ error, data }) {
        if (data) {
            this.allAppointments = data.map(appt => {
                let statusClass = 'status-badge ';
                if (appt.status === 'Completed') statusClass += 'badge-green';
                else if (appt.status === 'Cancelled' || appt.status === 'No-Show' || appt.status === 'No Show') statusClass += 'badge-red';
                else statusClass += 'badge-blue';

                let displayDate = '';
                let adjDate = null;
                if (appt.appointmentDate) {
                    const dt = new Date(appt.appointmentDate);
                    adjDate = dt;
                    displayDate = dt.toLocaleDateString() + ' at ' + dt.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
                }

                return { ...appt, statusClass, displayDate, _dateObj: adjDate };
            });
        } else if (error) {
            console.error('Error loading appointments:', error);
            this.allAppointments = [];
        }
    }

    get filteredAppointments() {
        if (!this.allAppointments) return [];
        const now = new Date();

        return this.allAppointments.filter(appt => {
            if (this.statusFilter !== 'All' && appt.status !== this.statusFilter) return false;
            if (this.typeFilter !== 'All' && appt.appointmentType !== this.typeFilter) return false;
            if (this.dateFilter !== 'All' && appt._dateObj) {
                if (this.dateFilter === 'Upcoming' && appt._dateObj < now) return false;
                if (this.dateFilter === 'Past' && appt._dateObj >= now) return false;
            }
            return true;
        });
    }

    get hasAppointments() {
        return this.filteredAppointments.length > 0;
    }

    handleStatusChange(event) { this.statusFilter = event.detail.value; }
    handleTypeChange(event)   { this.typeFilter = event.detail.value; }
    handleDateChange(event)   { this.dateFilter = event.detail.value; }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId, objectApiName: 'Appointment__c', actionName: 'view' }
            });
        }
    }
}
