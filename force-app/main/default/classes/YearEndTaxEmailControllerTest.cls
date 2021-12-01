@isTest
public class YearEndTaxEmailControllerTest {

    // public HTTPResponse respond(HTTPRequest req) {
    //     // Optionally, only send a mock response for a specific endpoint
    //     // and method.
    //     System.assertEquals('http://example.com/example/test', req.getEndpoint());
    //     System.assertEquals('GET', req.getMethod());
        
    //     // Create a fake response
    //     HttpResponse res = new HttpResponse();
    //     res.setHeader('Content-Type', 'application/json');
    //     res.setBody('{"example":"test"}');
    //     res.setStatusCode(200);
    //     return res;
    // }

    public static String demoEmail = 'fromsteinyearendtax@gmail.com';
    public List<Contact> contacts = new List<Contact>();

    
    @isTest(seeAllData=true)
    public static void testv3() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Test.startTest();        
            // Account testAccount = new Account(Name='Test');
            // insert testAccount;
            List<Id> contactIds = new List<Id>();
            List<Contact> newContacts = createContacts(10);
            insert newContacts;
            List<Opportunity> newOppties = new List<Opportunity>();
            for (Contact con : newContacts) {
                Integer ran = Integer.valueOf(Math.random()*50);
                contactIds.add(con.Id);
                newOppties.addAll(createOpportunitiesForContact(con, ran));
            }
            System.debug(newOppties.size() + ' new opportunities');
            insert newOppties;        
            // Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id FROM Contact WHERE npo02__OppAmountLastYear__c > 0 LIMIT 10]);

            // System.debug('contactMap contains '+ contactMap.keySet().size());
            Folder testFolder = [SELECT Id FROM Folder WHERE Type='EmailTemplate' OR Type='Email'];
            EmailTemplate template = new EmailTemplate(Name='Test Email Template', DeveloperName='YETETestEmailTemplate', FolderId=testFolder.Id, Body='Test body.', TemplateType='text');
            insert template;

            YearEndTaxEmailController.Request req = new YearEndTaxEmailController.Request();
            req.emailTemplateId = template.Id;
            req.contactIds = contactIds;
            // req.contactIds = new List<Id>(contactMap.keySet());
            req.fieldNamesString = 'CloseDate,Amount';
            YearEndTaxEmailController.sendEmail(new List<YearEndTaxEmailController.Request>{req});
            Test.stopTest();        
        }
    }


    public static List<Contact> createContacts(Integer numContacts) {
        Account acc = new Account(Name=accountName);
        insert acc;
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<Contact> contacts = new List<Contact>();
        List<String> firstNames = 'David,Marsha,Kendra,Shirley,Emma,Angela,Luis,Powell,Carmine,Jason,Pei,Skylar,Grace,Colleen,Bodhi,Tonya,Tracey'.split(',');
        List<String> lastNames = 'O\'Malley,Goldman,Budane,Crawford,Martinez,Romanov,Chang,Kim,Hlywa,Tragas,Marshburn,Favreau,Lemongrass,Bonheur,Temperate'.split(',');
        String email = 'fromsteinyearendtax@gmail.com';
        for (integer i=0; i<numContacts; i++) {
            String firstName = (String)getRandomElement(firstNames);
            String lastName = (String)getRandomElement(lastNames);
            contacts.add(new Contact(FirstName=firstName, LastName=lastName, Email=demoEmail));
            // System.debug(contacts[contacts.size()-1]);
        }        
        return contacts;

    }

    public static List<Opportunity> createOpportunitiesForContact(Contact contact, Integer numOpportunities) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i=0; i<numOpportunities; i++) {
            Integer ranNumDays = Integer.valueOf(Math.random()*365);
            Date ranDate = Date.newInstance(Date.today().year()-1, 1, 1).addDays(ranNumDays);
            Opportunity newOpp = new Opportunity(Name=contact.Name+' '+i, AccountId = contact.accountId, npsp__Primary_Contact__c = contact.Id, Amount = 1 + Math.random()*500, CloseDate = ranDate, StageName='Closed Won');
            opps.add(newOpp);
        }

        return opps;
    }

    public static Object getRandomElement(List<Object> objList) {
        Integer size = objList.size();
        Integer ran = Integer.valueOf(Math.random() * size);
        return objList[ran];
    }

}
