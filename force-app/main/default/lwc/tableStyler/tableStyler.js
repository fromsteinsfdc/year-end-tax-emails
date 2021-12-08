import { LightningElement, api, track } from 'lwc';
import getObjectFields from '@salesforce/apex/FieldSelectorController.getObjectFields';

const DEFAULT_COLUMNS = {
    AMOUNT: { fieldName: 'Amount', label: 'Amount' },
    CLOSEDATE: { fieldName: 'CloseDate', label: 'Close Date' },
    ID: { fieldName: 'Id', label: 'ID' }
}

export default class TableStyler extends LightningElement {

    @api 
    get fieldNamesString() {
        return this._fieldNamesString;
    }
    set fieldNamesString(value) {
        this._fieldNamesString = value;
        this.isLoading = false;
        getObjectFields({ objectName: objectName })
            .then(fields => {
                this.fields = this.shallowCloneArray(fields);
                let lookupFields = [];
                for (let field of this.fields) {
                    if (this.allowLookups && field.parentObjectName) {
                        let lookupField = Object.assign({}, field);
                        lookupField.isLookup = true;
                        lookupFields.push(lookupField);
                    }
                    field.icon = this.getIconFromFieldType(field.type);
                }
                this.fields.sort((a, b) => {
                    return a.label.toLowerCase() < b.label.toLowerCase() ? -1 : 1;
                });
                console.log('finished setfields, fields.length = ' + this.fields.length);
            }).catch(error => {
                console.log('Error fetching fields for related object: ' + clickedField.parentObjectName)
            }).finally(() => {
                this.isLoading = false;
            });
    }
    _fieldNamesString;

    @api defaultTableStyle;
    // @api defaultHeaderStyle = 'background-color:dodgerblue;color:white'; // deprecated?
    @api defaultBodyCellStyle = 'border:2px solid black;padding:0.5em';
    @api defaultHeaderCellStyle = 'border:2px solid black;padding:0.5em';
    
    @api tableStyle;
    @api bodyCellStyle;
    @api headerCellStyle;

    tableElementOptions = [
        { label: 'Table (overall)', value: 'table' },
        { label: 'Table (overall)', value: 'table' },
        { label: 'Table (overall)', value: 'table' },
        { label: 'Table (overall)', value: 'table' },
    ]

    get tableAttributes() {
        return this._tableAttributes;
    }
    set tableAttributes(value) {
        this._tableAttributes = value || [];
    }
    _tableAttributes = [];

    @track records = [];

    columns = Object.values(DEFAULT_COLUMNS);

    records = [
        { 
            fields: [
                { name: 'Amount', value: '$5,000' },
                { name: 'CloseDate', value: '9/17/2020' },
                { name: 'Id', value: '301555555025arjw' }
            ]
        },
        { 
            fields: [
                { name: 'Amount', value: '$12,000' },
                { name: 'CloseDate', value: '10/26/2020' },
                { name: 'Id', value: '301555555025arkv' }
            ]
        }
    ];
    
    connectedCallback() {            
        // this.tableStyle = this.tableStyle || this.defaultTableStyle;
        // this.bodyCellStyle = this.bodyCellStyle || this.defaultBodyCellStyle;
        // this.headerCellStyle = this.headerCellStyle || this.defaultHeaderCellStyle;
        this.defaultTableStyle = this.tableStyle;
        this.defaultHeaderCellStyle = this.headerCellStyle;
        this.defaultBodyCellStyle = this.bodyCellStyle;        
    }

    handleControlChange(event) {
        this[event.target.dataset.property] = event.target.value;
    }

    handleResetClick() {
        this.tableStyle = this.defaultTableStyle;
        this.bodyCellStyle = this.defaultBodyCellStyle;
        this.headerCellStyle = this.defaultHeaderCellStyle;
    }
}