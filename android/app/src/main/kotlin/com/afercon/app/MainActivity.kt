package com.afercon.app

import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat

class MainActivity: FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
