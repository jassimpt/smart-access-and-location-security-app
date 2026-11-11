import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private var lastLifecycleNotification: Notification.Name?

  /// Attaches the shared Flutter engine to the scene's window without a second engine.
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
    else { return }

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )
    self.window = window
    appDelegate.window = window
    window.makeKeyAndVisible()
    self.scene(scene, openURLContexts: connectionOptions.urlContexts)
    for activity in connectionOptions.userActivities {
      self.scene(scene, continue: activity)
    }
  }

  /// Resumes the legacy engine and registered plugins when the scene becomes active.
  func sceneDidBecomeActive(_ scene: UIScene) {
    forwardLifecycle(UIApplication.didBecomeActiveNotification)
  }

  /// Hides protected Flutter content as soon as the scene becomes inactive.
  func sceneWillResignActive(_ scene: UIScene) {
    forwardLifecycle(UIApplication.willResignActiveNotification)
  }

  /// Restores foreground lifecycle handling without automatically resuming tracking.
  func sceneWillEnterForeground(_ scene: UIScene) {
    forwardLifecycle(UIApplication.willEnterForegroundNotification)
  }

  /// Triggers auto-lock and suspends foreground tracking when the scene backgrounds.
  func sceneDidEnterBackground(_ scene: UIScene) {
    forwardLifecycle(UIApplication.didEnterBackgroundNotification)
  }

  /// Releases the scene window while retaining the shared engine for reconnection.
  func sceneDidDisconnect(_ scene: UIScene) {
    forwardLifecycle(UIApplication.didEnterBackgroundNotification)
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
      appDelegate.window === window
    {
      appDelegate.window = nil
    }
    window?.rootViewController = nil
    window = nil
  }

  /// Forwards URLs to the existing application delegate and its registered plugins.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    for context in URLContexts {
      var options: [UIApplication.OpenURLOptionsKey: Any] = [
        .openInPlace: context.options.openInPlace
      ]
      if let source = context.options.sourceApplication {
        options[.sourceApplication] = source
      }
      if let annotation = context.options.annotation {
        options[.annotation] = annotation
      }
      _ = appDelegate.application(UIApplication.shared, open: context.url, options: options)
    }
  }

  /// Preserves universal-link handling through Flutter's existing delegate.
  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    _ = appDelegate.application(
      UIApplication.shared,
      continue: userActivity,
      restorationHandler: { _ in }
    )
  }

  /// Bridges scene callbacks to the application notifications observed by Flutter 3.35.
  private func forwardLifecycle(_ notification: Notification.Name) {
    guard lastLifecycleNotification != notification else { return }
    lastLifecycleNotification = notification
    NotificationCenter.default.post(name: notification, object: UIApplication.shared)
  }
}
