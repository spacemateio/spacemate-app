package com.spacemate.android

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton

class StartActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private lateinit var progressBar: View
    private lateinit var agreeButton: MaterialButton
    private lateinit var prefs: SharedPreferences

    companion object {
        private const val PREF_HAS_AGREED_TO_TERMS = "has_agreed_to_terms"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
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

        setupWebView()
        setupButton()
    }

    private fun setupWebView() {
        webView.apply {
            settings.javaScriptEnabled = true
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
            
            loadUrl("https://spacemate.io/corporate/terms-of-service")
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