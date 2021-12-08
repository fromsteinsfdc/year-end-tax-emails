({
    handleNewRecordIds : function(component, event) {
        console.log('in handleNewRecordIds (in helper)');
        var recordIds = event.getParam('recordIds');
        console.log('recordIds = '+ recordIds);
        
        component.set('v.recordIds', recordIds);
    }
})
