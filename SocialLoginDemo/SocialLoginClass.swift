//
//  SocialLoginClass.swift
//  SocialLoginDemo
//
//  Created by Parth on 01/09/20.
//  Copyright © 2020 Samcom. All rights reserved.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices

class SocialLoginClass: NSObject,GIDSignInDelegate{
    
    static let shared = SocialLoginClass()
    var webView = WKWebView()
    var controllerView = UIViewController()
    var CLIENT_ID = ""
    var CLIENT_SECRET = ""
    var REDIRECT_URI = ""
    
    var linkedin_Name = ""
    var linkedin_LastName = ""
    var linkedin_Email = ""
    var linkedin_Id = ""
    var linkedin_Pic = ""

}

// MARK: - Google Login -
extension SocialLoginClass{
    func setGoogle(view:ViewController){
           GIDSignIn.sharedInstance().presentingViewController = view
       }
       
       func googleLogin(){
           GIDSignIn.sharedInstance()?.delegate = self
           GIDSignIn.sharedInstance()?.signOut()
           GIDSignIn.sharedInstance().signIn()
       }
       
       func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
           if error != nil {
            NotificationCenter.default.post(name: .kGoogleLogin, object: nil, userInfo: ["userProfile":"Error: \(error!)"])
           }
           else {
            NotificationCenter.default.post(name: .kGoogleLogin, object: nil, userInfo: ["userProfile":GIDSignIn.sharedInstance().currentUser.profile!])
           }
       }
}

// MARK: - Facebook Login -
extension SocialLoginClass{
    func setFBButton(){
        NotificationCenter.default.addObserver(forName: .AccessTokenDidChange, object: nil, queue: OperationQueue.main) { (notification) in
            self.checkLoggedInAndFetchData()
        }
    }
    
    func FBLogout(){
        if AccessToken.current != nil {
            LoginManager().logOut()
        }
    }
    func checkLoggedInAndFetchData(){
        if let token = AccessToken.current,
            !token.isExpired {
            // for more parameter see https://developers.facebook.com/docs/graph-api/reference/user
            
            let parameter = ["fields":"birthday, email,first_name, id, last_name, name, picture.type(large)"]
            
            let req = GraphRequest(graphPath: "me", parameters:parameter , tokenString: token.tokenString, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))
            req.start { (connection, result, error) in
                if(error == nil) {
                    NotificationCenter.default.post(name: .kFacebookLogin, object: nil, userInfo: ["userProfile":result!])
                } else {
                    NotificationCenter.default.post(name: .kFacebookLogin, object: nil, userInfo: ["userProfile":"Error: \(error!)"])
                }
            }
            // User is logged in, do work such as go to next view controller.
        }
    }
    
}

// MARK: - Linkedin Login -
extension SocialLoginClass: WKNavigationDelegate {
    func setRequiredLinkedInAuth(clientId:String,clientSecretId:String,redirectURL:String){
        CLIENT_ID = clientId
        CLIENT_SECRET = clientSecretId
        REDIRECT_URI = redirectURL
    }
    
