public class MessageServiceV2 {

    public static void sendMessageToContact(Contact recipient, String message){
        
        if(recipient == null 
           		|| String.isBlank(recipient.MobilePhone)
           		|| String.isBlank(message))
            return;
        
        MessageServiceV2.message(recipient.MobilePhone, message);
    }
    
	@future(callout=true)
    private static void message(String phoneNumber, String message){
        
        if(String.isBlank(phoneNumber) || String.isBlank(message))
            return;
        
        String account = 'AC4205eb1909d65812e93c40a3eed9d72a';
        String token = '097674833477c4f5c1b81d4db9098bb4';
        TwilioRestClient client = new TwilioRestClient(account, token);
        
        Map<String,String> params = new Map<String,String> {
                'To'   => phoneNumber,
                'From' => '+441772367475',
                'Body' => message
            };
        
        TwilioSMS sms = client.getAccount().getSMSMessages().create(params);
        
    }    
    
    
}