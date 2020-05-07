global without sharing class Process_SendEmail {

	private static final List<OrgWideEmailAddress> ORG_WIDE_ADDRESSES = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'do-not-reply@nav.no' LIMIT 1];
	private static final Id ORG_WIDE_EMAIL_ID = ORG_WIDE_ADDRESSES.size() == 1 ? ORG_WIDE_ADDRESSES[0].Id : null;

	@InvocableMethod(label = 'Send Email' )
	public static void sendEmail( List<Request> requests ) {

		Map<String, Id> templateMap = Process_SendEmailHelper.getMapOfEmailTemplates( requests );

		requests = Process_SendEmailHelper.removeInvalidRequests( requests );

		List<Messaging.SingleEmailMessage> messages = Process_SendEmailHelper.requestToSingleEmailMessage( requests, templateMap, ORG_WIDE_EMAIL_ID );

		List<Messaging.SendEmailResult> results = Messaging.sendEmail ( messages, false );
	}

	global class Request {

		@InvocableVariable(required = false label = 'Recipient Contact Lookup' description = 'The contact to email (if contact has no email, the email is not sent)')
		global Contact recipientContact;

		@InvocableVariable(required = false label = 'Object Relation ID' description = 'Fill if email template contains references ( {{{ var }}} )')
		global Id relatedToId;

		@InvocableVariable(required = false label = 'Dev Name of Enhanced Email Template')
		global String emailTemplateName;

		@InvocableVariable(required = false label = 'Use do-not-reply@nav.no' description = 'If false, the running user will be sender of email!')
		global Boolean useDoNotReply;
	}
}