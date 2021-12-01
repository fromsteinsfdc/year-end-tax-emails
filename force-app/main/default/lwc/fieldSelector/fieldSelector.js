import { LightningElement, api, track } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';

import getObjectFields from '@salesforce/apex/FieldSelectorController.getObjectFields';

const CLASSES = {
    PREFIX: '.',
    DROPDOWN_TRIGGER: 'slds-dropdown-trigger',
    IS_OPEN: 'slds-is-open',
}

const ICONS = {
    TEXT: 'utility:text',
    PICKLIST: 'utility:picklist_type',
    DATE: 'utility:date_input',
    DATETIME: 'utility:date_time',
    PERCENT: 'utility:percent',
    NUMBER: 'utility:topic2',
    CURRENCY: 'utility:currency',
    BOOLEAN: 'utility:crossfilter',
    IDENTITY: 'utility:identity'
}

const FIELD_TYPES = {
    BOOLEAN: 'boolean',
    CURRENCY: 'currency',
    STRING: 'string',
    DOUBLE: 'double',
    INTEGER: 'integer',
    DATE: 'date',
    DATETIME: 'datetime',
    PICKLIST: 'picklist',
    PERCENT: 'percent',
    TIME: 'time',
    ID: 'reference'
}

const LIGHTNING = {
    INPUT: 'lightning-input'
}

export default class FieldSelector extends LightningElement {
    @api publicStyle;
    @api label = 'Select Fields';
    @api hidePills;
    @api required;
    @api allowMultiSelect; // TODO: implement
    @api allowLookups;

    @api
    get objectName() {
        return this._objectName;
    }
    set objectName(value) {
        console.log('setting objectName to ' + value);
        this._objectName = value;
        if (!this.objectName) {
            this.placeholder = 'Select an object first'
            this.isLoading = false;
            return;
        }
        this.placeholder = null;
        this.isLoading = true;
        // If the object is changed from the original value, clear any pre-selected fields
        if (this.objectChangeCount > 0) {
            this.selectedFields = [];
            this.dispatchFields();
        }
        this.setFields(this.objectName);
        this.objectChangeCount++;
    }


    @api
    get selectedFields() {
        return this._selectedFields;
    }
    set selectedFields(fields) {
        this._selectedFields = this.shallowCloneArray(fields) || [];
        this.filterOptions();
    }

    @api
    get selectedFieldsNames() {
        return this.selectedFields.map(field => field.name);
    }

    @api
    get selectedFieldsNamesString() {
        return this.selectedFieldsNames.join(',');
    }

    @api
    get selectedFieldsLabelsString() {
        return this.selectedFields.map(field => field.label).join(',');
    }

    @api
    reportValidity() {
        if (!this.required)
            return true;
        let errorMessage = '';
        if (!this.selectedFields.length) {
            errorMessage = this.requiredMissingMessage;
        } else {
            this.inputElement.value = ' ';  // used to still display the 'required' asterisk when required but not cause an error on an empty text box
        }
        this.inputElement.setCustomValidity(errorMessage);
        return this.inputElement.reportValidity();
    }

    @api
    validate() {
        if (this.reportValidity()) {
            return { isValid: true }; 
        } else {
            return { 
                isValid: false, 
                errorMessage: this.requiredMissingMessage
             }; 
        }
    }

    get fields() {
        return this._fields || [];
    }
    set fields(value) {
        this._fields = value;
    }

    @track _fields = [];
    @track _selectedFields = [];
    lookupChain;
    errorMessage;
    isLoading;
    noMatchFoundString = 'No matches found';
    requiredMissingMessage = 'Please select a field.';
    objectChangeCount = 0;
    placeholder;


    getObjectFields(objectName, isLookupObject) {
        // Need to differentiate if we're getting object fields for the "primary" object or getting fields for a related object
        // if (!isLookupObject) {
        //     if (!objectName) {
        //         this.placeholder = 'Select an object first'
        //         this.isLoading = false;
        //         return;
        //     } else {
        //         this.placeholder = null;
        //         this.isLoading = true;
        //         this.fields = [];
        //         // If the object is changed from the original value, clear any pre-selected fields
        //         if (this.objectChangeCount > 0) {
        //             this.selectedFields = [];
        //             this.dispatchFields();
        //         }        
        //     }
        // }
    }

