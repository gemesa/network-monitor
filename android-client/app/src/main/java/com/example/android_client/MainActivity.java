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

public class MainActivity extends AppCompatActivity
        implements WebSocketClient.WebSocketClientListener {

    private TextView contentTextView;
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
    public void onWebSocketMessage(@NonNull String message) {
        // TODO
    }
}
