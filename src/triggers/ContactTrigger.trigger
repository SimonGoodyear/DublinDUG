trigger ContactTrigger on Contact (after insert) {
    
    MessageServiceV2.sendMessageToContact(Trigger.new[0], 'We know your name, ' + Trigger.new[0].FirstName);
    
}