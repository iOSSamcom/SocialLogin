//
//  ViewController.swift
//  SocialLoginDemo
//
//  Created by Parth on 01/09/20.
//  Copyright © 2020 Samcom. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices
import InstagramLogin

class ViewController: UIViewController{
   
    @IBOutlet weak var fbButton: FBLoginButton!
    @IBOutlet weak var linkedInBtn: UIButton!
    
    @IBOutlet weak var appleSignInBtn: ASAuthorizationAppleIDButton!
    var instagramLogin: InstagramLoginViewController!
    let clientId = "478bb702052db0007645af8ce0bb84b6"
       let redirectUri = "https://com.appcoda/oauth.php"

    override func viewDidLoad() {
        super.viewDidLoad()
        SocialLoginClass.shared.setFBButton()
        fbButton.permissions = ["public_profile", "email"]
        SocialLoginClass.shared.setGoogle(view:self)
        appleSignInBtn.addTarget(self, action: #selector(handleLogInWithAppleID), for: .touchUpInside)
        SocialLoginClass.shared.setRequiredLinkedInAuth(clientId: "86oudp4zlongrx", clientSecretId: "usDTmQmD0Rw8hyM2", redirectURL: "https://com.appcoda.linkedin.oauth/oauth")
        notificationObserver()
        // Do any additional setup after loading the view.
    }
    
    func notificationObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(googleLoginSuccess(notification:)), name: .kGoogleLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(facebookLoginSuccess(notification:)), name: .kFacebookLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appleLoginSuccess(notification:)), name: .kAppleLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(linkedInLoginSuccess(notification:)), name: .kLinkedInLogin, object: nil)

    }
    
    @objc func googleLoginSuccess(notification:Notification){
        if let profileData = notification.userInfo?["userProfile"] as? GIDProfileData{
            print(profileData.name ?? "")
        }else{
            let error = notification.userInfo?["userProfile"] as? String
            print(error!)
        }
    }
    
    @objc func facebookLoginSuccess(notification:Notification){
        if let profileData = notification.userInfo?["userProfile"] as? [String:Any]{
            print(profileData)
        }else{
            let error = notification.userInfo?["userProfile"] as? String
            print(error!)
        }
    }
    @objc func appleLoginSuccess(notification:Notification){
        if let profileData = notification.userInfo?["userProfile"] as? ASAuthorizationAppleIDCredential{
            print(profileData.user)
        }else{
            let error = notification.userInfo?["userProfile"] as? String
            print(error!)
        }
    }
    @objc func linkedInLoginSuccess(notification:Notification){
        if let profileData = notification.userInfo?["userProfile"] as? LinkedInUserData{
            print(profileData)
        }
    }
}


extension ViewController{
    
    @IBAction func googleClicked(_ sender: GIDSignInButton) {
        SocialLoginClass.shared.googleLogin()
        
    }
    @IBAction func linkedInClicked(_ sender: UIButton) {
        
        SocialLoginClass.shared.linkedInAuthVC(view: self)
    }
    @IBAction func linkedInLogoutClicked(_ sender: UIButton) {
        SocialLoginClass.shared.linkedInLogout()
    }
    @IBAction func instagramClicked(_ sender: UIButton) {
        loginWithInstagram()
        
    }
    
   @objc func handleLogInWithAppleID() {
       SocialLoginClass.shared.setAppleLogin(view:self)
   }
    
}



extension ViewController{
     func loginWithInstagram() {

            // 2. Initialize your 'InstagramLoginViewController' and set your 'ViewController' to delegate it
            instagramLogin = InstagramLoginViewController(clientId: clientId, redirectUri: redirectUri)
            instagramLogin.delegate = self

            // 3. Customize it
            instagramLogin.scopes = [.basic, .publicContent] // [.basic] by default; [.all] to set all permissions
            instagramLogin.title = "Instagram" // If you don't specify it, the website title will be showed
            instagramLogin.progressViewTintColor = .blue // #E1306C by default

            // If you want a .stop (or other) UIBarButtonItem on the left of the view controller
            instagramLogin.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissLoginViewController))

            // You could also add a refresh UIBarButtonItem on the right
            instagramLogin.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshPage))

            // 4. Present it inside a UINavigationController (for example)
            present(UINavigationController(rootViewController: instagramLogin), animated: true)
        }

        @objc func dismissLoginViewController() {
            instagramLogin.dismiss(animated: true)
        }

        @objc func refreshPage() {
            instagramLogin.reloadPage()
        }

        // ...
    }

    // MARK: - InstagramLoginViewControllerDelegate

    extension ViewController: InstagramLoginViewControllerDelegate {

        func instagramLoginDidFinish(accessToken: String?, error: InstagramError?) {

            print(accessToken)
            // Whatever you want to do ...

            // And don't forget to dismiss the 'InstagramLoginViewController'
            instagramLogin.dismiss(animated: true)
        }
    }
