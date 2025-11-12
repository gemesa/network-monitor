#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WebSocketClientDelegate <NSObject>

- (void)webSocketDidFailWithError:(NSError *)error;
- (void)webSocketDidReceiveMessage:(NSString *)message;

@end

@interface WebSocketClient : NSObject <NSURLSessionWebSocketDelegate>

@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property(nonatomic, weak) id<WebSocketClientDelegate> delegate;
@property(nonatomic, assign) BOOL isConnected;

- (void)connect:(NSString *)urlString;
- (void)sendMessage:(NSString *)message
         completion:(nullable void (^)(NSError *_Nullable error))completion;
- (void)receiveMessage;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
