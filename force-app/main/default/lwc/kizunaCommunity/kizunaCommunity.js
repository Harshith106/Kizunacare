import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, MessageContext } from 'lightning/messageService';
import FILTER_CHANNEL from '@salesforce/messageChannel/KizunaCommunityFilter__c';
import getAllEvents from '@salesforce/apex/KizunaCommunityController.getAllEvents';
import getAllPrograms from '@salesforce/apex/KizunaCommunityController.getAllPrograms';

export default class KizunaCommunity extends NavigationMixin(LightningElement) {
    @wire(MessageContext) messageContext;

    @track activeTab = 'events';
    @track events = [];
    @track programs = [];

    eventStatus = 'All';
    eventSearch = '';
    programStatus = 'All';
    programType = 'All';
    programSearch = '';

    subscription = null;

    connectedCallback() {
        this.subscribeToLms();
        this.loadEvents();
        this.loadPrograms();
    }

    subscribeToLms() {
        if (this.subscription) return;
        this.subscription = subscribe(
            this.messageContext,
            FILTER_CHANNEL,
            (msg) => this.handleFilterMessage(msg)
        );
    }

    handleFilterMessage(msg) {
        this.eventStatus   = msg.eventStatus   || 'All';
        this.eventSearch   = msg.eventSearch   || '';
        this.programStatus = msg.programStatus || 'All';
        this.programType   = msg.programType   || 'All';
        this.programSearch = msg.programSearch || '';
        this.loadEvents();
        this.loadPrograms();
    }

    loadEvents() {
        getAllEvents({ searchTerm: this.eventSearch, statusFilter: this.eventStatus })
            .then(data => { this.events = data; })
            .catch(err => { console.error('Events error:', err); this.events = []; });
    }

    loadPrograms() {
        getAllPrograms({ searchTerm: this.programSearch, statusFilter: this.programStatus, typeFilter: this.programType })
            .then(data => { this.programs = data; })
            .catch(err => { console.error('Programs error:', err); this.programs = []; });
    }

    get showEvents()   { return this.activeTab === 'events'; }
    get showPrograms() { return this.activeTab === 'programs'; }
    get hasEvents()    { return this.events   && this.events.length   > 0; }
    get hasPrograms()  { return this.programs && this.programs.length > 0; }

    get eventsTabClass()   { return this.activeTab === 'events'   ? 'tab-btn tab-btn--active' : 'tab-btn'; }
    get programsTabClass() { return this.activeTab === 'programs' ? 'tab-btn tab-btn--active' : 'tab-btn'; }

    handleTabSelect(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        const objectApiName = event.currentTarget.dataset.object;
        if (recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId, objectApiName, actionName: 'view' }
            });
        }
    }
}
