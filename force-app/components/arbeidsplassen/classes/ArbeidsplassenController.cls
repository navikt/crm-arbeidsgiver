public with sharing class ArbeidsplassenController {
    private static final String SIZE = '1000'; // amount of positions

    @AuraEnabled(cacheable=true)
    public static ArbeidsplassenWrapperModel getData(String recordId) {
        List<Account> acc = [SELECT INT_OrganizationNumber__c FROM Account WHERE Id = :recordId LIMIT 1];
        if (acc.size() == 0) {
            throwAuraError();
        }
        if (acc[0].INT_OrganizationNumber__c == null) {
            throw new AuraException('Bedriften mangler organisasjonsnummer.');
        }

        ArbeidsplassenWrapperModel wrapper;

        try {
            HttpResponse response = ArbeidsplassenController.doCallout(acc[0].INT_OrganizationNumber__c);
            ArbeidsplassenRawModel model = ArbeidsplassenRawModel.parse(response.getBody());

            List<ArbeidsplassenViewModel> viewModels = new List<ArbeidsplassenViewModel>();
            for (ArbeidsplassenRawModel.Content content : model.content) {
                viewModels.add(new ArbeidsplassenViewModel(content));
            }

            wrapper = new ArbeidsplassenWrapperModel(model.totalElements, viewModels);
        } catch (Exception e) {
            throwAuraError();
        }

        return wrapper;
    }

    public static HttpResponse doCallout(String orgNumber) {
        List<AccessToken__c> accessTokens = [
            SELECT Token__c
            FROM AccessToken__c
            WHERE Name__c = 'arbeidsplassen'
            LIMIT 1
        ];
        String accesToken = accessTokens.size() == 1 ? accessTokens[0].Token__c : '';

        if (accessTokens.size() == 0 && !Test.isRunningTest()) {
            throwAuraError();
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://arbeidsplassen.nav.no/public-feed/api/v1/ads?orgnr=' + orgNumber + '&size=' + SIZE);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', accesToken);
        Http h = new Http();

        HttpResponse res;
        try {
            res = h.send(req);
        } catch (Exception e) {
            throwAuraError();
        }

        return res;
    }

    private static void throwAuraError() {
        throw new AuraException(
            'Feil ved henting av data fra arbeidsplassen.nav.no. Vennligst prøv igjen senere, eller kontakt din nærmeste leder.'
        );
    }
}
