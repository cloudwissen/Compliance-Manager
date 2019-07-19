({
	/**
	* @description Method to be called during component initalisation
	*/
	doInit : function(component,event,helper){
		helper.getsObjectInformation(component,event,helper);
	},
	/**
	* @description Method used to handle on records list change
	*/
	handleRecordsListChange : function(component,event,helper){
		helper.setExcludeIds(component,event);
	},
	/**
	* @description Method used to handle sobject change
	*/
	handlesObjectChange : function(component,event,helper){
		helper.setExcludeIds(component);
		helper.setCurrentsObjectInfo(component);
	},
	/**
	* @description Method used to add selected records into the records map
	*/
	addSelectedRecords : function(component,event,helper){
		helper.addSelectedRecords(component);
	},
	/**
	* @description Method to handle the action event
	*/
	handleActionEvent : function(component,event,helper){
		helper.removeItem(component,event);
		helper.removeIdFromExcludeIds(component,event);
	},
})