({
	/**
	* @description Method to be called during component initalisation to users for a training course
	**/
	fetchsObjectRecords : function(component,event,helper){
		helper.fetchsObjectRecords(component,event);
	},

	/**
	* @description Method to set the selected ids
	**/
	handleOnRowSelection : function(component,event,helper){
		helper.updateSelectedIds(component,event);
	},

	/**
	* @description Method to handle the filter event
	**/
	handleFilterEvent : function(component,event,helper){
		helper.search(component,event);
	},

	/**
	* @description Method to save users for the trainings
	**/
	setAttendanceOnEvents : function(component,event,helper){
		helper.markAttendance(component,event,helper);
	},

	/**
	* @description Method to sort the table data 
	**/
	updateColumnSorting : function(component,event,helper){
		helper.sortData(component,event);
	}
})
