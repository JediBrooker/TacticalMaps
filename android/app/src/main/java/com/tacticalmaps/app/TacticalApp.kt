package com.tacticalmaps.app

import android.app.Application

/** Application entry point — installs local-only crash capture as early as
 *  possible so a field crash isn't silent. */
class TacticalApp : Application() {
    override fun onCreate() {
        super.onCreate()
        CrashReporter.install(this)
    }
}
