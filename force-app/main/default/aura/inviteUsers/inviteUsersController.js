({
    /**
    * @description : Method to be called during component initialisation
    **/
    doInit: function(component,event,helper){
        helper.fetchTrainingInfo(component);
    },

    /**
    * @description : Method to save participants for the training
    **/
    addParticipants: function(component,event,helper){
        helper.saveParticipants(component,event,helper);
    },
    /**
	* @description Method to remove the notified user from the exclude ids
	*/
	handleRemoveParticipantEvent : function(component,event,helper){
		helper.removeParticipantFromExlcudeIds(component,event);
	},
    
})