    // @wire(getObjectFields, { objectName: '$objectName' })
    // handleGetObjectFields({ error, data }) {
    //     this.errorMessage = null;
    //     if (error) {
    //         console.log('Error: ' + error.body.message);
    //         this.errorMessage = error.body.message;
    //     }
    //     if (data) {
    //         this.setFields(data);
    //         this.objectChangeCount++;
    //     }
    //     this.isLoading = false;
    // }

    connectedCallback() {
        this.isLoading = true;
        this.allowLookups = true;
    }

    get dropdownTrigger() {
        return this.template.querySelector(CLASSES.PREFIX + CLASSES.DROPDOWN_TRIGGER) || {};
    }

    get inputElement() {
        return this.template.querySelector(LIGHTNING.INPUT);
    }

    get searchLabelCounter() {
        return this.label + ' (' + this.selectedFields.length + ')';
    }

    get isInputDisabled() {
        return !this.objectName || this.isLoading;
    }

    get noMatchFound() {
        return !this.fields.some(field => !field.hidden);
        for (let field of this.fields) {
            if (!field.hidden)
                return false;
        }
        return true;
    }

    get unhiddenFields() {
        return this.fields.filter(field => !field.hidden);
    }

    /* ACTION FUNCTIONS */
    showList() {
        console.log('calling showList');
        this.dropdownTrigger.classList.add(CLASSES.IS_OPEN);
    }

    hideList() {
        this.dropdownTrigger.classList.remove(CLASSES.IS_OPEN);
    }

    setFields(objectName) {
        console.log('in setFields for object: ' + objectName);
        this.isLoading = false;
        getObjectFields({ objectName: objectName })
            .then(fields => {
                this.fields = this.shallowCloneArray(fields);
                let lookupFields = [];
                for (let field of this.fields) {
                    if (this.allowLookups && field.parentObjectName) {
                        // console.log(JSON.stringify(field));
                        let lookupField = Object.assign({}, field);
                        lookupField.isLookup = true;
                        // lookupField.name = field.parentObjectName;
                        // lookupField.label = lookupField.relationshipName;
                        // console.log('pushing lookupField ' + JSON.stringify(lookupField));
                        // console.log('lookupField: '+ JSON.stringify(lookupField));
                        lookupFields.push(lookupField);
                    }
                    field.icon = this.getIconFromFieldType(field.type);
                }
                // this.fields = lookupFields;
                
                // lookupFields.sort((a, b) => {
                //     return a.label.toLowerCase() < b.label.toLowerCase() ? -1 : 1;
                // });
                // this.fields = this.fields.concat(lookupFields);
                // this.fields.push(...lookupFields);
                // this.fields = [...lookupFields, ...this.fields];
                this.fields.sort((a, b) => {
                    return a.label.toLowerCase() < b.label.toLowerCase() ? -1 : 1;
                });
                // this.fields = [...lookupFields, ...this.fields];
                console.log('finished setfields, fields.length = ' + this.fields.length);
            }).catch(error => {
                console.log('Error fetching fields for related object: ' + clickedField.parentObjectName)
            }).finally(() => {
                this.isLoading = false;
            });
    }

    filterOptions(searchText = '') {
        searchText = searchText.trim().toLowerCase();
        console.log('in filterOptions, searchText = ' + searchText);
        if (this.lookupChain && searchText.startsWith(this.lookupChain.toLowerCase())) {
            searchText = searchText.substring(this.lookupChain.length);
        }
        // let filtered = 0;
        // let index = 0;
        if (!this.fields || !this.fields.length) {
            console.log('no fields buddy');
        } else {
            // console.log('found '+ this.fields.length +' buddy');
        }
        console.log('searchText is null = '+ !searchText);
        for (let field of this.fields) {            
            // let isAmount = field.name === 'Amount';
            // console.log(isAmount);
            field.hidden = false;
            if (this.selectedFields.length && this.selectedFields.some(el => el.name === field.name)) {
                console.log('in Amount!', field.name);
                // console.log('still in amount');
                // console.log(JSON.stringify(el));
                // console.log(JSON.stringify(field));
                // console.log('error?');
                field.hidden = true;
                console.log(field.name +' was just hidden because it is already selected');
                console.log('selectedFields = '+ JSON.stringify(this.selectedFields));
            } else {
                // console.log('field = ' + JSON.stringify(field));
                // WARNING: I don't know why some fields are appearing without name
                // console.log('gonna try to unhide');
                if (!searchText || field.name && field.label && (field.name.toLowerCase().includes(searchText) || field.label.toLowerCase().includes(searchText))) {
                    field.hidden = false;
                    // if (isAmount) {
                    //     console.log('amount is NOT hidden because it was found');
                    // }    
                    // field.filteredIndex = index++;
                } else {
                    // filtered++;
                    console.log('hiding '+ field.name +' because ')
                    field.hidden = true;
                    // if (isAmount) {
                    //     console.log('amount was just hidden because it did not match the search term');
                    // }
    
                }
            }
            // console.log('in field '+ field.name);
        }
        // console.log('filtered '+ filtered +' fields');        
    }

