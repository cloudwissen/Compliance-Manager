({
	 /**
	* @description Helper method to get the records list from the map
    * @param component - The component to which the controller belongs. 
	**/
	getRecords : function(component){
		var recordsMap = component.get("v.recordsMap");
		if(!$A.util.isEmpty(recordsMap)){	
			var sObjectInfo = component.get("v.sObjectInfo");
			if(recordsMap.hasOwnProperty(sObjectInfo.name)){
				component.set("v._recordsList",recordsMap[sObjectInfo.name]);
			}
		}
	},
})