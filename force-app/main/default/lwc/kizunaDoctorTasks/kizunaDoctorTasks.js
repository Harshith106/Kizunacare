import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDoctorTasks from '@salesforce/apex/KizunaTaskController.getDoctorTasks';

export default class KizunaDoctorTasks extends NavigationMixin(LightningElement) {
    @track allTasks = [];
    @track statusFilter = 'All';

    get statusOptions() {
        return [
            { label: 'All Tasks', value: 'All' },
            { label: 'Open', value: 'Open' },
            { label: 'Completed', value: 'Completed' }
        ];
    }

    @wire(getDoctorTasks)
    wiredTasks({ error, data }) {
        if (data) {
            this.allTasks = data.map(tsk => {
                let statusClass = 'status-badge ';
                if (tsk.status === 'Completed' || tsk.status === 'Resolved' || tsk.status === 'Closed') {
                    statusClass += 'badge-green';
                } else if (tsk.status === 'New' || tsk.status === 'Not Started') {
                    statusClass += 'badge-blue';
                } else {
                    statusClass += 'badge-yellow';
                }

                let priorityClass = 'priority-badge ';
                if (tsk.priority === 'High') priorityClass += 'priority-red';
                else if (tsk.priority === 'Normal' || tsk.priority === 'Medium') priorityClass += 'priority-yellow';
                else priorityClass += 'priority-green';

                let formattedDate = 'No Due Date';
                if (tsk.activityDate) {
                    const d = new Date(tsk.activityDate);
                    formattedDate = d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
                }

                return {
                    ...tsk,
                    statusClass,
                    priorityClass,
                    formattedDate
                };
            });
        } else if (error) {
            console.error('Error fetching tasks', error);
            this.allTasks = [];
        }
    }

    get hasTasks() {
        return this.allTasks && this.allTasks.length > 0;
    }

    get filteredTasks() {
        if (this.statusFilter === 'All') return this.allTasks;
        
        if (this.statusFilter === 'Completed') {
            return this.allTasks.filter(t => t.status === 'Completed' || t.status === 'Resolved' || t.status === 'Closed');
        } else if (this.statusFilter === 'Open') {
            return this.allTasks.filter(t => t.status !== 'Completed' && t.status !== 'Resolved' && t.status !== 'Closed');
        }
        
        return this.allTasks;
    }

    get hasFilteredTasks() {
        const ft = this.filteredTasks;
        return ft && ft.length > 0;
    }

    handleStatusChange(event) {
        this.statusFilter = event.detail.value;
    }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Task',
                    actionName: 'view'
                }
            });
        }
    }

    handleNewTask() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            }
        });
    }
}

