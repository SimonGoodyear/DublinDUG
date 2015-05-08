public with sharing class SendMessageToContactBatch implements Database.Batchable<SendMessageToContactQueue.MessageDetails>, Database.AllowsCallouts {

	private List<SendMessageToContactQueue.MessageDetails> bItems;
	private Id jId;

	public SendMessageToContactBatch(List<SendMessageToContactQueue.MessageDetails> MessageDetailss, Id jobId){
		this.bItems = MessageDetailss;
		this.jId = jobId;
	}	

	public Iterable<SendMessageToContactQueue.MessageDetails> start(Database.BatchableContext con){
		return this.bItems;
	}

	public void execute(Database.BatchableContext con, List<SendMessageToContactQueue.MessageDetails> items){

		SendMessageToContactQueue messageProcessor = new SendMessageToContactQueue();

		for(SendMessageToContactQueue.MessageDetails bItem : items){
			messageProcessor.processMessageDetails(bItem);
		}

	}

	public void finish(Database.BatchableContext con){
		delete [SELECT Id FROM Queue_Item__c WHERE Job_Id__c = :jId];
	}

}