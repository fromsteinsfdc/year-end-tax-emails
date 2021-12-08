import { LightningElement, api, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';

export default class GetIdsFromListViewHelper extends LightningElement {
    @api objectApiName;
    @api listViewApiName;
    @api recordIds = [];

    isLoading;

    connectedCallback() {
        console.log('in connectedCallback');
        this.isLoading = true;
    }

    @wire(getListUi, { objectApiName: '$objectApiName', listViewApiName: '$listViewApiName' })
    _getListUi({ error, data }) {
        if (error) {
            console.log('Error: '+ JSON.stringify(error));
        }
        if (data) {
            console.log('finished getting recordIds from getListUi');
            // let recordIds = [];
            for (let record of data.records.records) {
                this.recordIds.push(record.id);
            }
            this.isLoading = false;
            // this.recordIds = recordIds;
            // Fire the custom event
            this.dispatchEvent(new CustomEvent('newrecordids', {
                detail: { 
                    recordIds: this.recordIds
                }
            }));
        }
    }
}