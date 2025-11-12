#import "ViewController.h"
#import "WebSocketClient.h"

@interface ViewController () <WebSocketClientDelegate>
@property(nonatomic, strong) WebSocketClient *webSocketClient;
@property(nonatomic, strong) UIButton *connectButton;
@property(nonatomic, assign) BOOL isConnected;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor grayColor];
  self.webSocketClient = [[WebSocketClient alloc] init];
  self.webSocketClient.delegate = self;
  self.isConnected = NO;

  self.connectButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
  self.connectButton.backgroundColor = [UIColor systemBlueColor];
  [self.connectButton setTitleColor:[UIColor whiteColor]
                           forState:UIControlStateNormal];
  self.connectButton.layer.cornerRadius = 8;
  self.connectButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
  [self.connectButton addTarget:self
                         action:@selector(connectButtonTapped:)
               forControlEvents:UIControlEventTouchUpInside];

  self.connectButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.connectButton];

  [NSLayoutConstraint activateConstraints:@[
    [self.connectButton.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor],
    [self.connectButton.centerYAnchor
        constraintEqualToAnchor:self.view.centerYAnchor],
    [self.connectButton.widthAnchor constraintEqualToConstant:200],
    [self.connectButton.heightAnchor constraintEqualToConstant:50]
  ]];
}

- (void)connectButtonTapped:(UIButton *)sender {
  if (self.isConnected) {
    [self.webSocketClient sendMessage:@"{\"type\":\"unsubscribe\"}"
                           completion:^(NSError *_Nullable error) {
                             [self.webSocketClient disconnect];
                           }];
    self.isConnected = NO;
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.connectButton.backgroundColor = [UIColor systemBlueColor];
  } else {
    NSString *wsURL = @"ws://127.0.0.1:8080/data";
    [self.webSocketClient connect:wsURL];
    [self.webSocketClient sendMessage:@"{\"type\":\"subscribe\"}"
                           completion:nil];
    self.isConnected = YES;
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    self.connectButton.backgroundColor = [UIColor systemRedColor];
  }
}

- (void)webSocketDidFailWithError:(NSError *)error {
  // Reset button state.
  self.isConnected = NO;
  [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
  self.connectButton.backgroundColor = [UIColor systemBlueColor];

  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"Connection error"
                                          message:error.localizedDescription
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *okAction =
      [UIAlertAction actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                             handler:nil];

  [alert addAction:okAction];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
