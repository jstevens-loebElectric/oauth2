component extends="oauth2" accessors="true" {

	property name="client_id" type="string";
	property name="client_secret" type="string";
	property name="authEndpoint" type="string";
	property name="accessTokenEndpoint" type="string";
	property name="redirect_uri" type="string";
	
	/**
	* I return an initialized microsoft object instance.
	* @client_id The client ID for your application.
	* @authEndpoint The URL endpoint that handles the authorisation.
	* @accessTokenEndpoint The URL endpoint that handles retrieving the access token.
	* @redirect_uri The URL to redirect the user back to following authentication.
	**/
	public microsoft function init(
		required string client_id,
		required string client_secret,
		required string authEndpoint = 'https://login.microsoftonline.com/b7e3672d-b254-4b15-9a02-da1c739db9fd/oauth2/v2.0/authorize', 
		required string accessTokenEndpoint = 'https://login.microsoftonline.com/b7e3672d-b254-4b15-9a02-da1c739db9fd/oauth2/v2.0/token',
		required string redirect_uri
	)
	//N.B. I have set the default tenant of the application in the authEndPoint and accessTokenEndpoint variables to the coldbox-application-template's Directory ID on Azure. 
	//For future applications, this tenant value, the one that starts with .../b7e and goes to 9fd/... should be changed.
	{
		super.init(
			client_id           = arguments.client_id, 
			client_secret       = arguments.client_secret, 
			authEndpoint        = arguments.authEndpoint, 
			accessTokenEndpoint = arguments.accessTokenEndpoint, 
			redirect_uri        = arguments.redirect_uri
		);
		return this;
	}

	/**
	* I return the URL as a string which we use to redirect the user for authentication.
	* @scope An optional array of values to pass through for scope access.
	**/
	public string function buildRedirectToAuthURL(
		array scope = ["User.Read"] //These are the permissions being asked for by Oauth
	){
		var sParams = {
			'response_type' = 'code'
		};
		if( arrayLen( arguments.scope ) ){
			structInsert( sParams, 'scope', arrayToList( arguments.scope, ' ' ) );
		}
		return super.buildRedirectToAuthURL( sParams );
	}

	/**
	* I make the HTTP request to obtain the access token.
	* @code The code returned from the authentication request.
	* @scope The scopes of permissions requested by the application.
	* EDITS BY Jeff Stevens:
	* This was originally outdated an no longer worked with Microsoft's Azure Application Oauth procedures.
	* 	-The inherited oauth2 component functions are no longer used here. The HTTP request for the token is made here directly.
	*	-The default scope is the one used for the template application. It should be subject to change based on the scopes required for your application.
	*	-
	**/
	public struct function makeAccessTokenRequest(
		required string code,
		array scope = ["User.Read"]
	)
	{
		//Build an HTTP post request with our oAuth object's properties
		local.httpService = new http(method="post", charset="utf-8", url=variables.accessTokenEndpoint);
		local.httpService.addParam( type="formfield", name="client_id", value=getClient_id());
		local.httpService.addParam( type="formfield", name="grant_type", value="authorization_code");
		local.httpService.addParam( type="formfield", name="scope", value=arrayToList(arguments.scope, ' '));
		local.httpService.addParam( type="formfield", name="code", value=arguments.code);
		local.httpService.addParam( type="formfield", name="redirect_uri", value=getRedirect_uri());
		local.httpService.addParam( type="formfield", name="client_secret", value=getClient_secret());

		//Send the http request
		var result = httpService.send().getPrefix();
		local.content = listToArray(result.fileContent,chr(10));

		//Check the result of our token access request
		if( '200' == result.ResponseHeader[ 'Status_Code' ] ) {
	    	stuResponse.success = true;
	    	stuResponse.content = result.FileContent;
	    } else {
	    	stuResponse.success = false;
	    	stuResponse.content = result.Statuscode;
	    }
    	return stuResponse;
	}

}
