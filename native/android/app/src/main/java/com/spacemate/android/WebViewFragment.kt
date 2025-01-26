package com.spacemate.android

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.*
import androidx.browser.customtabs.CustomTabsIntent
import androidx.fragment.app.Fragment
import android.util.Log
import org.json.JSONObject
import com.spacemate.android.config.EnvironmentConfig

class WebViewFragment : Fragment() {
    private var webView: WebView? = null
    private var progressBar: View? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return WebView(requireContext()).also { webView = it }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupWebView()
    }

    private fun clearAuthCookies() {
        val cookieManager = CookieManager.getInstance()
        // Store deviceType cookie value
        val cookies = cookieManager.getCookie(EnvironmentConfig.baseUrl)
        var deviceTypeCookie: String? = null
        cookies?.split(";")?.forEach { cookie ->
            val trimmedCookie = cookie.trim()
            if (trimmedCookie.startsWith("deviceType=")) {
                deviceTypeCookie = trimmedCookie
            }
        }
        
        // Remove all cookies
        cookieManager.removeAllCookies(null)
        cookieManager.flush()
        
        // Restore deviceType cookie
        deviceTypeCookie?.let {
            cookieManager.setCookie(EnvironmentConfig.baseUrl, "$it; path=/; secure;")
            cookieManager.flush()
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        // Enable cookie persistence
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        cookieManager.setAcceptThirdPartyCookies(webView, true)

        webView?.apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                databaseEnabled = true
                mediaPlaybackRequiresUserGesture = false
                allowFileAccess = true
                allowContentAccess = true
                
                // Enable cache and data persistence
                cacheMode = WebSettings.LOAD_DEFAULT
            }

            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url?.toString() ?: return false
                    
                    // Check if the URL is for social media, external sharing, or legal pages
                    if (url.contains("facebook.com") || 
                        url.contains("linkedin.com") || 
                        url.contains("twitter.com") ||
                        url.contains("t.co") ||
                        url.contains("/corporate/terms-of-service") ||
                        url.contains("/corporate/privacy-policy")) {
                        // Open in external browser
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        startActivity(intent)
                        return true
                    }
                    
                    // Let WebView handle SpaceMate URLs
                    if (url.contains("spacemate.io")) {
                        return false // Let WebView handle it
                    }
                    
                    // Open other external links in browser
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    startActivity(intent)
                    return true
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    progressBar?.visibility = View.GONE
                    
                    // Inject the flutter_inappwebview interface
                    val bridgeScript = """
                        window.flutter_inappwebview = {
                            callHandler: function(handlerName, ...args) {
                                window.FlutterChannel.postMessage(...args);
                            }
                        };
                    """.trimIndent()
                    
                    evaluateJavascript(bridgeScript, null)
                }
            }

            addJavascriptInterface(object : Any() {
                @JavascriptInterface
                fun postMessage(message: String) {
                    try {
                        val json = JSONObject(message)
                        when (json.getString("type")) {
                            "login" -> handleLogin()
                            "logout" -> handleLogout()
                            else -> Log.d("WebView", "Unhandled message type: ${json.getString("type")}")
                        }
                    } catch (e: Exception) {
                        Log.e("WebView", "Error handling message: ${e.message}")
                    }
                }
            }, "FlutterChannel")

            // Set initial cookie for deviceType if not already set
            if (cookieManager.getCookie(EnvironmentConfig.baseUrl)?.contains("deviceType=") != true) {
                cookieManager.setCookie(
                    EnvironmentConfig.baseUrl,
                    "deviceType=mobile; path=/; secure;"
                )
                cookieManager.flush()
            }

            // Load initial URL
            loadUrl("${EnvironmentConfig.baseUrl}/storage")
        }
    }

    private fun handleLogout() {
        activity?.runOnUiThread {
            clearAuthCookies()
            // Navigate to discovery page and update bottom navigation
            (activity as? MainActivity)?.let { mainActivity ->
                mainActivity.findViewById<com.google.android.material.bottomnavigation.BottomNavigationView>(R.id.bottomNavigation)?.selectedItemId = R.id.navigation_explore
            }
            webView?.loadUrl("${EnvironmentConfig.baseUrl}/storage")
        }
    }

    fun loadUrl(url: String) {
        webView?.loadUrl(url)
    }

    fun navigateTo(route: String) {
        val message = JSONObject().apply {
            put("type", "navigation")
            put("data", JSONObject().put("route", route))
        }

        webView?.evaluateJavascript(
            "window.dispatchEvent(new CustomEvent('fromFlutter', { detail: ${message} }));",
            null
        )
    }

    private fun handleLogin() {
        activity?.runOnUiThread {
            val callbackUrl = "${EnvironmentConfig.baseUrl}/auth/mobile-login"
            val authUrl = "${EnvironmentConfig.baseUrl}/auth/signin?callbackUrl=$callbackUrl"

            val customTabsIntent = CustomTabsIntent.Builder().build()
            customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            customTabsIntent.launchUrl(requireContext(), Uri.parse(authUrl))
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        webView = null
        progressBar = null
    }
} 