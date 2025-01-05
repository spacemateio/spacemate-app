package com.spacemate.app

import android.content.Intent
import android.os.Bundle
import android.net.Uri
import android.webkit.CookieManager
import androidx.appcompat.app.AppCompatActivity
import android.view.MenuItem
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.navigation.NavigationBarView
import com.spacemate.app.config.EnvironmentConfig
import com.spacemate.app.config.Environment
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import android.os.Handler
import android.os.Looper

class MainActivity : AppCompatActivity() {
    private lateinit var webViewFragment: WebViewFragment
    private lateinit var bottomNavigation: BottomNavigationView

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        
        // Add a 2-second delay
        var keepSplashScreen = true    
        splashScreen.setKeepOnScreenCondition {
            if (keepSplashScreen) {
                Handler(Looper.getMainLooper()).postDelayed({ keepSplashScreen = false }, 1500) // 2 seconds delay
            }
            keepSplashScreen
        }
        
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        setupWebView()
        setupBottomNavigation()
        
        // Handle deep link if activity was launched from auth callback
        intent?.data?.let { handleAuthCallback(it) }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Handle deep link if activity receives new intent
        intent?.data?.let { handleAuthCallback(it) }
    }

    private fun handleAuthCallback(uri: Uri) {
        if (uri.scheme == "com.spacemate.app") {
            val token = uri.getQueryParameter("token")
            if (token != null) {
                val cookieManager = CookieManager.getInstance()
                
                // Clear only auth-related cookies
                val cookies = cookieManager.getCookie(EnvironmentConfig.baseUrl)
                cookies?.split(";")?.forEach { cookie ->
                    val cookieName = cookie.substringBefore("=").trim()
                    if (cookieName.contains("next-auth")) {
                        cookieManager.setCookie(EnvironmentConfig.baseUrl, "$cookieName=; expires=Thu, 01 Jan 1970 00:00:00 GMT")
                    }
                }
                cookieManager.flush()
                
                // Set the session token cookie
                val domain = Uri.parse(EnvironmentConfig.baseUrl).host ?: "spacemate.io"
                
                // Use secure cookie for production and test environments
                val isSecureCookie = EnvironmentConfig.environment != Environment.DEV
                val cookieName = if (isSecureCookie) "__Secure-next-auth.session-token" else "next-auth.session-token"
                
                // For development environment, don't add Secure flag
                val secureFlag = if (isSecureCookie) "; Secure" else ""
                val cookieValue = "$cookieName=$token; Domain=$domain; Path=/; HttpOnly; SameSite=Lax$secureFlag"
                
                cookieManager.setCookie(EnvironmentConfig.baseUrl, cookieValue)
                cookieManager.flush()

                // Reload the current page to apply the new cookie
                webViewFragment.loadUrl("${EnvironmentConfig.baseUrl}/storage")
                bottomNavigation.selectedItemId = R.id.navigation_explore
            }
        }
    }

    private fun setupWebView() {
        webViewFragment = WebViewFragment()
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, webViewFragment)
            .commit()
    }

    private fun setupBottomNavigation() {
        bottomNavigation = findViewById(R.id.bottomNavigation)
        bottomNavigation.setOnItemSelectedListener { item ->
            val route = when (item.itemId) {
                R.id.navigation_explore -> "/storage"
                R.id.navigation_rents -> "/account/reservation"
                R.id.navigation_inbox -> "/chat"
                R.id.navigation_profile -> "/account"
                else -> return@setOnItemSelectedListener false
            }

            webViewFragment.navigateTo(route)
            true
        }
    }
}