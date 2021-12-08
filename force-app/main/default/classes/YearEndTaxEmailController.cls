public without sharing class YearEndTaxEmailController {    

    public static String noOpportunitiesMessage = 'No donations were found that fit the criteria.';
    public static String success = 'success';
    public static String error = 'error';

    @InvocableMethod(label='Send Year End Tax Email!')
    public static List<Result> sendEmail(List<Request> reqs) {        
        Request req = reqs[0];
        Result res;
        System.debug('in YearEndTaxEmailSend, req = '+ req);
        if (req.contactIds.size() == 0) {
            res = new Result(error, 'Contact List View ['+ req.listViewId +'] does not contain any Contacts');
        } else {
            try {
                List<contact> updatedContacts = constructGiftTable(req.contactIds, req.fieldNamesString.split(','), req.tableStyle, req.headerCellStyle, req.bodyCellStyle);
                if (updatedContacts == null || updatedContacts.size() == 0) {

                }
                System.debug('first updated contact: '+ updatedContacts[0]);
                update updatedContacts;
                try {
                    List<Messaging.SingleEmailMessage> messages = sendEmailTemplateToContacts(req.emailTemplateId, req.contactIds);
                    // List<Messaging.SingleEmailMessage> messages = generateEmailMessages(req.emailTemplateId, req.contactIds);
                    // Messaging.sendEmail(messages);
                    // executeMessagingSend(messages);
                    res = new Result(success, 'You have successfully sent '+ req.contactIds.size() +' messages');
                    String emailTemplateName = [SELECT Name FROM EmailTemplate WHERE Id =: req.emailTemplateId].Name;
                    res.logId = logMessages(success, req.emailTemplateId, emailTemplateName +' - '+ Datetime.now(), messages);
                } catch (Exception e) {
                    res = new Result(error, 'There was an error sending out the emails: '+ e.getMessage());
                    String emailTemplateName = [SELECT Name FROM EmailTemplate WHERE Id =: req.emailTemplateId].Name;
                    // res.logId = logMessages(error, req.emailTemplateId, emailTemplateName +' - '+ Datetime.now(), messages);
                }
            } catch (Exception e) {
                String nameString = req.fieldNamesString;                
                System.debug('field names = '+ nameString);
                System.debug(e.getMessage());
                res = new Result(error, 'Error constructing Contact gift table with field names "'+nameString +'": '+ e.getMessage());                
            }
        }
        System.debug('result = '+ res);
        return new List<Result>{res};
    }

    // @future
    // public static void executeMessagingSend(List<Messaging.SingleEmailMessage> messages) {
    //     Messaging.sendEmail(messages);
    // }

    public static List<Messaging.SingleEmailMessage> sendEmailTemplateToContacts(Id emailTemplateId, List<Id> contactIds) {
        System.debug('req.emailTemplateId = '+ emailTemplateId);
        System.debug('req.contactIds = '+ contactIds);
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Id contactId : contactIds) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTargetObjectId(contactId);
            msg.setTemplateId(emailTemplateId);
            messages.add(msg);
        }
        try {
            Messaging.sendEmail(messages);
        } catch (Exception e) {
            // return null;
        }
        return messages;
    }    

    public static List<Messaging.SingleEmailMessage> generateEmailMessages(Id emailTemplateId, List<Id> contactIds) {
        System.debug('req.emailTemplateId = '+ emailTemplateId);
        System.debug('req.contactIds = '+ contactIds);
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Id contactId : contactIds) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTargetObjectId(contactId);
            msg.setTemplateId(emailTemplateId);
            messages.add(msg);
        }
        return messages;
    }    

    public static Id logMessages(String result, String emailTemplateId, String logEventName, List<Messaging.SingleEmailMessage> messages) {
        Mass_Email_Log__c newLog = new Mass_Email_Log__c();
        newLog.Name = logEventName;
        newLog.Email_Template_ID__c = emailTemplateId;
        newLog.Result__c = result;
        insert newLog;

        List<Mass_Email_Log_Item__c> logItems = new List<Mass_Email_Log_Item__c>();
        for (Messaging.SingleEmailMessage message : messages) {
            Mass_Email_Log_Item__c newItem = new Mass_Email_Log_Item__c();
            newItem.Mass_Email_Log__c = newLog.Id;
            newItem.Contact__c = message.getTargetObjectId();
            newItem.Email__c = [SELECT Email FROM Contact WHERE Id =: newItem.Contact__c].Email;
            newItem.Status__c = success;
            newItem.Email_Content__c = message.getHtmlBody();
            logItems.add(newItem);
        }
        insert logItems;

        return newLog.Id;
    }

    // public static Map<String, Map<String, String>> defaultTableStyle() {
    //     Map<String, Map<String, String>> returnMap = new Map<String, Map<String, String>>();
    //     return returnMap;
    // }

    public static List<Contact> getContactsWithPopulatedFieldValues(List<Id> contactIds, List<String> opportunityFieldNames) {        
        return null;
    }

    public static List<Contact> constructGiftTable(List<Id> contactIds, List<String> opportunityFieldNames, String tableStyle, String headerCellStyle, String bodyCellStyle) {        
        // String tableStyle = 'width:100%;border-collapse:collapse;border:2px solid black';
        // String headerStyle = 'background-color:dodgerblue;color:white';
        // String bodyCellStyle = 'border:2px solid black';
        // String headerCellStyle = 'border:2px solid black';

        System.debug('in constructGiftTable');
        String fieldNameString = String.join(opportunityFieldNames, ',');
        Map<String, FieldSelectorController.Field> fields = getFields('Opportunity', opportunityFieldNames);


        Map<Id, Opportunity> oppMapWithContactId = new Map<Id, Opportunity>([SELECT npsp__Primary_Contact__c FROM Opportunity WHERE npsp__Primary_Contact__c IN :contactIds AND CloseDate = LAST_YEAR AND IsWon = true]);
        List<Opportunity> opps = Database.query('SELECT '+ fieldNameString +' FROM Opportunity WHERE npsp__Primary_Contact__c IN :contactIds AND CloseDate = LAST_YEAR AND IsWon = true ORDER BY CloseDate ASC');
        List<Contact> contacts = [SELECT Id, Gifts_Last_Year__c FROM Contact WHERE Id IN :contactIds];        
        Map<Id, List<Opportunity>> contactOppMap = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : opps) {
            Id contactId = oppMapWithContactId.get(opp.Id).npsp__Primary_Contact__c;
            if (contactOppMap.containsKey(contactId)) {
                contactOppMap.get(contactId).add(opp);
            } else {
                contactOppMap.put(contactId, new List<Opportunity>{opp});
            }
        }
        // String cellStyle = 'border:1px solid black;padding:5px';
        for (Contact con : contacts) {
            System.debug('loop through contact '+ con.Id);
            String tableString = '<table style="'+ tableStyle +'"><thead><tr>';
            for (String fieldName : fields.keySet()) {            
                String cellString = '<th style="'+ headerCellStyle +'">'+ fields.get(fieldName).label +'</th>';
                System.debug('cellString = '+ cellString);
                tableString += cellString;
            }
            tableString += '</tr>';
            System.debug('tableString after header row = '+ tableString);
            System.debug('contactOppMap.containsKey = '+ contactOppMap.containsKey(con.Id));
            if (!contactOppMap.containsKey(con.Id)) {
                // This contact has no opportunities
                tableString = noOpportunitiesMessage;
            } else {
                for (Opportunity opp : contactOppMap.get(con.Id)) {
                    tableString += '<tr></thead><tbody>';
                    for (String fieldName : fields.keySet()) {
                        Object fieldValue = opp.get(fieldName);
                        if (fieldValue instanceof Date) {
                            fieldValue = ((Date)fieldValue).format();
                        }
                        else if (fieldValue instanceof Decimal) {
                            fieldValue = ((Decimal)fieldValue).format();
                            if (fields.get(fieldName).type.toLowerCase() == 'currency') {
                                fieldValue = '$' + fieldValue;
                            }
                        } 
                        System.debug('bodyCellStyle = '+ bodyCellStyle);
                        String cellString = '<td style="'+ bodyCellStyle +'">'+ fieldValue +'</td>';
                        tableString += cellString;
                    }
                    tableString += '</tr>';
                }
                tableString += '</tbody></table>';
            }
            con.Gifts_Last_Year__c = tableString;
            System.debug('tableString = '+ tableString);
        }
        return contacts;
        // update contacts;
    }

    public static Map<String, FieldSelectorController.Field> getFields(String objectName, List<String> fieldNames) {
        System.debug('in getFields for '+ objectName +', fieldNames = '+ fieldNames);
        DescribeSObjectResult objectRes = ((SObject)Type.forName('Schema', objectName).newInstance()).getSObjectType().getDescribe();
        System.debug('objectRes = '+ objectRes);
        List<FieldSelectorController.Field> fields = new List<FieldSelectorController.Field>();
        Map<String, FieldSelectorController.Field> fieldNameMap = new Map<String, FieldSelectorController.Field>();
        for (String fieldName : fieldNames) {
            fieldName = fieldName.trim();
            System.debug('looping through '+ fieldName);
            System.debug('objectRes.fields keyset = '+ objectRes.fields.getMap().keySet());
            System.debug('object contains field? '+ objectRes.fields.getMap().containsKey(fieldName));
            Schema.DescribeFieldResult fieldResult = objectRes.fields.getMap().get(fieldName).getDescribe();
            System.debug('fieldResult = '+ fieldResult);
            FieldSelectorController.Field field = new FieldSelectorController.Field(fieldResult.getName(), fieldResult.getLabel(), fieldResult.getType().name());
            fields.add(field);
            System.debug(field);
            fieldNameMap.put(fieldName, field);
            System.debug('added to fieldNameMap');
        }
        System.debug('about to return fieldNameMap: '+ fieldNameMap);
        return fieldNameMap;
    }


    public static List<String> safeSplit(String text, String separator) {
        List<String> returnStrings = new List<String>();
        for (String entry : text.split(separator)) {
            returnStrings.add(entry.trim());
        }
        return returnStrings;
    }
    
    public class Request {
        @InvocableVariable(label='Contact IDs' required=true)
        public List<String> contactIds;

        @InvocableVariable(label='Email Template ID' required=true)
        public String emailTemplateId;

        @InvocableVariable(label='Field Names String' required=true)
        public String fieldNamesString;

        @InvocableVariable(label='List View ID')
        public String listViewId;

        @InvocableVariable(label='Table CSS string')
        public String tableStyle;

        @InvocableVariable(label='Header Cell CSS string')
        public String headerCellStyle;

        @InvocableVariable(label='Body Cell CSS string')
        public String bodyCellStyle;
    }

    public class Result {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Log ID')
        public String logId;

        public Result(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }


    /*
    public static void constructGiftTable(List<Id> contactIds, List<String> opportunityFieldNames) {
        List<OpportunityContactRole> oppConRoles = [SELECT ContactId, OpportunityId FROM OpportunityContactRole WHERE ContactId IN :contactIds];
        // List<FieldSelector.Field> fields = getFields('Opportunity', opportunityFieldNames);
        Map<String, FieldSelectorController.Field> fields = getFields('Opportunity', opportunityFieldNames);
        Map<Id, Set<Id>> contactOppMap = new Map<Id, Set<Id>>();
        List<Id> oppIds = new List<Id>();
        for (OpportunityContactRole ocr : oppConRoles) {
            oppIds.add(ocr.OpportunityId);
            if (contactOppMap.containsKey(ocr.ContactId)) {
                contactOppMap.get(ocr.ContactId).add(ocr.OpportunityId);
            } else {
                contactOppMap.put(ocr.ContactId, new Set<Id>{ocr.OpportunityId});
            }
        }
        String fieldNameString = String.join(opportunityFieldNames, ',');
        System.debug('fieldNameString = '+ fieldNameString);
        System.debug(oppIds);
        System.debug(contactOppMap);
        List<Opportunity> opps = Database.query('SELECT '+ fieldNameString +' FROM Opportunity WHERE Id IN :oppIds');
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);    
        System.debug('found '+ opps);
        System.debug('oppMap '+ oppMap);
        List<Contact> contacts = [SELECT Id, Gifts_Last_Year__c FROM Contact WHERE Id IN :contactIds];
        List<String> tableStrings = new List<String>();
        for (Contact con : contacts) {
            String tableString = '<table style="border:1px solid black"><tr>';
            // for (integer i=0; i<opportunityFieldLabels.size(); i++) {
            //     tableString += '<td style="border:1px solid black>'+ opportunityFieldLabels[i] +'</td>';
            // }
            integer headerColumns = 0;
            for (String fieldName : fields.keySet()) {            
                String cellString = '<th style="border:1px solid black">'+ fields.get(fieldName).label +'</th>';
                System.debug('adding cellString in header: '+ cellString);
                tableString += cellString;
                headerColumns++;
            }
            System.debug('headerColumns = '+ headerColumns);
            tableString += '</tr>';
            System.debug('headerString = '+ tableString);
            

            for (Id oppId : contactOppMap.get(con.Id)) {
                integer dataColumns = 0;
                Opportunity opp = oppMap.get(oppId);
                tableString += '<tr>';
                for (String fieldName : fields.keySet()) {
                    dataColumns++;
                    Object fieldValue = opp.get(fieldName);
                    if (fieldValue instanceof Date) {
                        fieldValue = ((Date)fieldValue).format();
                    }
                    else if (fieldValue instanceof Decimal) {//if (fields.get(fieldName).type.toLowerCase() == 'currency') {
                        fieldValue = ((Decimal)fieldValue).format();
                        if (fields.get(fieldName).type.toLowerCase() == 'currency') {
                            fieldValue = '$' + fieldValue;
                        }
                    } 
                    String cellString = '<td style="border:1px solid black">'+ fieldValue +'</td>';
                    System.debug('cellString in data row: '+ cellString);
                    tableString += cellString;
                }
                System.debug('dataColumns = '+ dataColumns);
                tableString += '</tr>';
            }
            tableString += '</table>';
            System.debug('contact ID '+ con.Id +' tableString = '+ tableString);
            con.Gifts_Last_Year__c = tableString;
        }
        update contacts;
        List<Contact> newContacts = [SELECT Id, Gifts_Last_Year__c FROM Contact WHERE Id IN: contactIds];
        for (Contact newContact : newContacts) {
            System.debug('newContact gifts table = '+ newContact.Gifts_Last_Year__c);
        }
    }
    */

/*
    public static void basicAuthCallout(String objectName, String listViewId, String emailTemplateId){
        if (objectName == null) objectName = 'Contact';
        if (listViewId == null) listViewId = '00B7j000001JL35EAG';
        if (emailTemplateId == null) emailTemplateId = '00X4C000000RX75UAG';

        if (true) {
            System.debug('Calling getIdsFromListView...');
            System.debug(getIdsFromListView(objectName, listViewId));
            return;
        }
        HttpRequest req = new HttpRequest();        
        req.setMethod('GET');        
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+ '/services/data/v50.0/sobjects/'+ objectName +'/listviews/'+ listViewId +'/results');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        Map<String, Object> resultMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

        // for (String resultKey : resultMap.keySet()) {
        //     System.debug('key: '+ resultKey +' - '+ resultMap.get(resultKey));
        // }
        // System.debug(resultMap.get('columns'));
        // System.debug(resultMap.get('columns') instanceof string);
        // System.debug(resultMap.get('developerName'));
        // System.debug(resultMap.get('developerName') instanceof string);
        // System.debug(resultMap.get('records'));

        // I have no idea how this works but it does, I'm not going to touch it
        List<ListViewRecord> records = (List<ListViewRecord>) JSON.deserialize(JSON.serialize(resultMap.get('records')), List<ListViewRecord>.class);

        Set<String> emails = new Set<String>();
        Set<Id> targetIds = new Set<Id>();
        for (ListViewRecord contact : records) {
            // String foundValue;
            for (ListViewRecordColumn col : contact.columns) {
                if (col.fieldNameOrPath == 'Id') {
                    targetIds.add(col.value);
                    // foundValue = col.value;
                    break;
                }
            }            
            // if (foundValue != null) {
            //     emails.add(foundValue);
            // }
        }
        System.debug(records);
        // System.debug('Found '+ emails.size() +' emails, including: '+ emails);
        System.debug('Found '+ targetIds.size() +' targetIds, including: '+ targetIds);

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Id targetId : targetIds) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTargetObjectId(targetId);
            msg.setTemplateId(emailTemplateId);
            messages.add(msg);
        }

        System.debug('Found '+ messages.size() +' messages, including: '+ messages);
    }
*/
   
    /*
    public class Result {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Log ID')
        public String logId;

        public Result(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }
    */

/*
    // @InvocableMethod(callout=true)
    public static List<Result> sendYearEndTaxEmail(List<Request> reqs) {
        System.debug('in sendYearEndTaxEmail, reqs.size = '+ reqs.size());
        Request req = reqs[0];
        Result res;
        Mass_Email_Log__c newLog = new Mass_Email_Log__c();
        System.debug(req);

        List<String> errors = validateRequest(req);
        if (errors.size() > 0) {
            //return new List<Result>();
            res = new Result('error', 'Error 1 of '+ errors.size() +': '+ errors[0]);
        } else {
            System.debug('No errors found in request');

            // Replacing the following line with a block that creates dummy data if running in a test context
            // List<Id> contactIds = getIdsFromListView('Contact', req.listViewId);
            List<Id> contactIds;
            if (Test.isRunningTest()) {
                System.debug('IS RUNNING TEST');
                // Need to create a dummy contact and get Id
                Contact testContact = new Contact(FirstName='Dummy', LastName='Contact');
                insert testContact;
                contactIds = new List<Id>{testContact.Id};
            } else {
                System.debug('IS NOT RUNNING TEST');
                contactIds = getIdsFromListView('Contact', req.listViewId);
            }
            
            if (contactIds.size() == 0) {
                res = new Result('error', 'There was an error getting the contacts from list view '+ req.listViewId);
            } else {
                System.debug('contactIds has '+ contactIds.size() +' elements, including: '+ contactIds);

                System.debug('about to construct gift table at '+ Datetime.now());
                System.debug('req.fieldNamesString = '+ req.fieldNamesString);
                constructGiftTable(contactIds, safeSplit(req.fieldNamesString, ','));
                System.debug('contact tables successfully updated!');

                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
                for (Id contactId : contactIds) {
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                    msg.setTargetObjectId(contactId);
                    msg.setTemplateId(req.emailTemplateId);
                    messages.add(msg);
                }
                System.debug('Found '+ messages.size() +' messages, including: '+ messages);
                try {
                    Messaging.sendEmail(messages);
                    res = new Result(success, 'You have successfully sent '+ messages.size() +' messages');
                    
                    // Create log
                    String emailTemplateName = [SELECT Name FROM EmailTemplate WHERE Id =: req.emailTemplateId].Name;
                    String massEmailLogName = emailTemplateName +' - '+ Datetime.now();
                    // Mass_Email_Log__c newLog = new Mass_Email_Log__c(Name = massEmailLogName, Email_Template_ID__c = req.emailTemplateId);
                    newLog.Name = massEmailLogName;
                    newLog.Email_Template_ID__c = req.emailTemplateId;
                    List<Mass_Email_Log_Item__c> logItems = new List<Mass_Email_Log_Item__c>();
                    insert newLog;                
                    for (Messaging.SingleEmailMessage message : messages) {
                        Mass_Email_Log_Item__c newItem = new Mass_Email_Log_Item__c();
                        newItem.Mass_Email_Log__c = newLog.Id;
                        newItem.Contact__c = message.getTargetObjectId();
                        newItem.Email__c = [SELECT Email FROM Contact WHERE Id =: newItem.Contact__c].Email;
                        newItem.Status__c = success;
                        newItem.Email_Content__c = message.getHtmlBody();
                        logItems.add(newItem);
                    }
                    insert logItems;
                    res.logId = newLog.Id;
    
                } catch(Exception e) {
                    res = new Result(error, 'There was an error sending the emails: '+ e.getMessage());
                }
                
                //logItems.add(new Mass_Email_Log_Item__c())

            }
        }
        return new List<Result>{res};
    }
    // Overloading the method to allow calling it with 3 separate parameters instead of a single Request object
    public static List<Result> sendYearEndTaxEmail(String listViewId, String emailTemplateId, String fieldNamesString) {
        Request req = new Request(listViewId, emailTemplateId, fieldNamesString);
        Result res;
        List<String> errors = validateRequest(req); // Validate input
        List<Id> contactIds = getIdsFromListView('Contact', req.listViewId);
        return sendYearEndTaxEmail(new List<Request>{req});
    }

    public static List<String> validateRequest(Request req) {

        boolean isValid = true;
        List<String> errorMessages = new List<String>();
        try {
            ListView lv = [SELECT Id FROM ListView WHERE Id = :req.listViewId];
            try {
                List<Id> contactIds = getIdsFromListView('Contact', req.listViewId);
                if (contactIds.size() == 0) {
                    errorMessages.add('No Contacts found in List View '+ req.listViewId);
                }
            } catch (Exception e) {
                errorMessages.add('Error calling getIdsFromListView on List View: '+ req.listViewId +': '+ e.getMessage());
            }    
        } catch (Exception e) {
            errorMessages.add('Invalid List View ID provided: '+req.listViewId+'1. Please enter the ID of the Contact List View that contains the donors you want to email.');
        }

        try {
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Id = :req.emailTemplateId];
        } catch (Exception e) {
            errorMessages.add('Invalid Email Template ID provided: '+ req.emailTemplateId +'. Please enter the ID of the Email Template you want to send out to your donors.');
        }


        return errorMessages;
    }

    public static List<Id> getIdsFromListView(String objectName, String listViewId) {
        System.debug('in getIdsFromListView. objectName = '+ objectName +', listViewId = '+ listViewId);
        // Construct and send API request for list view results data
        HttpRequest req = new HttpRequest();        
        req.setMethod('GET');        
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        System.debug('request header set');
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+ '/services/data/v50.0/sobjects/'+ objectName +'/listviews/'+ listViewId +'/results');
        System.debug('request endpoint set');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('result received');

        if (res.getStatusCode() != 200) {
            System.debug('Error in API call: '+ res.getBody());
            return new List<Id>();
        }
        System.debug('API call was a success');

        // Parse the JSON response into a list of records each consisting of a list of columns. Each column consists of the field name and the value of that field for that record
        Map<String, Object> resultMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        List<ListViewRecord> records = (List<ListViewRecord>) JSON.deserialize(JSON.serialize(resultMap.get('records')), List<ListViewRecord>.class);

        // Loop through the records and add the value of the ID column for each record to a list
        List<Id> ids = new List<Id>();
        for (ListViewRecord contact : records) {
            for (ListViewRecordColumn col : contact.columns) {
                if (col.fieldNameOrPath == 'Id') {
                    ids.add(col.value);
                    break;
                }
            }            
        }        
        return ids;
    }

    public class ListViewRecord {
        public List<ListViewRecordColumn> columns;
    }

    public class ListViewRecordColumn {
        public String fieldNameOrPath;
        public String value;
    }

    // Controller for the VF page
    public PageReference vfController() {
        String listViewId = ApexPages.currentPage().getParameters().get('listViewId');
        String emailTemplateId = ApexPages.currentPage().getParameters().get('emailTemplateId');
        String fieldNamesString = ApexPages.currentPage().getParameters().get('fieldNamesString');
                
        Request req = new Request(listViewId, emailTemplateId, fieldNamesString);
        Result res;        
        List<Id> contactIds;
        // Result res = sendYearEndTaxEmail(new List<Request>{req})[0];
        try {
            contactIds = YearEndTaxEmailController.getIdsFromListView('Contact', req.listViewId);
            if (contactIds.size() == 0) {
                res = new Result(error, 'Contact List View ['+ req.listViewId +'] does not contain any Contacts');
            } else {
                try {
                    // constructGiftTable(contactIds, req.fieldNamesString.split(','));
                    constructGiftTable(contactIds, safeSplit(req.fieldNamesString, ','));
                    try {
                        // List<Messaging.SingleEmailMessage> messages = YearEndTaxEmailController.sendEmailTemplateToContacts(req.emailTemplateId, contactIds);
                        YearEndTaxEmailController.sendEmailTemplateToContacts(req.emailTemplateId, contactIds);
                        res = new Result(success, 'You have successfully sent '+ contactIds.size() +' messages');
                    } catch (Exception e) {
                        new Result(error, 'There was an error sending out the emails: '+ e.getMessage());
                    }
                } catch (Exception e) {
                    res = new Result(error, 'Error constructing Contact gift table with field names "'+ req.fieldNamesString +'": '+ e.getMessage());
                }
            }
        } catch (Exception e) {
            res = new Result(error, 'Error getting Contact List View ['+ req.listViewId +']: '+ e.getMessage());
        }
        // List<Messaging.SingleEmailMessage> msgs = YearEndTaxEmailController.sendEmailTemplateToContacts(req.emailTemplateId, contactIds);
        // for (Messaging.SingleEmailMessage msg : msgs) {
        //     System.debug('msg = '+ msg);
        // }

        return new PageReference('/flow/'+ resultFlowName +'?status='+ res.status +'&message='+ res.message);        
    }    
    */    

    
      /** https://github.com/chrisludovice/SFDX_NestedJsonParser/blob/brainstorm/Json2ApexNestedJsonMethod */
    //   public static void parse(String payload){
        
    //     // using JSON.deserializeUntyped to deserialize nested json payload        
    //     Map<String, Object> mainNode;
    //     List<Object> firtInstance;
    //     mainNode = (Map<String, Object>)JSON.deserializeUntyped(payload); 
    //     if(mainNode!=null)
    //     	firtInstance = (List< Object>)mainNode.get('data'); 
    //     else mainNode = new Map<String, Object>();
        
    //     for(integer x=0;x<firtInstance.size();x++){
            
    //         Map<String, Object> d1 =  (Map<String, Object>)firtInstance[x];           
            
    //         // print first level of json - > data
    //         system.debug('keyId'+x+': '+d1.get('keyId'));
    //         system.debug('referralCode'+x+': '+d1.get('referralCode'));
    //         system.debug('push'+x+': '+d1.get('push'));
    //         system.debug('createdAt'+x+': '+d1.get('createdAt'));
    //         system.debug('updatedAt'+x+': '+d1.get('updatedAt')); 
            
    //         // print second level of json - > metadata
    //         Map<String, Object> d2 = (Map<String, Object>)d1.get('metadata');            
    //         if(d2!=null){
    //             system.debug('name:'+d2.get('name'));
    //             system.debug('date:'+d2.get('date'));
                
    //             // print 3rd level of json - > v_status
    //             if(d2.get('v_status')!=null){
    //                 Map<String, Object> d3 =  (Map<String, Object>)d2.get('v_status'); 
    //         		if(d3!=null)
    //             	system.debug('revert:'+d3.get('revert'));
    //             }
    //         }
    //       }           

    // }    
  }