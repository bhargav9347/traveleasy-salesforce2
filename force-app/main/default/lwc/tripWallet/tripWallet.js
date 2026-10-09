import { LightningElement, api, wire, track } from 'lwc';
import getTripWalletData from '@salesforce/apex/TripWalletController.getTripWalletData';

export default class TripWallet extends LightningElement {
    @api recordId;
    @track walletData;
    @track error;
    @track isLoading = true;

    @wire(getTripWalletData, { travelRequestId: '$recordId' })
    wiredWallet({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.walletData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error';
            this.walletData = undefined;
        }
    }

    get hasExpenseItems() {
        return this.walletData && this.walletData.expenseItems && this.walletData.expenseItems.length > 0;
    }

    get utilizationPercentage() {
        if (!this.walletData || !this.walletData.estimatedCost || this.walletData.estimatedCost === 0) {
            return 0;
        }
        const pct = (this.walletData.actualCost / this.walletData.estimatedCost) * 100;
        return Math.min(Math.round(pct), 100);
    }
}
