package com.example.android_client;

import android.app.AlertDialog;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.res.ResourcesCompat;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity
        implements WebSocketClient.WebSocketClientListener {

    TextView contentTextView;
    private Button connectButton;
    WebSocketClient webSocketClient;
    boolean isConnected = false;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        webSocketClient = new WebSocketClient(this);

        contentTextView = findViewById(R.id.contentTextView);
        contentTextView.setText("Ready to connect.\n\nTap 'Connect' to view network devices.");
        connectButton = findViewById(R.id.connectButton);

        connectButton.setBackgroundTintList(null);
        connectButton.setBackgroundResource(R.drawable.button_disconnected);
        connectButton.setForeground(
                ResourcesCompat.getDrawable(getResources(), R.drawable.button_ripple, getTheme()));
        connectButton.setClickable(true);
        connectButton.setFocusable(true);

        connectButton.setOnClickListener(
                new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        connectButtonTapped();
                    }
                });
    }

    void connectButtonTapped() {
        if (isConnected) {
            webSocketClient.sendMessage(
                    "{\"type\":\"unsubscribe\"}",
                    new WebSocketClient.SendCallback() {
                        @Override
                        public void onComplete() {
                            webSocketClient.disconnect();
                        }
                    });

        } else {
            // https://developer.android.com/studio/run/emulator-networking
            String wsURL = "ws://10.0.2.2:8080/data";
            webSocketClient.connect(wsURL);
        }
    }

    @Override
    public void onWebSocketConnected() {
        isConnected = true;
        connectButton.setText("Disconnect");
        connectButton.setBackgroundResource(R.drawable.button_connected);
        webSocketClient.sendMessage("{\"type\":\"subscribe\"}", null);
    }

    @Override
    public void onWebSocketDisconnected() {
        isConnected = false;
        connectButton.setText("Connect");
        connectButton.setBackgroundResource(R.drawable.button_disconnected);
    }

    @Override
    public void onWebSocketError(@NonNull Exception error) {
        new AlertDialog.Builder(MainActivity.this)
                .setTitle("Connection error")
                .setMessage(error.getMessage())
                .setPositiveButton("OK", null)
                .show();
    }

    @Override
    public void onWebSocketMessage(final @NonNull String message) {
        runOnUiThread(
                new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject json = new JSONObject(message);
                            String type = json.optString("type");

                            if ("ack".equals(type)) {
                                contentTextView.setText(json.optString("message"));
                            } else if ("data".equals(type)) {
                                JSONArray devices = json.optJSONArray("data");
                                StringBuilder formattedText = new StringBuilder();

                                if (devices != null) {
                                    formattedText
                                            .append("Network devices (")
                                            .append(devices.length())
                                            .append(" found)\n");
                                    formattedText.append("====================\n\n");

                                    for (int i = 0; i < devices.length(); i++) {
                                        JSONObject device = devices.getJSONObject(i);
                                        String ip = device.optString("ip", "N/A");
                                        String mac = device.optString("mac", "N/A");
                                        String hostname = device.optString("hostname", "Unknown");

                                        formattedText.append("- ").append(hostname).append("\n");
                                        formattedText.append("  IP: ").append(ip).append("\n");
                                        formattedText.append("  MAC: ").append(mac).append("\n\n");
                                    }
                                }

                                contentTextView.setText(formattedText.toString());
                            } else {
                                contentTextView.setText("Received: " + message);
                            }
                        } catch (JSONException e) {
                            contentTextView.setText("JSON parse error: " + e.getMessage());
                        }
                    }
                });
    }
}
