public without sharing class SendMessageToContactQueue implements Queueable, Database.AllowsCallouts{
	
	// With the back off of queued jobs this means we will have tried 5 times over 5 minutes (the initial on plus 4 retries)
	private static final Integer MAX_RETRIES = 4; 

	public SendMessageToContactQueue() {
		this.retryNumber = 0;
	}

	public SendMessageToContactQueue(List<MessageDetails> batchItems, Id jobId, Integer batchSize, Integer retryNumber){
		this.batchItems = batchItems;
		this.jobId = jobId;
		this.batchSize = batchSize;
		this.retryNumber = retryNumber;
	}

	private List<MessageDetails> batchItems;
	private Id jobId;
	private Integer batchSize;
	private Integer retryNumber;
	private static Id jobId;


	// The id of the job that will process the queued items
	public static Id getJobId(){
		if(jobId == null){
			if(!Test.isRunningTest()){
				jobId = system.enqueueJob(new SendMessageToContactQueue());
			}else{
				jobId = '0039000001WPYgIAAX';
			}

		}
		return jobId;
	}

	
	public static List<Queue_Item__c> addItemsToQueue(List<MessageDetails> items){

		List<Queue_Item__c> ret = new List<Queue_Item__c>();

		String text = JSON.serialize(items);
		if(text.length() > 65536){
			text = null;

			List<MessageDetails> a = new List<MessageDetails>();
			for(Integer i=0; i<(items.size()/2); i++){
				a.add(items.get(0));
				items.remove(0);
			}

			ret.addAll(SendMessageToContactQueue.addItemsToQueue(items));
			ret.addAll(SendMessageToContactQueue.addItemsToQueue(a));

		}else{
			ret.add(new Queue_Item__c(Job_Id__c=SendMessageToContactQueue.getJobId(), Details__c=text));
		}

		return ret;

	}


	public void execute(QueueableContext qCon){

		Integer soql = 0;
		Integer dml = 0;
		Integer rows = 0;
		Integer callouts = 0;
		Integer maxrows = 0;

		List<MessageDetails> items = new List<MessageDetails>();

		// Get all the records associated with the trigger
		Id jobId;
		if(!Test.isRunningTest()){
			jobId = qCon.getJobId();
		}else{
			jobId = '0039000001WPYgIAAX';
		}

		for(Queue_Item__c item : [SELECT Details__c FROM Queue_Item__c WHERE Job_Id__c = :jobId]){
			items.addAll((List<MessageDetails>)JSON.deserialize(item.Details__c, List<MessageDetails>.class));			
			rows++; // Add rows in here as we have to delete these at the end
		}


		// Details of limits we're going to encounter

		dml = 1;					// DML operations - this is just the clean up of the queue
		soql = 0; 					// Number of queries
		maxrows = 0; 				// Number of rows we will return across our queries
		callouts = items.size();	// Number of callouts - 1 per contact


		if(soql + Limits.getQueries() < Limits.getLimitQueries() 
				&& dml + Limits.getDMLStatements() < Limits.getLimitDMLStatements()
				&& rows + Limits.getDMLRows() < Limits.getLimitDMLRows()
				&& callouts + Limits.getCallouts() < Limits.getLimitCallouts()){

			// Run it now!!
			for(MessageDetails detail : items){
				processMessageDetails(detail);
			}

			if(!Test.isRunningTest()){
				jobId = qCon.getJobId();
			}else{
				jobId = '0039000001WPYgIAAX';
			}

			delete [SELECT Id FROM Queue_Item__c WHERE Job_Id__c = :jobId];

		}else{

			// Calculate batch size
			Integer batchsize = 100; // Could be more complex calc here, but in this case we only have one constraint

			// Spin up a batch job
			if(!Test.isRunningTest()){
				jobId = qCon.getJobId();
			}else{
				jobId = '0039000001WPYgIAAX';
			}

			runBatch(items, jobId, batchSize);
		}


	}

	private void runBatch(List<MessageDetails> bItems, Id jobId, Integer batchSize){

		if(exceededBatchJobLimit()){
			System.enqueueJob(new SendMessageToContactQueue(bItems, jobId, batchSize, ++retryNumber));
		}else{
			Database.executeBatch(new SendMessageToContactBatch(bItems, jobId), batchSize);
		}
	}


	public void processMessageDetails(MessageDetails item){

		MessageServiceV3.sendMessageToContact(new Contact(MobilePhone=item.RecipientNumber), item.Message);

	}


    /**
     * Return true if the number of jobs exceeds 5 - will need updating when flexiqueues is GA
     */
    private boolean exceededBatchJobLimit() {


        try {


            if(!Schema.sObjectType.AsyncApexJob.isAccessible()){
                return true;
            }else{

                Integer numBatchJobs = 0;
                try {
                    numBatchJobs = [SELECT COUNT() FROM AsyncApexJob WHERE status in ('Processing','Queued','Preparing', 'Holding') and JobType <> 'ScheduledApex' ];
                } catch (Exception e) {
                    system.debug(e.getMessage());
                }
                return numBatchJobs > 4 ? true : false;
            }
        } catch (NoAccessException nae) {
            // User doesn't have access to AsyncApexJob. TODO: find a better way of solving "caused by: System.NoAccessException: No access to entity: AsyncApexJob"
            return true;
        }
    }


	public class MessageDetails{

		public String RecipientNumber {get; set;}
		public String Message {get; set;}
	}

}