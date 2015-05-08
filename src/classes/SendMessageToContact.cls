public without sharing class SendMessageToContact {

	@InvocableMethod(label='Send an SMS to the Contact\'s MobilePhone')
	public static List<ContactMessageDetails> SendMessageToContact(List<ContactMessageDetails> details){

		MessageServiceV2.sendMessageToContact(details[0].recipient, details[0].message);

		return details;
	}


	public class ContactMessageDetails{

		@InvocableVariable(label='Contact' description='The Contact that you want to send a message to')
		public Contact recipient;

		@InvocableVariable(label='Message' description='The message that you want to send')
		public String message;

	}

}