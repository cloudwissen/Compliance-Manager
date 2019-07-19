({
	/**
	* @description Method to be called during component initalisation
	**/
	fetchPolicyInfo : function(component,event,helper){
		helper.fetchPolicyInfo(component);
	},
	
	/**
	* @description Method used to distribute policy to users
	**/
	sendPolicy : function(component,event,helper){
		helper.distributePolicy(component,event,helper);
	},
	
	/**
	* @description Method draw the modal in the component to get the message from the user
	**/
	handleShowModal : function(component,event,helper){
		helper.showModal(component,event);
	},
	
	/**
	* @description Method to remove the notified user from the exclude ids
	**/
	handleRemoveNotifiedUserEvent : function(component,event,helper){
		helper.removeNotifiedUserFromExlcudeIds(component,event);
	},
})