    resetSearch() {
        if (this.lookupChain) {
            console.log('resetting search');
            this.lookupChain = null;
            this.setFields(this.objectName);
        }
    }

    dispatchFields() {
        this.dispatchEvent(new CustomEvent('fieldupdate', { detail: { value: this.selectedFields } }));
    }

    selectField(clickedField, event) {
        console.log('clickedField = ' + JSON.stringify(clickedField));
        if (clickedField.isLookup) {
            if (event)
                event.preventDefault();
            console.log('relationship field clicked');
            if (!this.lookupChain) {
                this.lookupChain = '$' + this.objectName + '.';
            }
            this.lookupChain += clickedField.relationshipName + '.';
            this.inputElement.value = this.lookupChain;
            this.setFields(clickedField.parentObjectName);
        } else {
            if (this.lookupChain) {
                let lookupField = Object.assign({}, clickedField);
                lookupField.name = this.lookupChain.substring(this.lookupChain.indexOf('.') + 1) + lookupField.name;
                lookupField.label = this.lookupChain.substring(this.lookupChain.indexOf('.') + 1) + lookupField.label;
                console.log('adding lookupField: ' + JSON.stringify(lookupField));
                this.selectedFields.push(lookupField);
                this.resetSearch();
            } else {
                this.selectedFields.push(clickedField);
            }
            this.inputElement.value = '';
            this.dispatchFields();
        }
    }

    // @api 
    // validate() {
    //     console.log('validating fieldSelector... required = '+ required +' and selectedFields.length = '+ this.selectedFields.length);
    //     if (!required || this.selectedFields.length) {
    //         console.log('validation passed');
    //         return { isValid: true }; 
    //     } 
    //     else { 
    //         // If the component is invalid, return the isValid parameter 
    //         // as false and return an error message. 
    //         console.log('validation failed');
    //         return { 
    //             isValid: false, 
    //             errorMessage: this.requiredMissingMessage
    //          }; 
    //      }
    
    // }

    /* EVENT HANDLERS */
    handleSearchChange() {
        this.filterOptions(this.inputElement.value);
    }

    handleSearchFocus(event) {
        this.filterOptions(this.inputElement.value);
        console.log('in handleSearchFocus, options have been filtered');
        this.showList();
    }

    handleSearchBlur(event) {
        this.resetSearch();
        this.hideList();
        this.reportValidity();
    }

    handleFieldSelect(event) {
        const clickedField = this.fields[event.currentTarget.dataset.index];
        this.selectField(clickedField, event);
    }

    handleFieldUnselect(event) {
        this.selectedFields.splice(event.currentTarget.dataset.index, 1);
        this.dispatchFields();
    }

    /* UTILITY FUNCTIONS */
    shallowCloneArray(arrayToClone) {
        if (!Array.isArray(arrayToClone))
            return null;

        let newArray = [];
        for (let el of arrayToClone) {
            newArray.push(Object.assign({}, el));
        }
        return newArray;
    }

    getIconFromFieldType(fieldType) {
        switch (fieldType.toLowerCase()) {
            case FIELD_TYPES.INTEGER:
            case FIELD_TYPES.DOUBLE:
                return ICONS.NUMBER;
            case FIELD_TYPES.BOOLEAN:
                return ICONS.BOOLEAN;
            case FIELD_TYPES.CURRENCY:
                return ICONS.CURRENCY;
            case FIELD_TYPES.PICKLIST:
                return ICONS.PICKLIST;
            case FIELD_TYPES.PERCENT:
                return ICONS.PERCENT;
            case FIELD_TYPES.DATETIME:
            case FIELD_TYPES.TIME:
                return ICONS.DATETIME;
            case FIELD_TYPES.DATE:
                return ICONS.DATE;
            case FIELD_TYPES.ID:
                return ICONS.IDENTITY;
            default:
                return ICONS.TEXT;
        }
    }
}