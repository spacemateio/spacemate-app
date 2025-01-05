package com.spacemate.app.config

enum class Environment {
    DEV, TEST, PROD
}

object EnvironmentConfig {
    var environment: Environment = Environment.PROD

    val baseUrl: String
        get() = when (environment) {
            Environment.DEV -> "http://10.0.2.2:3000" // Android emulator localhost
            Environment.TEST -> "https://test.spacemate.io"
            Environment.PROD -> "https://spacemate.io"
        }
} 