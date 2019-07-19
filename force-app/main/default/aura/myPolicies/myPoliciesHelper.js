({
    /**
    * @description Helper method which takes in action and creates promise around it
    * @param      action - action for which callback is set and promise is created around.
    **/
    promiseServerSideCall: function(action) {
        return new Promise(function(resolve, reject) {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject(Error(errors[0].message));
                        }
                    } else {
                        reject(Error($A.get("$Label.XLC.Unknown_Error")));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },

    /**
    * @description Helper method to get the list of policies from the controller
    * @param component - The component to which the controller belongs. 
    * @param event - The event to which the controller belongs. 
    * @param helper — The component’s helper
    **/
    getPolicies: function(component,event,helper){
        $A.util.removeClass(component.find("spinner"),"slds-hide");
        var action = component.get("c.getMyPolicies");
        var fetchPoliciesPromise = this.promiseServerSideCall(action);
        fetchPoliciesPromise.then(
            $A.getCallback(function(result){
                    helper.setPoliciesMap(component,result);
                    helper.updateSelectedList(component);
                    component.set("v._fieldLabel",result.fieldlabel);
                })
            ).catch(
                $A.getCallback(function(error){
                    component.set("v._disableActions", true);
                    component.set("v._errorMessage", "Insufficient Privileges"); // @TODO - Add custom label
                })
            ).finally(
                //Hide Spinner
                function(){
                    $A.util.addClass(component.find("spinner"),"slds-hide"); 
                }
        );  
    },

    /**
    * @description Helper method to get the list of documents for a policy
    * @param component - The component to which the controller belongs. 
    * @param event - The event to which the controller belongs. 
    * @param helper — The component’s helper
    **/
    openPolicyDocuments: function(component,event,helper) {
        var action = component.get("c.getDocuments");
        action.setParams({
            recordId : event.getSource().get("v.value")
        });
        var filesPromise = this.promiseServerSideCall(action);
        filesPromise.then(
            $A.getCallback(function(result){
                    if(result && result.hasOwnProperty('documentIds') && result.documentIds.length > 0){
                        $A.get('e.lightning:openFiles').fire({
                            recordIds: result.documentIds
                        });
                    }else if(result && result.hasOwnProperty('documentIds') && result.documentIds.length == 0 && result.hasOwnProperty('policyname')){
                        helper.showNoItemsModal(component,result.policyname);
                    }
                })
            ).catch(
                $A.getCallback(function(error){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
            })
        );
    },

    /**
    * @description Helper method to get the policy read confirmation from the user
    * @param component - The component to which the controller belongs. 
    * @param event - The event to which the controller belongs.
    * @param helper — The component’s helper
    **/
    handleConfirmation: function(component,event,helper) {
        var policyId = event.getSource().get("v.value");
        var action = component.get("c.setPolicyRead");
        action.setParams({
            recordId : policyId
        });
        var confirmationPromise = this.promiseServerSideCall(action);
        confirmationPromise.then(
            $A.getCallback(function(result){
                helper.closeModal(component);
                helper.removeItem(component,policyId);
                })
            ).catch(            
                $A.getCallback(function(error){
                    helper.closeModal(component);
                    var toastError = $A.get("e.force:showToast");
                    toastError.setParams({
                        "type": "error",
                        "message": error.message
                    });
                    toastError.fire();
                })
        );
    },

    /**
    * @description Helper method to get the list view 
    * @param component - The component to which the controller belongs. 
    * @param event - The event to which the controller belongs.
    **/
    navigateToList: function(component,event) {
        var action = component.get("c.getListView");
        action.setParams({
            listViewName : component.get("v.mode") == 'Unread' ? component.get("v.unreadPoliciesListView") : component.get("v.readPoliciesListView")
        });
        var listViewPromise = this.promiseServerSideCall(action); 
        listViewPromise.then(
            $A.getCallback(function(result){
                if(result && result.hasOwnProperty('listviewid') && result.hasOwnProperty('sobjectname')){
                    $A.get("e.force:navigateToList")
                        .setParams({
                            "listViewId" : result.listviewid,
                            "listViewName" : component.get("v.listViewName"),
                            "scope" : result.sobjectname
                        }).fire();
                }
            })
        ).catch(
            $A.getCallback(function(error){
                console.log('Error is '+error);
            })
        );
    },
    
    /**
    * @description Helper method to remove the selected item from both policies map and display list
    * @param component - The component to which the controller belongs.
    * @param recordId - Id of the record to remove from policies map and display list.
    **/
    removeItem: function(component,recordId) {
        var policiesMap = component.get("v._policiesMap");
        var data = policiesMap[component.get("v.mode")];
        var indexToRemove = 0;
        var itemToRemove = null;
        data.forEach(function(item,index){
            if(recordId == item.Id){
                indexToRemove = index;
                itemToRemove = item;
            }
        });
        data.splice(indexToRemove, 1);
        component.set("v._displayList", data);
        var myPolicies = policiesMap['Read']; 
        myPolicies.splice(0,0,itemToRemove);
        policiesMap['Read'] = myPolicies;
        policiesMap['Unread'] = data;
        this.updateSelectedList(component);
    },

    /**
    * @description Helper method to populate the policies map
    * @param component - The component to which the controller belongs. 
    * @param response - JSON object contains both read and unread list of policies
    **/
    setPoliciesMap: function(component,response) {
        var policiesMap = {};
        if(response.hasOwnProperty('Read')) policiesMap['Read'] = response['Read'];  
        if(response.hasOwnProperty('Unread')) policiesMap['Unread'] = response['Unread']; 
        component.set("v._policiesMap",policiesMap);
    },

    /**
    * @description Helper method to update the display list
    * @param component - The component to which the controller belongs.
    **/
    updateSelectedList: function(component) {
        var status = component.get("v.mode");
        var limitValue = component.get("v.limitValue");
        var policiesMap = component.get("v._policiesMap");
        var data = [];
        if(!$A.util.isEmpty(status)){
            var myPolicies = policiesMap[status];
            var data = myPolicies.slice(0,limitValue);
            component.set("v._displayList",data);
        }
    },

    /**
    * @description Helper method to create policy confirmation modal
    * @param component - The component to which the controller belongs. 
    * @param event - The event to which the controller belongs. 
    **/
    showConfirmationModal: function(component,event) {
        $A.createComponents([
            ["aura:html",{"tag":"div","body":event.getSource().get("v.name"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["aura:html",{"tag":"div","body":$A.get("$Label.c.Confirm_Policy_Read"),"HTMLAttributes":{"class":"slds-text-align_center","style":"font-size:0.90rem;color:#3E3E3C;"}}],
            ["lightning:button",{"label":$A.get("$Label.c.Cancel"),"onclick":component.getReference("c.handleCloseModal")}],
            ["lightning:button",{"variant":"brand","label":$A.get("$Label.c.Confirm"),"onclick":component.getReference("c.handleConfirmation"),"value":event.getSource().get("v.value")}]
        ],
        function(components, status, errorMessage){
            if (status === "SUCCESS") {
                component.find("overlayLib").showCustomModal({
                   header: components[0],
                   body: components[1],
                   footer: [components[2],components[3]],
                   showCloseButton: true,
                   closeCallback: function() {}
               }).then(function(overlay){
                    // we need to set the modal instance in an attribute to call its methods
                    component.set("v.overlayPanel",[overlay]);
               });
            }else{
                console.error(errorMessage);
            }
        });
    },

    /**
    * @description Helper method to show no items modal
    * @param component - The component to which the controller belongs. 
    * @param policyName - Name of the policy to show it in the modal header. 
    **/
    showNoItemsModal: function(component,policyName) {
        $A.createComponents([
            ["aura:html",{"tag":"div","body":policyName,"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["aura:html",{"tag":"div","body":$A.get("$Label.c.No_Policy_Documents_To_Display"),"HTMLAttributes":{"class":"slds-text-align_center","style":"font-size:0.90rem;color:#3E3E3C;"}}]
        ],
        function(components, status, errorMessage){
            if(status === "SUCCESS"){
                component.find("overlayLib").showCustomModal({
                   header:components[0],
                   body:components[1],
                   showCloseButton: true,
                   closeCallback: function() {}
               }).then(function(overlay){
                    // we need to set the modal instance in an attribute to call its methods
                    component.set("v.overlayPanel",[overlay]);
               });
           }else{
               console.error(errorMessage);
           }
        });
    },

    /**
    * @description Helper method to close the modal
    * @param component - The component to which the controller belongs. 
    **/
    closeModal: function(component) {
        var overlayPanel = component.get("v.overlayPanel");
        if(!$A.util.isEmpty(overlayPanel)){
            overlayPanel[0].close();
        }
    },
})