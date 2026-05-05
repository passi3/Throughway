//
//  ThroughwayApp.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import iamport_ios

class AppDelegate: UIResponder, UIApplicationDelegate {
    var pendingDeepLinkRoomId: String?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Iamport.shared.close()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        NotificationCenter.default.post(name: .fcmTokenDidUpdate, object: fcmToken)
    }
}

extension Notification.Name {
    static let fcmTokenDidUpdate   = Notification.Name("fcmTokenDidUpdate")
    static let chatRoomDeepLink    = Notification.Name("chatRoomDeepLink")
    static let inAppChatBanner     = Notification.Name("inAppChatBanner")
    static let activityKeepDidChange = Notification.Name("activityKeepDidChange")
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let userInfo = content.userInfo
        let roomId = (userInfo["roomId"] ?? userInfo["room_id"]) as? String
        if let roomId {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .inAppChatBanner,
                    object: nil,
                    userInfo: [
                        "title":  content.title,
                        "body":   content.body,
                        "roomId": roomId
                    ]
                )
            }
        }
        completionHandler([.badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let roomId = (userInfo["roomId"] ?? userInfo["room_id"]) as? String
        if let roomId {
            pendingDeepLinkRoomId = roomId
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .chatRoomDeepLink, object: roomId)
            }
        }
        completionHandler()
    }
}

@main
struct ThroughwayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            AuthView(viewModel: authViewModel)
        }
    }
}
