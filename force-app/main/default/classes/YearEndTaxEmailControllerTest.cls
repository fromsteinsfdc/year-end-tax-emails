@isTest
public class YearEndTaxEmailControllerTest {

    public static String demoEmail = 'fromsteinyearendtax@gmail.com';

    @isTest
    public static void testYearEndTaxEmail() {
        System.debug('in yearEndTaxEmail');
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Test.startTest();        
            List<Contact> contacts = new List<Contact>();
            List<Opportunity> opps = new List<Opportunity>();
            List<Id> contactIds = new List<Id>();
            integer numContacts = 10;
            integer numOppties = 10;
            for (integer i=0; i<numContacts; i++) {
                Contact con = new Contact(FirstName='Test', LastName='Contact'+i, Email=demoEmail);
                System.debug('Contact = '+ con);
                contacts.add(con);

            }
            insert contacts;
            for (Contact con : contacts) {
                contactIds.add(con.Id);
                for (integer i=0; i<numOppties; i++) {
                    Date closeDate = Date.today().addYears(-1).addDays(-i);
                    String oppName = con.FirstName +' '+ con.LastName +' donation '+ i;
                    Opportunity opp = new Opportunity(Name = oppName, npsp__Primary_Contact__c = con.Id, CloseDate = closeDate, Amount = 200, StageName = 'Closed Won');                    
                    System.debug('opportunity = '+ opp);
                    opps.add(opp);
                }
            }
            insert opps;

            // List<Contact> contacts = createContacts(1);
            // System.debug('created '+ contacts.size() +' dummy contacts');
            // insert contacts;
            // List<Opportunity> opps = new List<Opportunity>();
            // for (Contact c : contacts) {
            //     contactIds.add(c.Id);
            //     opps.addAll(createOpportunitiesForContact(c, 1));
            // }
            // insert opps;
            // System.debug('created '+ opps.size() +' dummy opps');

            // Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id FROM Contact WHERE npo02__OppAmountLastYear__c > 0 LIMIT 10]);

            // System.debug('contactMap contains '+ contactMap.keySet().size());
            // Folder testFolder = [SELECT Id FROM Folder WHERE Type='EmailTemplate' OR Type='Email'];
            EmailTemplate template = new EmailTemplate(Name='Test Email Template', DeveloperName='YETETestEmailTemplate', FolderId=UserInfo.getUserId(), Body='Test body.', TemplateType='text');
            insert template;
            System.debug('email template successfully created, '+ template.Id);

            YearEndTaxEmailController.Request req = new YearEndTaxEmailController.Request();
            req.emailTemplateId = template.Id;
            req.contactIds = contactIds;
            // req.contactIds = new List<Id>(contactMap.keySet());
            req.fieldNamesString = 'CloseDate,Amount';
            System.debug('req = '+ req);
            YearEndTaxEmailController.sendEmail(new List<YearEndTaxEmailController.Request>{req});
            Test.stopTest();
        }
    }


    public static List<Contact> createContacts(Integer numContacts) {
        Account acc = new Account(Name='Test Account');
        insert acc;

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
