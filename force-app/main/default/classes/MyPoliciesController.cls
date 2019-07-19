/**
* @description Apex class to fetch the read and unread policies, files related to a given policy, 
*              set the distributed user record to true and get the list view id for a given list
*              view name.
**/
public with sharing class MyPoliciesController {
    
    /**
    * @description Method to get list of Unread policies
    * @return Map<String, Object> Map contains policy data and policy object field label
    * @TODO ONE TO DISCUSS - 3 Queries, could this be improved?
    **/
    @AuraEnabled 
    public static Map<String, Object> getMyPolicies(){
        Map<String,Object> policiesMap = new Map<String,Object>();

        //Check user has sufficient access to Query Policy, Policy Version and Policy Notification Data
        Boolean queryAccessPolicy =  grc__Policy__c.sObjectType.getDescribe().isAccessible();
        
        Boolean queryAccessPolicyVersion = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                                Policy_Version__c.sObjectType.getDescribe().getName(),
                                                new Set<String>{    Policy_Version__c.XLComp__Policy__c.getDescribe().getName(),
                                                                    'CreatedDate'
                                                                }, 
                                                XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                            );
        Boolean queryAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                                    Policy_Notification__c.sObjectType.getDescribe().getName(), 
                                                    new Set<String>{    Policy_Notification__c.XLComp__Policy_Version__c.getDescribe().getName(),
                                                                        Policy_Notification__c.XLComp__Policy_Read__c.getDescribe().getName(),
                                                                        Policy_Notification__c.OwnerId.getDescribe().getName(),
                                                                        Policy_Notification__c.XLComp__Date_Policy_Read__c.getDescribe().getName(),
                                                                        'CreatedDate'
                                                                    }, 
                                                    XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                                );
        
        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessPolicy || !queryAccessPolicyVersion || !queryAccessPolicyNotification){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }


        policiesMap.putAll((Map<String, Object>)getPoliciesByUserReadStatus());
        policiesMap.put('fieldlabel',grc__Policy__c.Name.getDescribe().getLabel());   
        return policiesMap;
    }

    /**
    * @description Method to get Map of policies by user read status
    * @return Map<String, List<Policy_Notification__c>> Map of Unread/Read mode by list of policy distributions
    **/
    private static Map<String, List<Policy_Notification__c>> getPoliciesByUserReadStatus(){
        Map<String, List<Policy_Notification__c>> policiesByUserReadStatusMap = new Map<String, List<Policy_Notification__c>>{
            'Read' => new List<Policy_Notification__c>(),
            'Unread' => new List<Policy_Notification__c>()
        };

        //get all the latest policies related to current user.
        //@TODO Look to improve this, it calls a query in a query (getLastestPolicyVersions)
        List<Policy_Notification__c> policyNotifiedUsers = [SELECT Policy_Version__c, Policy_Version__r.Policy__r.Name, Policy_Version__r.Policy__c, Policy_Read__c 
            FROM Policy_Notification__c WHERE OwnerId =: UserInfo.getUserId() AND Policy_Version__c IN: getLastestPolicyVersions()
            ORDER BY Date_Policy_Read__c DESC,CreatedDate ASC LIMIT 50000];
        
        for(Policy_Notification__c notifiedUser : policyNotifiedUsers){
            if(notifiedUser.Policy_Read__c){
                policiesByUserReadStatusMap.get('Read').add(notifiedUser);
            }else {
                policiesByUserReadStatusMap.get('Unread').add(notifiedUser);
            }
            
        }
        return policiesByUserReadStatusMap;
    }

    /**
    * @description Method to get lastet policy version ids
    * @return Set<Id> lastet policy version ids for each policy
    **/
    private static Set<Id> getLastestPolicyVersions(){
        Set<Id> policyVersionsIds = new Set<Id>();
        for(grc__Policy__c policy : [SELECT Id, (SELECT Id FROM Policy_Versions__r ORDER BY CreatedDate DESC LIMIT 1) FROM grc__Policy__c LIMIT 50000]){
            if(!policy.Policy_Versions__r.isEmpty()) policyVersionsIds.add(policy.Policy_Versions__r[0].Id);
        }
        return policyVersionsIds;
    }

    /**
    * @description Method to get list of policy documents for a policy
    * @param recordId Id of the policy record to get its associated files
    * @return Map<String, Object> Map contains policy content document ids and name of the current policy
    **/
    @AuraEnabled 
    public static Map<String, Object> getDocuments(Id recordId){
        Map<String,Object> policyDocumentsMap = new Map<String,Object>();
        
        //Check user has sufficient access to Query Policy Data
        Boolean queryAccessPolicy = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                        grc__Policy__c.sObjectType.getDescribe().getName(), 
                                        new Set<String>{grc__Policy__c.XLComp__Content_Document_Id__c.getDescribe().getName()}, 
                                        XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                    );
        
        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessPolicy){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }
        
        //Query Policy
        List<grc__policy__c> policiesList = [SELECT Id, Name, Content_Document_Id__c FROM grc__Policy__c WHERE Id =: recordId LIMIT 1];
        if(!policiesList.isEmpty()){
            policyDocumentsMap.put('policyname',policiesList[0].Name);
            policyDocumentsMap.put('documentIds',!String.isBlank(policiesList[0].Content_Document_Id__c) ? new Set<Id>{policiesList[0].Content_Document_Id__c} : new Set<Id>{});
        }
        return policyDocumentsMap;
    }

    /**
    * @description Method to set the read attribute equals for a given notified user record.
    * @param recordId Id of the policy notification record
    **/
    @AuraEnabled 
    public static void setPolicyRead(Id recordId){

        //Check user has sufficient access to Query Policy Notification Data
        Boolean queryAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                                    Policy_Notification__c.sObjectType.getDescribe().getName(), 
                                                    new Set<String>{    Policy_Notification__c.XLComp__Policy_Read__c.getDescribe().getName(),
                                                                        Policy_Notification__c.XLComp__Date_Policy_Read__c.getDescribe().getName()
                                                                    }, 
                                                    XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                                );
        //Check user has sufficient access to Update Policy Notification Data
        Boolean updateAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                                    Policy_Notification__c.sObjectType.getDescribe().getName(),
                                                    new Set<String>{    Policy_Notification__c.XLComp__Policy_Read__c.getDescribe().getName(),
                                                                        Policy_Notification__c.XLComp__Date_Policy_Read__c.getDescribe().getName()
                                                                    }, 
                                                    XLC.SchemaHelper.DatabaseAction.UPDATE_DATA
                                                );

        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessPolicyNotification || !updateAccessPolicyNotification){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }
        

        //Query Policy Notifications
        List<Policy_Notification__c> policyNotificationList = [SELECT Id, Policy_Read__c, Date_Policy_Read__c FROM Policy_Notification__c WHERE Id =: recordId LIMIT 1];
        
        //Change Policy Notification values
        for(Policy_Notification__c notifiedUser : policyNotificationList){
            notifiedUser.Policy_Read__c = true;
            notifiedUser.Date_Policy_Read__c = System.today();
        }

        //Update Policy Notifications
        try{
            update policyNotificationList;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * @description Method to get the list view Id for a given list view name from the policy distribution user
    * @param listViewName Name of the list view to redirect the user to.
    * @return Map<String, Object> Map contains given list view id and policy distribution sobject name.
    **/
    @AuraEnabled 
    public static Map<String, Object> getListView(String listViewName){
        Map<String, Object> objectsMap = new Map<String, Object>();
        
        //Query List view
        List<ListView> listViewsList = [SELECT Id FROM ListView WHERE DeveloperName =: listViewName AND SobjectType =: Policy_Notification__c.sObjectType.getDescribe().getName() LIMIT 1];
        
        if(!listViewsList.isEmpty()){
            objectsMap.put('listviewid',listViewsList[0].Id);
            objectsMap.put('sobjectname',Policy_Notification__c.sObjectType.getDescribe().getName());
        }
        
        return objectsMap;
    }
}
