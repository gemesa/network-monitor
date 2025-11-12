#import "ViewController.h"
#import "WebSocketClient.h"

@interface ViewController () <WebSocketClientDelegate>
@property(nonatomic, strong) WebSocketClient *webSocketClient;
@property(nonatomic, strong) UIButton *connectButton;
@property(nonatomic, strong) UITextView *contentTextView;
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

  self.contentTextView = [[UITextView alloc] init];
  self.contentTextView.font = [UIFont systemFontOfSize:14];
  self.contentTextView.editable = NO;
  self.contentTextView.backgroundColor = [UIColor lightGrayColor];
  self.contentTextView.layer.cornerRadius = 8;
  self.contentTextView.layer.borderWidth = 1.0;
  self.contentTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
  self.contentTextView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.contentTextView];

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
    [self.contentTextView.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor],
    [self.contentTextView.centerYAnchor
        constraintEqualToAnchor:self.view.centerYAnchor
                       constant:-50],
    [self.contentTextView.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor
                       constant:20],
    [self.contentTextView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor
                       constant:-20],
    [self.contentTextView.heightAnchor constraintEqualToConstant:400],

    // Button below the text view.
    [self.connectButton.topAnchor
        constraintEqualToAnchor:self.contentTextView.bottomAnchor
                       constant:20],
    [self.connectButton.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor],
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

- (void)webSocketDidReceiveMessage:(NSString *)message {
  self.contentTextView.text = message;
}

@end
