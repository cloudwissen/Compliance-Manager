({
    /**
    * @description Method to be called during component initalisation
    */
    doInit: function(component,event,helper){
        helper.getPolicies(component,event,helper);
    },
    
    /**
    * @description Method invoked when changing the Read/Unread mode
    */
    handleMenuSelect: function(component,event,helper){
        var selectedMenuItemValue = event.getParam("value")
        if(selectedMenuItemValue){
            component.set("v.mode",selectedMenuItemValue);
            helper.updateSelectedList(component,event);
        }
    },
    
    /**
    * @description Method invoked when a file icon is clicked on the policy
    */
    openFile: function(component,event,helper){
        helper.openPolicyDocuments(component,event,helper);
    },
    
    /**
    * @description Method invoked when a tick icon is clicked on the policy
    */
    getConfirmation: function(component,event,helper){
       helper.showConfirmationModal(component,event);
    },

    /**
    * @description Method invoked when a confirm button is clicked on the modal
    */
    handleConfirmation: function(component,event,helper){
        helper.handleConfirmation(component,event,helper);
    },

    /**
    * @description Method invoked when a cancel button is clicked on the modal
    */
    handleCloseModal : function(component,event,helper){
        helper.closeModal(component);
    },

    /**
    * @description Method invoked when a view all link is clicked on the modal
    */
    handleViewAll: function(component,event,helper){
        helper.navigateToList(component,event);
    }
})