    func linkedInAuthVC(view:ViewController) {
        controllerView = view
        // Create linkedIn Auth ViewController
        let linkedInVC = UIViewController()
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        linkedInVC.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: linkedInVC.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: linkedInVC.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: linkedInVC.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: linkedInVC.view.trailingAnchor)
        ])
        
        let state = "linkedin\(Int(NSDate().timeIntervalSince1970))"
        
        let authURLFull = LinkedInConstants.AUTHURL + "?response_type=code&client_id=" + self.CLIENT_ID + "&scope=" + LinkedInConstants.SCOPE + "&state=" + state + "&redirect_uri=" + self.REDIRECT_URI
        
        
        let urlRequest = URLRequest.init(url: URL.init(string: authURLFull)!)
        webView.load(urlRequest)
        
        // Create Navigation Controller
        let navController = UINavigationController(rootViewController: linkedInVC)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
        linkedInVC.navigationItem.leftBarButtonItem = cancelButton
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
        linkedInVC.navigationItem.rightBarButtonItem = refreshButton
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navController.navigationBar.titleTextAttributes = textAttributes
        linkedInVC.navigationItem.title = "linkedin.com"
        navController.navigationBar.isTranslucent = false
        navController.navigationBar.tintColor = UIColor.white
        navController.navigationBar.barTintColor = UIColor.black
        navController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        navController.modalTransitionStyle = .coverVertical
        
        controllerView.present(navController, animated: true, completion: nil)
    }
    
    func linkedInLogout(){
        let cookieStorage: HTTPCookieStorage = HTTPCookieStorage.shared
          if let cookies = cookieStorage.cookies {
              for cookie in cookies {
                      cookieStorage.deleteCookie(cookie)
              }
          }
        let revokeUrl = "https://api.linkedin.com/uas/oauth/invalidateToken"

        let request = URLRequest(url: URL(string: revokeUrl)! as URL)
        webView.load(request)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let cookieStorage2: HTTPCookieStorage = HTTPCookieStorage.shared
            if let cookies = cookieStorage2.cookies {
                for cookie in cookies {
                    cookieStorage.deleteCookie(cookie)
                }
            }
            let revokeUrl2 = "https://api.linkedin.com/uas/oauth/invalidateToken"
            let request2 = URLRequest(url: URL(string: revokeUrl2)! as URL)
            self.webView.load(request2)
            print("logout Successfull")

        }
        
    }
    @objc func cancelAction() {
        controllerView.dismiss(animated: true, completion: nil)
    }
    
    @objc func refreshAction() {
        self.webView.reload()
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        RequestForCallbackURL(request: navigationAction.request)
        
        //Close the View Controller after getting the authorization code
        if let urlStr = navigationAction.request.url?.absoluteString {
            if urlStr.contains("?code=") {
                print(urlStr)
                controllerView.dismiss(animated: true, completion: nil)
            }
        }
        decisionHandler(.allow)
    }
    
    func RequestForCallbackURL(request: URLRequest) {
        // Get the authorization code string after the '?code=' and before '&state='
        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.hasPrefix(self.REDIRECT_URI) {
            if requestURLString.contains("?code=") {
                if let range = requestURLString.range(of: "=") {
                    let linkedinCode = requestURLString[range.upperBound...]
                    if let range = linkedinCode.range(of: "&state=") {
                        let linkedinCodeFinal = linkedinCode[..<range.lowerBound]
                        linkedinRequestForAccessToken(authCode: String(linkedinCodeFinal))

                    }
                }
            }
        }
    }
    
   func linkedinRequestForAccessToken(authCode: String) {
        let grantType = "authorization_code"
        // Set the POST parameters.
        let postParams = "grant_type=" + grantType + "&code=" + authCode + "&redirect_uri=" + self.REDIRECT_URI + "&client_id=" + self.CLIENT_ID + "&client_secret=" + self.CLIENT_SECRET
        let postData = postParams.data(using: String.Encoding.utf8)
        let request = NSMutableURLRequest(url: URL(string: LinkedInConstants.TOKENURL)!)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                let results = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                
                let accessToken = results?["access_token"] as! String
//                print("accessToken is: \(accessToken)")
                
                let expiresIn = results?["expires_in"] as! Int
                print("expires in: \(expiresIn)")
                
                // Get user's id, first name, last name, profile pic url
                self.fetchLinkedInUserProfile(accessToken: accessToken)
            }
        }
        task.resume()
    }
    func fetchLinkedInUserProfile(accessToken: String) {
        let tokenURLFull = "https://api.linkedin.com/v2/me?projection=(id,firstName,lastName,profilePicture(displayImage~:playableStreams))&oauth2_access_token=\(accessToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let verify: NSURL = NSURL(string: tokenURLFull!)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: verify as URL)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error == nil {
                let linkedInProfileModel = try? JSONDecoder().decode(LinkedInProfileModel.self, from: data!)
                
                //AccessToken
//                print("LinkedIn Access Token: \(accessToken)")
                
                // LinkedIn Id
                let linkedinId: String! = linkedInProfileModel?.id
//                print("LinkedIn Id: \(linkedinId ?? "")")
                self.linkedin_Id = linkedinId ?? ""

                // LinkedIn First Name
                let linkedinFirstName: String! = linkedInProfileModel?.firstName.localized.enUS
//                print("LinkedIn First Name: \(linkedinFirstName ?? "")")
                self.linkedin_Name = linkedinFirstName
                // LinkedIn Last Name
                let linkedinLastName: String! = linkedInProfileModel?.lastName.localized.enUS
//                print("LinkedIn Last Name: \(linkedinLastName ?? "")")
                self.linkedin_LastName = linkedinLastName

                // LinkedIn Profile Picture URL
                let linkedinProfilePic: String!
                
                /*
                 Change row of the 'elements' array to get diffrent size of the profile url
                 elements[0] = 100x100
                 elements[1] = 200x200
                 elements[2] = 400x400
                 elements[3] = 800x800
                 */
                if let pictureUrls = linkedInProfileModel?.profilePicture.displayImage.elements[2].identifiers[0].identifier {
                    linkedinProfilePic = pictureUrls
                } else {
                    linkedinProfilePic = "Not exists"
                }
//                print("LinkedIn Profile Avatar URL: \(linkedinProfilePic ?? "")")
                self.linkedin_Pic = linkedinProfilePic ?? ""
                // Get user's email address
                self.fetchLinkedInEmailAddress(accessToken: accessToken)
            }
        }
        task.resume()
    }
    
    func fetchLinkedInEmailAddress(accessToken: String) {
        let tokenURLFull = "https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))&oauth2_access_token=\(accessToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let verify: NSURL = NSURL(string: tokenURLFull!)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: verify as URL)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error == nil {
                let linkedInEmailModel = try? JSONDecoder().decode(LinkedInEmailModel.self, from: data!)
                
                // LinkedIn Email
                let linkedinEmail: String! = linkedInEmailModel?.elements[0].elementHandle.emailAddress
//                print("LinkedIn Email: \(linkedinEmail ?? "")")
                self.linkedin_Email = linkedinEmail ?? ""
                DispatchQueue.main.async {
                    let userData = LinkedInUserData(Name: self.linkedin_Name, LastName: self.linkedin_LastName, Email: self.linkedin_Email, Id: self.linkedin_Id, Pic: self.linkedin_Pic)
                    NotificationCenter.default.post(name: .kLinkedInLogin, object: nil, userInfo: ["userProfile":userData])

                    
                    //                    self.performSegue(withIdentifier: "detailseg", sender: self)
                }
            }
        }
        task.resume()
    }
}

