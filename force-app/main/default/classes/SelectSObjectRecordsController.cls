/**
* @description Apex class used to select sobject records
**/
public with sharing class SelectSObjectRecordsController{
	
	@testVisible
	private static final String BUSINESS_UNIT_ICON_DEVELOPER_NAME = 'Business_Unit_Icon';
	

	/**
	* @description Method to get the list of objects 
	* @return Map<String, Object> Map contains list of objects and transient message field label
	**/
	@AuraEnabled
	public static List<Object> getsObjectInfo(){
		List<Object> sObjectsList = new List<Object>();

		//Check user has sufficient access to Query Document Data
		Boolean queryAccessDocument = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										Document.sObjectType.getDescribe().getName(), 
										new Set<String>{Document.DeveloperName.getDescribe().getName()}, 
										XLC.SchemaHelper.DatabaseAction.QUERY_DATA
									);

		//Throw exception if the user doesn't have sufficient access
		if(!queryAccessDocument){
			throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
		}

		Document document = SelectSObjectRecordsHelper.getDocumentByDeveloperName(BUSINESS_UNIT_ICON_DEVELOPER_NAME);
		sObjectsList.add(new Map<String, String>{'name' => User.sObjectType.getDescribe().getName().toLowerCase(),'label' => User.sObjectType.getDescribe().getLabelPlural(),'icon' => 'standard:user','srcUrlField' => 'FullPhotoUrl'});
		if(SelectSObjectRecordsHelper.isSharingGroupFieldAvailable()) {
			sObjectsList.add(new Map<String, String>{'name' => grc__Business_Unit__c.sObjectType.getDescribe().getName().toLowerCase(),'label' => grc__Business_Unit__c.sObjectType.getDescribe().getLabelPlural(),'srcUrl'=>'/servlet/servlet.FileDownload?file='+(document != null && document.Id != null ? document.Id : '')});
		}
		sObjectsList.add(new Map<String, String>{'name' => Group.sObjectType.getDescribe().getName().toLowerCase(),'label' => Group.sObjectType.getDescribe().getLabelPlural(),'icon' => 'standard:groups'});
		sObjectsList.add(new Map<String, String>{'name' => UserRole.sObjectType.getDescribe().getName().toLowerCase(),'label' => UserRole.sObjectType.getDescribe().getLabelPlural(),'icon' => 'standard:hierarchy'});
		return sObjectsList;
	}
}
