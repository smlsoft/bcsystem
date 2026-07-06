package com.smlsoft.dedecashier

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.annotation.Keep
import androidx.annotation.NonNull
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONObject

class MainActivity: FlutterActivity(), MethodChannel.MethodCallHandler {
    private var customMethodChannelHandler: CustomMethodChannelHandler? = null
    private lateinit var presentationChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var flutterEngineChannel: MethodChannel? = null
    private var presentation: PresentationDisplay? = null
    private var displayManager: DisplayManager? = null

    companion object {
        private const val PRESENTATION_CHANNEL = "presentation_displays_plugin"
        private const val PRESENTATION_EVENTS_CHANNEL = "presentation_displays_plugin_events"
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Setup existing USB functionality
        android.util.Log.d("MainActivity", "Setting up custom method channel handler")
        try {
            customMethodChannelHandler = CustomMethodChannelHandler(this, flutterEngine.dartExecutor.binaryMessenger)
            customMethodChannelHandler?.setupChannel()
            android.util.Log.d("MainActivity", "Custom method channel handler setup complete")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error setting up custom method channel handler: ${e.message}")
        }

        // Setup presentation display functionality
        setupPresentationDisplay(flutterEngine)
    }

    private fun setupPresentationDisplay(flutterEngine: FlutterEngine) {
        // Initialize MethodChannel for presentation displays
        presentationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRESENTATION_CHANNEL)
        presentationChannel.setMethodCallHandler(this)

