package com.medbook.appointment.configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                // Try to load from classpath for simplified deployment if JSON is provided there.
                // Alternatively, we could load from environment variable Base64 if needed.
                InputStream resourceAsStream = getClass().getResourceAsStream("/firebase-service-account.json");
                if (resourceAsStream != null) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(resourceAsStream))
                            .build();

                    FirebaseApp.initializeApp(options);
                } else {
                    // Initialize with default credentials
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.getApplicationDefault())
                            .build();

                    FirebaseApp.initializeApp(options);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
