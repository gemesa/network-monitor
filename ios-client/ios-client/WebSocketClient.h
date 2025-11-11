#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebSocketClient : NSObject <NSURLSessionWebSocketDelegate>

@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;

- (void)connect:(NSString *)urlString;
- (void)sendMessage:(NSString *)message;
- (void)receiveMessage;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
