//
//  SecurityService.swift
//  Intapp
//
//  Created by ra3571 on 2/23/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import Foundation

/**!
Important configuraion note:

Config.plist file contains the following configs 

adfs.endpoint https://fs.freescale.net/adfs/services/trust/13/UsernameMixed
adfs.realm urn:federation:MicrosoftOnline
adfs.contentType 


*/
public class SecurityService {

    var authenticatedUser: String?
    var rstToken: String?
    var samlData: NSMutableDictionary?
    
    // MARK: Shared Instance
    public class var sharedInstance: SecurityService  {
        struct Singleton {
            static let instance = SecurityService()
        }
        return Singleton.instance
    }
    
    init() {
        // read in any stored properties like user name and password
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // initSamlFromUserDefaults
        samlData = [:]
        
    }
    
    // used to indicate if the user is logged in 
    public func isLoggedIn() -> Bool {
        if samlData != nil {
            if samlData!["samlAssertion"] != nil {
                return true
            }
        }
        return false
    }
    
    // call this when you want to login. The call is done asynchrously so the callback is used
    // to get notified
    public func login(username:String, passwd:String, callback:(results: NSMutableDictionary?, error : NSError?) -> Void) {
        
        if let endpoint = NSUserDefaults.standardUserDefaults().valueForKey("adfs.endpoint") as? String {
            if let realm  = NSUserDefaults.standardUserDefaults().valueForKey("adfs.realm") as? String {
                if let url = NSURL(string: endpoint) {
                    let r = NSMutableURLRequest(URL: url)
                    
                    if let contentType = NSUserDefaults.standardUserDefaults().valueForKey("adfs.contentType") as? String {
                        r.addValue(contentType, forHTTPHeaderField: "Content-Type")
                    } else {
                        r.addValue("application/soap+xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    }
                    
                    r.HTTPMethod = "POST"
                    let soapMessage = getADFSSoapEnv(username, passwd: passwd, endpoint: endpoint, realm: realm)
                    let messageLength = "\(count(soapMessage))"
                    r.addValue(messageLength, forHTTPHeaderField  : "Content-Length")
                    r.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding)
                    let ro = AFHTTPRequestOperation(request: r)
                    ro.responseSerializer = AFXMLParserResponseSerializer()
                    ro.responseSerializer.acceptableContentTypes = NSSet(objects:"application/soap+xml","application/xml","text/html") as Set<NSObject>
                    
                    ro.setCompletionBlockWithSuccess({ (oper, responseObject) in
                        if responseObject.isKindOfClass(NSXMLParser) {
                            let parser = responseObject as! NSXMLParser
                            
                            var myParser = ADFSResponseParser().initWithParser(parser) as! ADFSResponseParser
                            let samlAssertion = myParser.results["samlAssertion"] as? String
                            let samlCreated = myParser.results["samlCreated"] as? String
                            let samlExpires = myParser.results["samlExpires"] as? String
                            
                            self.samlData!["samlAssertion"] = samlAssertion
                            self.samlData!["samlCreated"] = samlCreated
                            self.samlData!["samlExpires"] = samlExpires
                            
                            // save the samlStruct
                            NSUserDefaults.standardUserDefaults().setObject(self.samlData, forKey: "saml")
                            
                            // call the completion block...
                            dispatch_async(dispatch_get_main_queue(), {
                                callback(results: self.samlData, error: nil)
                            })
                        }
                        }, failure: { (oper, err) in
                            // something is wrong
                            NSLog("oper: \(oper)")
                            NSLog("err: \(err)")
                            
                            // call the completion block...
                            dispatch_async(dispatch_get_main_queue(), {
                                callback(results: nil, error: err)
                            })
                    })
                    ro.start()
                }
            }
        }
    }
    
    public func logout() {
        samlData = nil
    }
    
    
    public func loginToMicrosoft(username:String, passwd:String) {
 
        let endpoint = "https://fs.freescale.net/adfs/services/trust/13/UsernameMixed"
        let realm = "urn:federation:MicrosoftOnline"
        
        let url = NSURL(string: endpoint)
 
        if url != nil {
            
            // TODO: move to func
            let r = NSMutableURLRequest(URL: url!)
            r.addValue("application/soap+xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
            r.HTTPMethod = "POST"
            let soapMessage = getADFSSoapEnv(username, passwd: passwd, endpoint: endpoint, realm: realm)
            let messageLength = "\(count(soapMessage))"
            r.addValue(messageLength, forHTTPHeaderField  : "Content-Length")

            r.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding)
            let ro = AFHTTPRequestOperation(request: r)
            ro.responseSerializer = AFXMLParserResponseSerializer()
            ro.responseSerializer.acceptableContentTypes = NSSet(objects:"application/soap+xml","application/xml","text/html") as Set<NSObject>

            ro.setCompletionBlockWithSuccess({ (oper, responseObject) in
                if responseObject.isKindOfClass(NSXMLParser) {
                    let parser = responseObject as! NSXMLParser

                    var myParser = ADFSResponseParser().initWithParser(parser) as! ADFSResponseParser
                    let samlAssertion = myParser.results["samlAssertion"] as? String
                    let samlCreated = myParser.results["samlCreated"] as? String
                    let samlExpires = myParser.results["samlExpires"] as? String
                    
                    // if we have these values...then it is time to get the RST token
                    // TODO: move this to own function
                    let rstEndpoint = "https://login.microsoftonline.com/RST2.srf"
                    
                    let rstRealm = "https://freescale.sharepoint.com"
                    let rstUrl = NSURL(string: rstEndpoint)
                    if  rstUrl != nil {
                        let rstReq = NSMutableURLRequest(URL: rstUrl!)
                        let rstMessage = self.getRSTSoapEnv(rstEndpoint, realm: rstRealm, samlAssertion: samlAssertion!, created: samlCreated!, expires: samlExpires!)
                        DLog("rstMessage:\n\(rstMessage)")

                        let rstMessageLength = "\(count(rstMessage))"
                        
                        rstReq.addValue("application/soap+xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                        rstReq.HTTPMethod = "POST"
                        rstReq.addValue(rstMessageLength, forHTTPHeaderField  : "Content-Length")
                        rstReq.HTTPBody = rstMessage.dataUsingEncoding(NSUTF8StringEncoding)
                        
                        let rstRequestOper = AFHTTPRequestOperation(request: rstReq)
                        rstRequestOper.responseSerializer = AFXMLParserResponseSerializer()
                        rstRequestOper.responseSerializer.acceptableContentTypes = NSSet(objects:"application/soap+xml","application/xml","text/html") as Set<NSObject>
                        rstRequestOper.setCompletionBlockWithSuccess({ (rstOper, rstResponseObject) in
                            if rstResponseObject.isKindOfClass(NSXMLParser) {
                                let rstParser = rstResponseObject as! NSXMLParser
                                var myParser = RTSResponseParser().initWithParser(rstParser) as! RTSResponseParser
                                
                                // get the value for wsse:BinarySecurityToken
                            }
                        }, failure: { (rstOper, err) in
                            // something is wrong
                            NSLog("rstOper: \(rstOper)")
                            NSLog("error: \(err)")
                            // display an alert
                            
                        })
                        rstRequestOper.start()
                    }
                }
            }, failure: { (oper, err) in
                    // something is wrong
                    NSLog("oper: \(oper)")
                    NSLog("err: \(err)")
            })
            ro.start()
        }
    }
    
    

    /**
    <s:Envelope
    xmlns:s="http://www.w3.org/2003/05/soap-envelope"
    xmlns:a="http://www.w3.org/2005/08/addressing"
    xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
    <s:Header>
    <a:Action s:mustUnderstand="1">http://docs.oasis-open.org/ws-sx/ws-trust/200512/RST/Issue</a:Action>
    <a:To s:mustUnderstand="1">{endpoint}</a:To>
    <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
    <o:UsernameToken u:Id="uuid-6a13a244-dac6-42c1-84c5-cbb345b0c4c4-1">
    <o:Username>{username}</o:Username>
    <o:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">{password}</o:Password>
    </o:UsernameToken>
    </o:Security>
    </s:Header>
    <s:Body>
    <t:RequestSecurityToken xmlns:t="http://docs.oasis-open.org/ws-sx/ws-trust/200512">
    <wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy">
    <a:EndpointReference>
    <a:Address>{realm}</a:Address>
    </a:EndpointReference>
    </wsp:AppliesTo>
    <t:KeyType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Bearer</t:KeyType>
    <t:RequestType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Issue</t:RequestType>
    <t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType>
    </t:RequestSecurityToken>
    </s:Body>
    </s:Envelope>
    
    returns something like
    
    */
    func getADFSSoapEnv(username: String, passwd: String, endpoint: String, realm: String) -> String {
        let template = "<s:Envelope" +
            " xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\"" +
            " xmlns:a=\"http://www.w3.org/2005/08/addressing\"" +
            " xmlns:u=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">" +
            "    <s:Header>" +
            "        <a:Action s:mustUnderstand=\"1\">http://docs.oasis-open.org/ws-sx/ws-trust/200512/RST/Issue</a:Action>" +
            "        <a:To s:mustUnderstand=\"1\">{endpoint}</a:To>" +
            "        <o:Security s:mustUnderstand=\"1\" xmlns:o=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\">" +
            "            <o:UsernameToken u:Id=\"uuid-6a13a244-dac6-42c1-84c5-cbb345b0c4c4-1\">" +
            "                <o:Username>{username}</o:Username>" +
            "                <o:Password Type=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText\">{password}</o:Password>" +
            "            </o:UsernameToken>" +
            "        </o:Security>" +
            "    </s:Header>" +
            "    <s:Body>" +
            "        <t:RequestSecurityToken xmlns:t=\"http://docs.oasis-open.org/ws-sx/ws-trust/200512\">" +
            "            <wsp:AppliesTo xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\">" +
            "                <a:EndpointReference>" +
            "                    <a:Address>{realm}</a:Address>" +
            "                </a:EndpointReference>" +
            "            </wsp:AppliesTo>" +
            "            <t:KeyType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Bearer</t:KeyType>" +
            "            <t:RequestType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Issue</t:RequestType>" +
            "            <t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType>" +
            "        </t:RequestSecurityToken>" +
            "    </s:Body>" +
        "</s:Envelope>"
        
        // sub in the value
        var retVal = template.stringByReplacingOccurrencesOfString("{username}", withString: username, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{password}", withString: passwd, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{endpoint}", withString: endpoint, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{realm}", withString: realm, options: NSStringCompareOptions.LiteralSearch, range: nil)
        return retVal
    }
    
    /*!
    This method returns the soap message to get the RST token
    
    <soap:Envelope
    xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
    xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust"
    xmlns:auth="http://schemas.xmlsoap.org/ws/2006/12/authorization"
    xmlns:wsa="http://www.w3.org/2005/08/addressing"
    xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" >
    <soap:Header>
    <wsa:To>{endpoint}</wsa:To>
    <wsa:ReplyTo>
    <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>
    </wsa:ReplyTo>
    <wsa:Action>http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action>
    <wsse:Security>
    <wsu:Timestamp xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="timestamp">
    <wsu:Created xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">{created}</wsu:Created>
    <wsu:Expires xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">{expires}</wsu:Expires>
    </wsu:Timestamp>
    {samlAssertion}
    </wsse:Security>
    </soap:Header>
    <soap:Body>
    <wst:RequestSecurityToken>
    <wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType>
    <wsp:AppliesTo>
    <wsa:EndpointReference>
    <wsa:Address>{realm}</wsa:Address>
    </wsa:EndpointReference>
    </wsp:AppliesTo>
    </wst:RequestSecurityToken>
    </soap:Body>
    </soap:Envelope>'
    */
    func getRSTSoapEnv(endpoint: String, realm: String, samlAssertion: String, created: String, expires: String) -> String {
        
        let template = "<soap:Envelope" +
            " xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\"" +
            " xmlns:wst=\"http://schemas.xmlsoap.org/ws/2005/02/trust\"" +
            " xmlns:auth=\"http://schemas.xmlsoap.org/ws/2006/12/authorization\"" +
            " xmlns:wsa=\"http://www.w3.org/2005/08/addressing\"" +
            " xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\"" +
            " xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"" +
            " xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" >" +
            "   <soap:Header>" +
            "      <wsa:To>{endpoint}</wsa:To>" +
            "      <wsa:ReplyTo>" +
            "         <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>" +
            "      </wsa:ReplyTo>" +
            "      <wsa:Action>http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action>" +
            "      <wsse:Security>" +
            "         <wsu:Timestamp xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" wsu:Id=\"timestamp\">" +
            "            <wsu:Created xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">{created}</wsu:Created>" +
            "            <wsu:Expires xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">{expires}</wsu:Expires>" +
            "         </wsu:Timestamp>" +
            "         {samlAssertion}" +
            "      </wsse:Security>" +
            "   </soap:Header>" +
            "   <soap:Body>" +
            "      <wst:RequestSecurityToken>" +
            "         <wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType>" +
            "         <wsp:AppliesTo>" +
            "            <wsa:EndpointReference>" +
            "               <wsa:Address>{realm}</wsa:Address>" +
            "            </wsa:EndpointReference>" +
            "         </wsp:AppliesTo>" +
            "      </wst:RequestSecurityToken>" +
            "   </soap:Body>" +
        "</soap:Envelope>"
        
        var retVal = template.stringByReplacingOccurrencesOfString("{created}", withString: created, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{expires}", withString: expires, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{samlAssertion}", withString: samlAssertion, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{endpoint}", withString: realm, options: NSStringCompareOptions.LiteralSearch, range: nil)
        retVal = retVal.stringByReplacingOccurrencesOfString("{realm}", withString: realm, options: NSStringCompareOptions.LiteralSearch, range: nil)
        return retVal

    }
    
    /*
    This will parse ther response from the ADFS server when we send 
    * the ADFS SOAP Envelope
    */
    class ADFSResponseParser: NSObject, NSXMLParserDelegate {

        var currentElement = NSString() // this is the current element we are parsing
        var parser = NSXMLParser()      // this is the parser retured from the operation
        var results = NSMutableDictionary() // this is the results dictionary that we will use for later
        var insideAssertion = false
        
        func initWithParser(parser:NSXMLParser) -> AnyObject {
            results["samlAssertion"] = ""
            
            self.parser = parser
            parser.delegate = self
            parser.shouldProcessNamespaces = true
            parser.shouldReportNamespacePrefixes = true
            parser.shouldResolveExternalEntities = false
            parser.parse()
           
            return self
        }
        
        func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [NSObject : AnyObject]) {
            
            println("<\(qualifiedName)>")
            
            currentElement = qualifiedName!
            
            // this block will create code
            if currentElement.isEqualToString("saml:Assertion") {
                insideAssertion = true
            }
            
            if insideAssertion {
                // we are inside the saml assertion so add all this to the string
                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString("<\(qualifiedName) ")
                if attributeDict.count > 0 {
                    var count = 0
                    for (attr, val) in attributeDict {
                        results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString("\(attr)=\"\(val)\"")
                        count++
                        if (count < attributeDict.count) {
                            results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString(" ")
                        }
                    }
                }
                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString(">")
            }
        }
        
        /* This method is called inside of the elements */
        func parser(parser: NSXMLParser, foundCharacters string: String?) {
            println("\(string)")
            
            // assign to the correct key
            if currentElement.isEqualToString("wsu:Created") {
                results["samlCreated"] = string
            } else if currentElement.isEqualToString("wsu:Expires") {
                results["samlExpires"] = string
            } else if currentElement.isEqualToString("saml:Assertion") {
                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString(string!)
            } else if insideAssertion {
                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString(string!)
            }
        }
        
        func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            println("</\(qName)>")
            if (qName == "saml:Assertion") {
                insideAssertion = false
                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString("</\(qName)>")
            } else if (insideAssertion == true) {
                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString("</\(qName)>")
            }
        }
    }
    
    /*
    This will parse ther response from the ADFS server when we send
    * the ADFS SOAP Envelope
    */
    class RTSResponseParser: NSObject, NSXMLParserDelegate {
        
        var parser = NSXMLParser()      // this is the parser retured from the operation
        var results = NSMutableDictionary() // this is the results dictionary that we will use for later
       // var insideAssertion = false
        
        func initWithParser(parser:NSXMLParser) -> AnyObject {
            results["samlAssertion"] = ""
            
            self.parser = parser
            parser.delegate = self
            parser.shouldProcessNamespaces = true
            parser.shouldReportNamespacePrefixes = true
            parser.shouldResolveExternalEntities = false
            parser.parse()
            
            return self
        }

        
        func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [NSObject : AnyObject]) {
            println("<\(qualifiedName)>")
        }
        
        func parser(parser: NSXMLParser, foundCharacters string: String?) {
            println("\(string)")
        }

        
        func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            println("</\(qName)>")
//            if (qName == "saml:Assertion") {
//                insideAssertion = false
//                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString("</\(qName)>")
//            } else if (insideAssertion == true) {
//                results["samlAssertion"] = results["samlAssertion"]?.stringByAppendingString("</\(qName)>")
//            }
        }
    }
    
}
