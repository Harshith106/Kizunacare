import { LightningElement, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { wire } from 'lwc';
import FILTER_CHANNEL from '@salesforce/messageChannel/KizunaCommunityFilter__c';

export default class KizunaCommunityFilters extends LightningElement {
    @wire(MessageContext) messageContext;

    @track eventStatus = 'All';
    @track eventSearch = '';
    @track programStatus = 'All';
    @track programType = 'All';
    @track programSearch = '';

    // Debounce timers
    eventSearchTimer;
    programSearchTimer;

    get eventStatusOptions() {
        return [
            { label: 'All Statuses', value: 'All' },
            { label: 'Upcoming', value: 'Upcoming' },
            { label: 'Active', value: 'Active' },
            { label: 'Completed', value: 'Completed' },
            { label: 'Cancelled', value: 'Cancelled' }
        ];
    }

    get programStatusOptions() {
        return [
            { label: 'All Statuses', value: 'All' },
            { label: 'Active', value: 'Active' },
            { label: 'Completed', value: 'Completed' },
            { label: 'Inactive', value: 'Inactive' }
        ];
    }

    get programTypeOptions() {
        return [
            { label: 'All Types', value: 'All' },
            { label: 'Vaccination', value: 'Vaccination' },
            { label: 'Nutrition', value: 'Nutrition' },
            { label: 'Mental Health', value: 'Mental Health' },
            { label: 'Maternal Care', value: 'Maternal Care' },
            { label: 'Chronic Disease', value: 'Chronic Disease' }
        ];
    }

    publishFilters() {
        publish(this.messageContext, FILTER_CHANNEL, {
            eventStatus: this.eventStatus,
            eventSearch: this.eventSearch,
            programStatus: this.programStatus,
            programType: this.programType,
            programSearch: this.programSearch
        });
    }

    handleEventStatusChange(event) {
        this.eventStatus = event.detail.value;
        this.publishFilters();
    }

    handleEventSearchChange(event) {
        const val = event.target.value;
        clearTimeout(this.eventSearchTimer);
        this.eventSearchTimer = setTimeout(() => {
            this.eventSearch = val;
            this.publishFilters();
        }, 350);
    }

    handleProgramStatusChange(event) {
        this.programStatus = event.detail.value;
        this.publishFilters();
    }

    handleProgramTypeChange(event) {
        this.programType = event.detail.value;
        this.publishFilters();
    }

    handleProgramSearchChange(event) {
        const val = event.target.value;
        clearTimeout(this.programSearchTimer);
        this.programSearchTimer = setTimeout(() => {
            this.programSearch = val;
            this.publishFilters();
        }, 350);
    }
}


