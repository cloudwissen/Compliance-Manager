@isTest(seeAllData=false)
private with sharing class SelectSObjectRecordsControllerTest {
	
	/**
	*	@description : Test getsObjectsList method
	**/
	@isTest
	static void test_getsObjectInfo(){
		Test.startTest();
		// create documents 
		List<Document> documentsList = new List<Document>{new Document(Name='Test Document - 1',DeveloperName=SelectSObjectRecordsController.BUSINESS_UNIT_ICON_DEVELOPER_NAME,Body=Blob.valueOf('Some Text'),ContentType='application/pdf',FolderId=UserInfo.getUserId())};
		insert documentsList;
		List<Object> objectsList = SelectSObjectRecordsController.getsObjectInfo();
		if(SelectSObjectRecordsHelper.isSharingGroupFieldAvailable()){
			System.assertEquals(4,objectsList.size(), 'If sharing group field is available the objectinfo map for the business unit will be added so 4 object infos will be returned');
		}else {
			System.assertEquals(3,objectsList.size(), 'If sharing group field is not available the objectinfo map for the business unit will not be added so 3 object infos will be returned');
		}
		
		Test.stopTest();
	}
}