        // Initialize EventChannel for display events
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, PRESENTATION_EVENTS_CHANNEL)
        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displayConnectedStreamHandler = DisplayConnectedStreamHandler(displayManager)
        eventChannel.setStreamHandler(displayConnectedStreamHandler)

        Log.d(TAG, "Presentation display setup complete")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.i(TAG, "Presentation Channel: method: ${call.method} | arguments: ${call.arguments}")
        when (call.method) {
            "showPresentation" -> {
                try {
                    val obj = JSONObject(call.arguments as String)
                    Log.i(
                        TAG,
                        "Channel: method: ${call.method} | displayId: ${obj.getInt("displayId")} | routerName: ${
                            obj.getString("routerName")
                        }"
                    )
                    val displayId: Int = obj.getInt("displayId")
                    val tag: String = obj.getString("routerName")
                    val display = displayManager?.getDisplay(displayId)
                    if (display != null) {
                        val flutterEngine = createFlutterEngine(tag)
                        flutterEngine?.let {
                            flutterEngineChannel =
                                MethodChannel(it.dartExecutor.binaryMessenger, "${PRESENTATION_CHANNEL}_engine")
                            presentation = PresentationDisplay(this, tag, display)
                            Log.i(TAG, "presentation: $presentation")
                            presentation?.show()

                            result.success(true)
                        }
                            ?: result.error("404", "Can't find FlutterEngine", null)
                    } else {
                        result.error("404", "Can't find display with displayId is $displayId", null)
                    }
                } catch (e: Exception) {
                    result.error(call.method, e.message, null)
                }
            }
            "hidePresentation" -> {
                try {
                    val obj = JSONObject(call.arguments as String)
                    Log.i(TAG, "Channel: method: ${call.method} | displayId: ${obj.getInt("displayId")}")

                    presentation?.dismiss()
                    presentation = null
                    result.success(true)
                } catch (e: Exception) {
                    result.error(call.method, e.message, null)
                }
            }
            "listDisplay" -> {
                val listJson = ArrayList<DisplayJson>()
                val category = (call.arguments as? String) ?: "android.hardware.display.category.PRESENTATION"
                val displays = displayManager?.getDisplays(category)
                Log.i(TAG, "listDisplay: Found ${displays?.size ?: 0} displays")
           
                if (displays != null) {
                    for (display: Display in displays) {
                        Log.i(TAG, "display: $display")
                        try {
                            val displayId = display.displayId
                            val displayFlags = display.flags
                            val displayRotation = display.rotation
                            val displayName = try {
                                display.name ?: "Unknown Display"
                            } catch (e: Exception) {
                                "Display $displayId"
                            }
                            
                            Log.i(TAG, "Display details - ID: $displayId, Flags: $displayFlags, Rotation: $displayRotation, Name: $displayName")
                            
                            val d = DisplayJson(displayId, displayFlags, displayRotation, displayName)
                            listJson.add(d)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error reading display properties: ${e.message}")
                            // Add fallback display info
                            val fallbackDisplay = DisplayJson(0, 0, 0, "Error Display")
                            listJson.add(fallbackDisplay)
                        }
                    }
                }
                val jsonResult = Gson().toJson(listJson)
                Log.i(TAG, "listDisplay result: $jsonResult")
                result.success(jsonResult)
            }
            "transferDataToPresentation" -> {
                try {
                    flutterEngineChannel?.invokeMethod("DataTransfer", call.arguments)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun createFlutterEngine(tag: String): FlutterEngine? {
        if (FlutterEngineCache.getInstance().get(tag) == null) {
            val flutterEngine = FlutterEngine(this)
            flutterEngine.navigationChannel.setInitialRoute(tag)
            FlutterInjector.instance().flutterLoader().startInitialization(this)
            val path = FlutterInjector.instance().flutterLoader().findAppBundlePath()
            val entrypoint = DartExecutor.DartEntrypoint(path, "secondaryDisplayMain")
            flutterEngine.dartExecutor.executeDartEntrypoint(entrypoint)
            flutterEngine.lifecycleChannel.appIsResumed()
            // Cache the FlutterEngine to be used by FlutterActivity.
            FlutterEngineCache.getInstance().put(tag, flutterEngine)
        }
        return FlutterEngineCache.getInstance().get(tag)
    }

    override fun onDestroy() {
        super.onDestroy()
        customMethodChannelHandler?.onDestroy()
        presentationChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        presentation?.dismiss()
    }
}

@Keep
data class DisplayJson(
    @SerializedName("displayId")
    val displayId: Int,
    @SerializedName("flags")
    val flags: Int,
    @SerializedName("rotation")
    val rotation: Int,
    @SerializedName("name")
    val name: String
)

class PresentationDisplay(context: Context, private val tag: String, display: Display) :
    Presentation(context, display) {

    companion object {
        private const val TAG = "PresentationDisplay"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val flContainer = FrameLayout(context)
        val params = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        flContainer.layoutParams = params

        setContentView(flContainer)

        val flutterView = FlutterView(context)
        flContainer.addView(flutterView, params)
        val flutterEngine = FlutterEngineCache.getInstance().get(tag)
        if (flutterEngine != null) {
            flutterView.attachToFlutterEngine(flutterEngine)
            Log.d(TAG, "FlutterView attached to FlutterEngine with tag: $tag")
        } else {
            Log.e(TAG, "Can't find the FlutterEngine with cache name $tag")
        }
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "PresentationDisplay started")
    }

    override fun onStop() {
        super.onStop()
        Log.d(TAG, "PresentationDisplay stopped")
    }
}

class DisplayConnectedStreamHandler(private var displayManager: DisplayManager?) :
    EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private var handler: Handler? = null

    companion object {
        private const val TAG = "DisplayConnectedStreamHandler"
    }

    private val displayListener =
        object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) {
                Log.d(TAG, "Display added: $displayId")
                sink?.success(1)
            }

            override fun onDisplayRemoved(displayId: Int) {
                Log.d(TAG, "Display removed: $displayId")
                sink?.success(0)
            }

            override fun onDisplayChanged(displayId: Int) {
                Log.d(TAG, "Display changed: $displayId")
                // Optional: notify about display changes
                // sink?.success(2)
            }
        }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "Starting display listener")
        sink = events
        handler = Handler(Looper.getMainLooper())
        displayManager?.registerDisplayListener(displayListener, handler)
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "Stopping display listener")
        sink = null
        handler = null
        displayManager?.unregisterDisplayListener(displayListener)
    }
}