import { LightningElement, api, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';

export default class GetIdsFromListViewHelper extends LightningElement {
    @api objectApiName;
    @api listViewApiName;
    @api recordIds = [];

    @wire(getListUi, { objectApiName: '$objectApiName', listViewApiName: '$listViewApiName' })
    _getListUi({ error, data }) {
        if (error) {
            console.log('Error: '+ JSON.stringify(error));
        }
        if (data) {
            for (let record of data.records.records) {
                console.log('record: '+ JSON.stringify(record));
                this.recordIds.push(record.id);
            }
        }
    }
}