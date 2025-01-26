package com.spacemate.android

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.SpannableString
import android.text.Spanned
import android.text.method.LinkMovementMethod
import android.text.style.ClickableSpan
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebSettings
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.google.android.material.button.MaterialButton

class StartActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private lateinit var progressBar: View
    private lateinit var agreeButton: MaterialButton
    private lateinit var termsText: TextView
    private lateinit var prefs: SharedPreferences

    companion object {
        private const val PREF_HAS_AGREED_TO_TERMS = "has_agreed_to_terms"
        private const val TERMS_URL = "https://spacemate.io/corporate/terms-of-service"
        private const val PRIVACY_URL = "https://spacemate.io/corporate/privacy-policy"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        
        // Add a 1.5-second delay
        var keepSplashScreen = true    
        splashScreen.setKeepOnScreenCondition {
            if (keepSplashScreen) {
                Handler(Looper.getMainLooper()).postDelayed({ keepSplashScreen = false }, 1500)
            }
            keepSplashScreen
        }

        super.onCreate(savedInstanceState)

        // Check if user has already agreed to terms
        prefs = getSharedPreferences("app_prefs", MODE_PRIVATE)
        if (prefs.getBoolean(PREF_HAS_AGREED_TO_TERMS, false)) {
            navigateToMain()
            return
        }

        setContentView(R.layout.activity_start)

        webView = findViewById(R.id.webView)
        progressBar = findViewById(R.id.progressBar)
        agreeButton = findViewById(R.id.agreeButton)
        termsText = findViewById(R.id.termsText)

        setupWebView()
        setupButton()
        setupTermsText()
    }

    private fun setupTermsText() {
        val fullText = "By Selecting \"I Agree & Continue\", I agree to SpaceMate's Terms of Service, & acknowledge the Privacy Policy"
        val spannableString = SpannableString(fullText)

        val termsClickableSpan = object : ClickableSpan() {
            override fun onClick(widget: View) {
                webView.loadUrl(TERMS_URL)
            }
        }

        val privacyClickableSpan = object : ClickableSpan() {
            override fun onClick(widget: View) {
                webView.loadUrl(PRIVACY_URL)
            }
        }

        // Find indices for Terms of Service
        val termsStart = fullText.indexOf("Terms of Service")
        val termsEnd = termsStart + "Terms of Service".length

        // Find indices for Privacy Policy
        val privacyStart = fullText.indexOf("Privacy Policy")
        val privacyEnd = privacyStart + "Privacy Policy".length

        // Set clickable spans
        spannableString.setSpan(termsClickableSpan, termsStart, termsEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        spannableString.setSpan(privacyClickableSpan, privacyStart, privacyEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

        termsText.apply {
            text = spannableString
            movementMethod = LinkMovementMethod.getInstance()
            setLinkTextColor(resources.getColor(R.color.primary, null))
        }
    }

    private fun setupWebView() {
        webView.apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                cacheMode = WebSettings.LOAD_DEFAULT
                loadWithOverviewMode = true
                useWideViewPort = true
            }
            
            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    progressBar.visibility = View.VISIBLE
                    agreeButton.isEnabled = false
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    progressBar.visibility = View.GONE
                    agreeButton.isEnabled = true
                }
            }
            
            // Setup cookie manager and add deviceType cookie
            val cookieManager = CookieManager.getInstance()
            cookieManager.setAcceptCookie(true)
            cookieManager.setAcceptThirdPartyCookies(this, true)
            
            // Set the deviceType cookie
            val domain = "spacemate.io"
            val cookieValue = "deviceType=mobile; Domain=$domain; Path=/"
            cookieManager.setCookie("https://spacemate.io", cookieValue)
            cookieManager.flush()
            
            loadUrl(TERMS_URL)
        }
    }

    private fun setupButton() {
        agreeButton.setOnClickListener {
            // Save agreement to preferences
            prefs.edit().putBoolean(PREF_HAS_AGREED_TO_TERMS, true).apply()
            navigateToMain()
        }
    }

    private fun navigateToMain() {
        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }
} 