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
    _isConnected = NO;
  }
  return self;
}

- (void)connect:(NSString *)urlString {
  self.isConnected = YES;
  NSURL *url = [NSURL URLWithString:urlString];

  self.webSocketTask = [self.session webSocketTaskWithURL:url];

  // https://developer.apple.com/documentation/foundation/urlsessiontask/resume()?language=objc#Discussion
  [self.webSocketTask resume];

  [self receiveMessage];
}

- (void)sendMessage:(NSString *)message
         completion:(nullable void (^)(NSError *_Nullable error))completion {
  // https://developer.apple.com/documentation/foundation/nsurlsessionwebsockettask/sendmessage:completionhandler:?language=objc
  NSURLSessionWebSocketMessage *wsMessage =
      [[NSURLSessionWebSocketMessage alloc] initWithString:message];

  // This block is short-lived and non-recursive, so we do not use a weak self.
  // Technically this could cause a retain cycle, but it is temporary and gets
  // released quickly.
  [self.webSocketTask sendMessage:wsMessage
                completionHandler:^(NSError *error) {
                  if (error) {
                    NSLog(@"Send error: %@", error.localizedDescription);
                    // self is captured here.
                    if ([self.delegate respondsToSelector:@selector
                                       (webSocketDidFailWithError:)]) {
                      [self.delegate webSocketDidFailWithError:error];
                    }
                  } else {
                    NSLog(@"Sent: %@", message);
                  }

                  if (completion) {
                    completion(error);
                  }
                }];
}

- (void)receiveMessage {
  if (!self.isConnected) {
    NSLog(@"Not receiving - not connected");
    return;
  }
  __weak typeof(self) weakSelf = self;
  // https://developer.apple.com/documentation/foundation/nsurlsessionwebsockettask/receivemessagewithcompletionhandler:?language=objc
  // This block is long-lived because it is waiting for the server to send data.
  // Without a weak self, it creates a retain cycle.
  [self.webSocketTask
      receiveMessageWithCompletionHandler:^(
          NSURLSessionWebSocketMessage *message, NSError *error) {
        if (error) {
          NSLog(@"Receive error: %@", error.localizedDescription);

          // self is captured here.
          if (weakSelf.isConnected &&
              [weakSelf.delegate
                  respondsToSelector:@selector(webSocketDidFailWithError:)]) {
            [weakSelf.delegate webSocketDidFailWithError:error];
          }
          return;
        }
        NSLog(@"Received: %@", message.string);

        // self is captured here.
        [weakSelf receiveMessage];
      }];
}

- (void)disconnect {
  self.isConnected = NO;
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

// https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/urlsession(_:task:didcompletewitherror:)?language=objc
// Catch connection errors raised earlier in the network stack.
- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(nullable NSError *)error {
  if (!self.isConnected) {
    NSLog(@"Task cancelled (intentional disconnect)");
    // No need to notify the delegate.
    return;
  }

  if (error) {
    NSLog(@"Connection error: %@", error.localizedDescription);
    if ([self.delegate
            respondsToSelector:@selector(webSocketDidFailWithError:)]) {
      [self.delegate webSocketDidFailWithError:error];
    }
  }
}

@end

NS_ASSUME_NONNULL_END
