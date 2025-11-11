#import "WebSocketClient.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WebSocketClient

- (instancetype)init {
  self = [super init];
  if (self) {
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    // UIKit requires all UI updates to happen on the main thread.
    _session =
        [NSURLSession sessionWithConfiguration:config
                                      delegate:self
                                 delegateQueue:[NSOperationQueue mainQueue]];
  }
  return self;
}

- (void)connect:(NSString *)urlString {
  NSURL *url = [NSURL URLWithString:urlString];

  self.webSocketTask = [self.session webSocketTaskWithURL:url];

  // https://developer.apple.com/documentation/foundation/urlsessiontask/resume()?language=objc#Discussion
  [self.webSocketTask resume];

  [self receiveMessage];
}

- (void)sendMessage:(NSString *)message {
  // https://developer.apple.com/documentation/foundation/nsurlsessionwebsockettask/sendmessage:completionhandler:?language=objc
  NSURLSessionWebSocketMessage *wsMessage =
      [[NSURLSessionWebSocketMessage alloc] initWithString:message];

  [self.webSocketTask sendMessage:wsMessage
                completionHandler:^(NSError *error) {
                  if (error) {
                    NSLog(@"Send error: %@", error.localizedDescription);
                  } else {
                    NSLog(@"Sent: %@", message);
                  }
                }];
}

- (void)receiveMessage {
  // https://developer.apple.com/documentation/foundation/nsurlsessionwebsockettask/receivemessagewithcompletionhandler:?language=objc
  [self.webSocketTask
      receiveMessageWithCompletionHandler:^(
          NSURLSessionWebSocketMessage *message, NSError *error) {
        if (error) {
          NSLog(@"Receive error: %@", error.localizedDescription);
          return;
        }
        NSLog(@"Received: %@", message.string);

        [self receiveMessage];
      }];
}

- (void)disconnect {
  // https://developer.apple.com/documentation/foundation/urlsessionwebsockettask/cancel(with:reason:)?language=objc
  [self.webSocketTask
      cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure
                   reason:nil];
}

// https://developer.apple.com/documentation/foundation/urlsessionwebsocketdelegate/urlsession(_:websockettask:didopenwithprotocol:)?language=objc
- (void)URLSession:(NSURLSession *)session
          webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
    didOpenWithProtocol:(nullable NSString *)protocol {
  NSLog(@"WebSocket connected");
}

// https://developer.apple.com/documentation/foundation/urlsessionwebsocketdelegate/urlsession(_:websockettask:didclosewith:reason:)?language=objc
- (void)URLSession:(NSURLSession *)session
       webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
    didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode
              reason:(nullable NSData *)reason {
  NSLog(@"WebSocket closed (code: %ld)", closeCode);
}

@end

NS_ASSUME_NONNULL_END
