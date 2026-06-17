import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyCases from '@salesforce/apex/KizunaCaseController.getMyCases';

export default class KizunaMedicalCases extends NavigationMixin(LightningElement) {
    @track statusFilter   = 'All';
    @track priorityFilter = 'All';
    @track dateFilter     = 'All';

    @track allCases = [];

    get statusOptions() {
        return [
            { label: 'All Statuses',  value: 'All' },
            { label: 'New',           value: 'New' },
            { label: 'In Progress',   value: 'In Progress' },
            { label: 'Resolved',      value: 'Resolved' },
            { label: 'Closed',        value: 'Closed' }
        ];
    }
    get priorityOptions() {
        return [
            { label: 'All Priorities', value: 'All' },
            { label: 'High',           value: 'High' },
            { label: 'Medium',         value: 'Medium' },
            { label: 'Low',            value: 'Low' }
        ];
    }
    get dateOptions() {
        return [
            { label: 'All Time',  value: 'All' },
            { label: 'Upcoming',  value: 'Upcoming' },
            { label: 'Past',      value: 'Past' }
        ];
    }

    @wire(getMyCases)
    wiredCases({ data, error }) {
        if (data) {
            // Process data once for optimal performance
            this.allCases = data.map(c => {
                let statusClass = 'status-badge ';
                if (c.status === 'Closed' || c.status === 'Resolved') statusClass += 'badge-green';
                else if (c.status === 'New') statusClass += 'badge-blue';
                else statusClass += 'badge-yellow';

                let priorityClass = 'priority-badge ';
                if (c.priority === 'High') priorityClass += 'priority-red';
                else if (c.priority === 'Medium') priorityClass += 'priority-yellow';
                else priorityClass += 'priority-green';

                let displayDate = 'Not Scheduled';
                let adjDate = null;
                if (c.visitDate) {
                    const dt = new Date(c.visitDate);
                    const offset = dt.getTimezoneOffset() * 60000;
                    adjDate = new Date(dt.getTime() + offset);
                    displayDate = adjDate.toLocaleDateString();
                }

                return { ...c, statusClass, priorityClass, displayDate, _dateObj: adjDate };
            });
        } else if (error) {
            console.error('Cases error:', error);
            this.allCases = [];
        }
    }

    get filteredCases() {
        if (!this.allCases) return [];
        const today = new Date(); today.setHours(0, 0, 0, 0);

        return this.allCases.filter(c => {
            if (this.statusFilter !== 'All' && c.status !== this.statusFilter) return false;
            if (this.priorityFilter !== 'All' && c.priority !== this.priorityFilter) return false;
            if (this.dateFilter !== 'All' && c._dateObj) {
                if (this.dateFilter === 'Upcoming' && c._dateObj < today) return false;
                if (this.dateFilter === 'Past' && c._dateObj >= today) return false;
            }
            return true;
        });
    }

    get hasCases() { return this.filteredCases.length > 0; }

    handleStatusChange(event)   { this.statusFilter   = event.detail.value; }
    handlePriorityChange(event) { this.priorityFilter = event.detail.value; }
    handleDateChange(event)     { this.dateFilter     = event.detail.value; }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/kizunacasedetailpage?recordId=' + recordId
                }
            });
        }
    }
}
