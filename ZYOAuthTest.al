pageextension 50100 CustomerListExt extends "Customer List"
{
    actions
    {
        addafter("Sent Emails")
        {
            action(GetOAuthToken)
            {
                Caption = 'Get OAuth Token';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = GetActionMessages;

                trigger OnAction()
                var
                    BCEnvironmentHandler: Codeunit OAuth2TestInAL;
                begin
                    BCEnvironmentHandler.GetOAuthToken();
                end;
            }
        }
    }
}

codeunit 50120 OAuth2TestInAL
{
    procedure GetOAuthToken() AuthToken: Text
        var
            HttpClient: HttpClient;
            HttpRequestMessage: HttpRequestMessage;
            HttpResponseMessage: HttpResponseMessage;
            HttpContent: HttpContent;
            Headers: HttpHeaders;
            ResponseText: Text;
            JsonToken: JsonToken;
            JsonResponse: JsonObject;
            JsonValue: JsonValue;
            ClientID: Text;
            ClientSecret: Text;
            TenantID: Text;
            TokenEndpoint: Text;
            Content: Text;
        begin
            // Get client ID, client secret, and tenant ID from setup
            ClientID := 'b4fe1687-f1ab-4bfa-b494-0e2236ed50bd';
            ClientSecret := 'huL8Q~edsQZ4pwyxka3f7.WUkoKNcPuqlOXv0bww';
            TenantID := '7e47da45-7f7d-448a-bd3d-1f4aa2ec8f62';

            // Define the token endpoint
            TokenEndpoint := 'https://login.microsoftonline.com/' + TenantID + '/oauth2/v2.0/token';

            // Define the request content
            Content := 'grant_type=client_credentials&client_id=' + ClientID + '&client_secret=' + ClientSecret + '&scope=https://graph.microsoft.com/.default';

            // Initialize the HTTP request
            HttpRequestMessage.SetRequestUri(TokenEndpoint);
            HttpRequestMessage.Method := 'POST';

            // Initialize the HTTP content
            HttpContent.WriteFrom(Content);
            HttpContent.GetHeaders(Headers);
            Headers.Remove('Content-Type');
            Headers.Add('Content-Type', 'application/x-www-form-urlencoded');
            HttpRequestMessage.Content := HttpContent;

            // Send the HTTP request
            if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
                if HttpResponseMessage.IsSuccessStatusCode() then begin
                    HttpResponseMessage.Content.ReadAs(ResponseText);
                    JsonResponse.ReadFrom(ResponseText);
                    if JsonResponse.Get('access_token', JsonToken) then begin
                        JsonValue := JsonToken.AsValue();
                        AuthToken := JsonValue.AsText();
                        Message(AuthToken);
                        exit(AuthToken);
                    end else
                        Error('Failed to get access token from response');
                end else
                    Error('Failed to get access token: %1', HttpResponseMessage.HttpStatusCode());
            end else
                Error('Failed to send HTTP request for access token');
        end;
}
