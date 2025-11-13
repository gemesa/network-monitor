package com.example.android_client;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;

public class WebSocketClient {
    private static final String TAG = "WebSocketClient";

    private OkHttpClient client;
    // https://square.github.io/okhttp/3.x/okhttp/okhttp3/WebSocket.html
    private WebSocket webSocket;
    WebSocketClientListener listener;
    boolean isConnected = false;
    Handler mainHandler;

    public interface WebSocketClientListener {
        void onWebSocketConnected();

        void onWebSocketDisconnected();

        void onWebSocketError(@NonNull Exception error);

        void onWebSocketMessage(@NonNull String message);
    }

    public interface SendCallback {
        void onComplete();
    }

    public WebSocketClient(@NonNull WebSocketClientListener listener) {
        this.client = new OkHttpClient();
        this.listener = listener;
        this.mainHandler = new Handler(Looper.getMainLooper());
    }

    public void connect(@NonNull String url) {
        isConnected = true;

        Request request = new Request.Builder().url(url).build();
        // https://square.github.io/okhttp/3.x/okhttp/okhttp3/WebSocketListener.html
        webSocket =
                client.newWebSocket(
                        request,
                        new okhttp3.WebSocketListener() {
                            @Override
                            public void onOpen(
                                    @NonNull WebSocket webSocket, @NonNull Response response) {
                                Log.d(TAG, "WebSocket connected");
                                if (listener != null) {
                                    // Might update UI.
                                    mainHandler.post(
                                            new Runnable() {
                                                @Override
                                                public void run() {
                                                    listener.onWebSocketConnected();
                                                }
                                            });
                                }
                            }

                            @Override
                            public void onMessage(
                                    @NonNull WebSocket webSocket, @NonNull String text) {
                                Log.d(TAG, "Received: " + text);
                                if (listener != null) {
                                    listener.onWebSocketMessage(text);
                                }
                            }

                            @Override
                            public void onClosing(
                                    @NonNull WebSocket webSocket,
                                    int code,
                                    @NonNull String reason) {
                                Log.d(TAG, "WebSocket closing: " + code + " / " + reason);
                                // https://datatracker.ietf.org/doc/html/rfc6455#section-7.4
                                webSocket.close(1000, null);
                            }

                            @Override
                            public void onClosed(
                                    @NonNull WebSocket webSocket,
                                    int code,
                                    @NonNull String reason) {
                                Log.d(TAG, "WebSocket closed: " + code + " / " + reason);
                                if (listener != null) {
                                    // Might update UI.
                                    mainHandler.post(
                                            new Runnable() {
                                                @Override
                                                public void run() {
                                                    listener.onWebSocketDisconnected();
                                                }
                                            });
                                }
                            }

                            @Override
                            public void onFailure(
                                    @NonNull WebSocket webSocket,
                                    @NonNull Throwable t,
                                    @Nullable Response response) {
                                if (!isConnected) {
                                    Log.d(TAG, "Task cancelled (intentional disconnect)");
                                    return;
                                }

                                Log.e(TAG, "Connection error: " + t.getMessage());
                                if (listener != null) {
                                    mainHandler.post(
                                            new Runnable() {
                                                @Override
                                                public void run() {
                                                    listener.onWebSocketError(new Exception(t));
                                                }
                                            });
                                }
                            }
                        });
    }

    public void sendMessage(final @NonNull String message, final @Nullable SendCallback callback) {
        if (webSocket == null) {
            return;
        }

        boolean success = webSocket.send(message);

        if (success) {
            Log.d(TAG, "Sent: " + message);
            if (callback != null) {
                callback.onComplete();
            }
        } else {
            Log.e(TAG, "Send failed");
            if (listener != null) {
                // This might update the UI
                // so it must be executed on the main thread.
                mainHandler.post(
                        new Runnable() {
                            @Override
                            public void run() {
                                final Exception error = new Exception("Failed to send message");
                                listener.onWebSocketError(error);
                            }
                        });
            }
            if (callback != null) {
                callback.onComplete();
            }
        }
    }

    public void disconnect() {
        isConnected = false;
        if (webSocket != null) {
            // https://datatracker.ietf.org/doc/html/rfc6455#section-7.4
            webSocket.close(1000, "Normal closure");
            webSocket = null;
        }
    }
}