// MARK: - Apple Login -

extension SocialLoginClass:ASAuthorizationControllerDelegate,ASAuthorizationControllerPresentationContextProviding{
    
    func setAppleLogin(view:UIViewController){
        controllerView = view
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func appleLogin(credential: ASAuthorizationAppleIDCredential) {
          
          guard let appleIDToken = credential.identityToken else {
              
              print("Unable to fetch identity token")
              return
          }
          guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
              
              print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
              return
          }
          print("Apple Token = \(idTokenString)")
          
//          let userIdApple = credential.user
//          let fullName = credential.fullName
//          let firstName = fullName?.givenName
//          let lastName = fullName?.familyName
//          let email = credential.email
          
        NotificationCenter.default.post(name: .kAppleLogin, object: nil, userInfo: ["userProfile":credential])
        
      }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential {
            appleLogin(credential: appleIDCredential)
        }else {
            NotificationCenter.default.post(name: .kAppleLogin, object: nil, userInfo: ["userProfile":"Please provide correct credentials. Thanks"])
        }
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
           return controllerView.view.window!
    }
}

extension Notification.Name {

    static let kGoogleLogin = Notification.Name(rawValue: "kGoogleLogin")
    static let kFacebookLogin = Notification.Name(rawValue: "kFacebookLogin")
    static let kAppleLogin = Notification.Name(rawValue: "kAppleLogin")
    static let kLinkedInLogin = Notification.Name(rawValue: "kLinkedInLogin")

}

struct LinkedInConstants {
    static let SCOPE = "r_liteprofile%20r_emailaddress" //Get lite profile info and e-mail address
    static let AUTHURL = "https://www.linkedin.com/oauth/v2/authorization"
    static let TOKENURL = "https://www.linkedin.com/oauth/v2/accessToken"
}

struct LinkedInUserData {
    var Name:String?
    var LastName:String?
    var Email:String?
    var Id:String?
    var Pic:String?
}

// MARK: - LinkedInEmailModel -
struct LinkedInEmailModel: Codable {
    let elements: [Element]
}

// MARK: - Element
struct Element: Codable {
    let elementHandle: Handle
    let handle: String
    
    enum CodingKeys: String, CodingKey {
        case elementHandle = "handle~"
        case handle
    }
}

// MARK: - Handle
struct Handle: Codable {
    let emailAddress: String
}


// MARK: - LinkedInProfileModel -
struct LinkedInProfileModel: Codable {
    let firstName, lastName: StName
    let profilePicture: ProfilePicture
    let id: String
}

// MARK: - StName
struct StName: Codable {
    let localized: Localized
}

// MARK: - Localized
struct Localized: Codable {
    let enUS: String
    
    enum CodingKeys: String, CodingKey {
        case enUS = "en_US"
    }
}

// MARK: - ProfilePicture -
struct ProfilePicture: Codable {
    let displayImage: DisplayImage
    
    enum CodingKeys: String, CodingKey {
        case displayImage = "displayImage~"
    }
}

// MARK: - DisplayImage -
struct DisplayImage: Codable {
    let elements: [ProfilePicElement]
}

// MARK: - Element
struct ProfilePicElement: Codable {
    let identifiers: [ProfilePicIdentifier]
}

// MARK: - Identifier
struct ProfilePicIdentifier: Codable {
    let identifier: String
}
