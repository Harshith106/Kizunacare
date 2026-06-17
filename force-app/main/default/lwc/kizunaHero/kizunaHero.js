import { LightningElement, track, wire } from 'lwc';
import getUserInfo from '@salesforce/apex/KizunaHeroController.getUserInfo';

export default class KizunaHero extends LightningElement {
    @track userName = 'User';
    @track userRole = 'User';
    @track subtitle = '';
    @track greeting = '';
    @track timeSlot = 'morning'; // morning | afternoon | evening | night

    @wire(getUserInfo)
    wiredUser({ data, error }) {
        if (data) {
            this.userName = data.name;
            this.userRole = data.role;
            this.subtitle  = data.subtitle;
        }
        if (error) console.error(error);
    }

    connectedCallback() {
        const h = new Date().getHours();
        if      (h >= 5  && h < 12) { this.greeting = 'Good Morning';   this.timeSlot = 'morning';   }
        else if (h >= 12 && h < 17) { this.greeting = 'Good Afternoon'; this.timeSlot = 'afternoon'; }
        else if (h >= 17 && h < 21) { this.greeting = 'Good Evening';   this.timeSlot = 'evening';   }
        else                        { this.greeting = 'Good Night';     this.timeSlot = 'night';     }
    }

    get isMorning()   { return this.timeSlot === 'morning';   }
    get isAfternoon() { return this.timeSlot === 'afternoon'; }
    get isEvening()   { return this.timeSlot === 'evening';   }
    get isNight()     { return this.timeSlot === 'night';     }
    get isDoctor()    { return this.userRole  === 'Doctor';   }
    get isPatient()   { return this.userRole  === 'Patient';  }

    get heroTitle() {
        return this.isDoctor
            ? 'Empowering Rural Healthcare'
            : 'Your Health, Our Mission';
    }

    get heroSubtitle() {
        return this.isDoctor
            ? 'Connecting doctors with communities that need you most.'
            : 'Accessible, compassionate care — wherever you are.';
    }
}
