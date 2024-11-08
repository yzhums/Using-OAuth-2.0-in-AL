page 50100 "Test OAuth 2.0 in AL"
{
    Caption = 'Test OAuth 2.0 in AL';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Info)
            {
                field(ClientID; ClientID)
                {
                    ApplicationArea = All;
                    Caption = 'Client ID';
                    ToolTip = 'The client ID of the Azure AD application';
                }
                field(ClientSecret; ClientSecret)
                {
                    ApplicationArea = All;
                    Caption = 'Client Secret';
                    ToolTip = 'The client secret of the Azure AD application';
                }
                field(TenantID; TenantID)
                {
                    ApplicationArea = All;
                    Caption = 'Tenant ID';
                    ToolTip = 'The tenant ID of the Azure AD application';
                }
                field(CallEndpoint; CallEndpoint)
                {
                    ApplicationArea = All;
                    Caption = 'Call Endpoint';
                    ToolTip = 'The endpoint to call';

                    trigger OnValidate()
                    begin
                        Result := '';
                    end;
                }
            }
            group(Results)
            {
                field(Result; Result)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                    Caption = 'Result';
                    ShowCaption = false;
                    ToolTip = 'The result of the call';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetData)
            {
                Caption = 'Get Data';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = GetActionMessages;

                trigger OnAction()
                var
                    OAuth2TestInAL: Codeunit OAuth2TestInAL;
                begin
                    OAuth2TestInAL.GetData(CallEndpoint, ClientID, ClientSecret, TenantID, Result);
                    CurrPage.Update();
                end;
            }
        }
    }

    var
        CallEndpoint: Text;
        ClientID: Text;
        ClientSecret: Text;
        TenantID: Text;
        Result: Text;
}

codeunit 50120 OAuth2TestInAL
{
    procedure GetData(CallEndpoint: Text; ClientID: Text; ClientSecret: Text; TenantID: Text; var Result: Text)
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        AuthToken: SecretText;
        ResponseText: Text;
    begin
        // Get OAuth token
        AuthToken := GetOAuthToken(ClientID, ClientSecret, TenantID);

        if AuthToken.IsEmpty() then
            Error('Failed to obtain access token.');

        // Initialize the HTTP request
        HttpRequestMessage.SetRequestUri(CallEndpoint);
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken));

        // Send the HTTP request
        if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            // Log the status code for debugging
            //Message('HTTP Status Code: %1', HttpResponseMessage.HttpStatusCode());

            if HttpResponseMessage.IsSuccessStatusCode() then begin
                HttpResponseMessage.Content.ReadAs(ResponseText);
                Result := ResponseText;
            end else begin
                // Here's where the error is reported
                HttpResponseMessage.Content.ReadAs(ResponseText);
                Error('Failed to get: %1 %2', HttpResponseMessage.HttpStatusCode(), ResponseText);
            end;
        end else
            Error('Failed to send HTTP request');
    end;

    procedure GetOAuthToken(ClientID: Text; ClientSecret: Text; TenantID: Text) AuthToken: SecretText
    var
        AccessTokenURL: Text;
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
    begin
        AccessTokenURL := 'https://login.microsoftonline.com/' + TenantID + '/oauth2/v2.0/token';
        Scopes.Add('https://api.businesscentral.dynamics.com/.default');
        if not OAuth2.AcquireTokenWithClientCredentials(ClientID, ClientSecret, AccessTokenURL, '', Scopes, AuthToken) then
            Error('Failed to get access token from response\%1', GetLastErrorText());
    end;
}
