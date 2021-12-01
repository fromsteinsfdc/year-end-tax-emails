import { LightningElement, api, track } from 'lwc';

export default class TableStyler extends LightningElement {
    @api tableStyle = 'width:100%;border-collapse:collapse;border:2px solid black';
    @api headerStyle = 'background-color:dodgerblue;color:white';
    @api bodyCellStyle = 'border:2px solid black;padding:5px';
    @api headerCellStyle = 'border:2px solid black;padding:5px';

    get tableAttributes() {
        return this._tableAttributes;
    }
    set tableAttributes(value) {
        this._tableAttributes = value || [];
    }
    _tableAttributes = [];

    @track records = [];

    columns = [
        { fieldName: 'Amount', label: 'Amount' },
        { fieldName: 'CloseDate', label: 'Close Date' },
    ];
}