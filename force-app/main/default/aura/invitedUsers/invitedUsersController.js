({
    /**
    * @description Method to be called during component initalisation to fetch invited users for a training course
    */
    doinit: function(component,event,helper){
        helper.fetchsObjectRecords(component,event,helper);
        var action = {'label':$A.get("$Label.c.Delete"),'name':'delete','iconName':'utility:close'};
        component.set("v._actions", [action]);
        var sObjectInfo = {'label': 'User', 'srcUrl' : 'broken', 'srcUrlField' : 'FullPhotoUrl', 'icon' : 'standard:user'};
       	component.set("v._sObjectInfo", sObjectInfo);
    },

    /**
    * @description Method to be called during any change on the invite users
    */
    fetchInvitedUsers: function(component,event,helper){
        helper.fetchsObjectRecords(component,event,helper);
    },

    /**
    * @description Method to be called when the recordAction event from the recordTileList Component is fired
    */
    recordAction: function(component,event,helper){
        helper.recordAction(component,event,helper);
    }
})