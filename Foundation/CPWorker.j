@import <Foundation/CPObject.j>

@implementation CPWorker : CPObject {
  JSObject  worker;
  id        delegate; 
}

+ (id)workerWithURL:(CPString)url delegate:(id)aDelegate {
  return [[CPWorker alloc] initWithURL:url delegate:aDelegate];
}

- (id)initWithURL:(CPString)url delegate:(id)aDelegate {
  self = [super init];
  if (self && typeof(Worker)!=="undefined") {
    self.worker = new Worker(url);
    self.delegate = aDelegate;
    self.worker.onmessage = function(evt) {
      [delegate worker:self didReceiveData:evt.data];
      [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
  }
  
  return self;
}

- (void)sendMessage:(CPString)aMessage {
  self.worker.postMessage(aMessage);
}

- (void)sendData:(JSObject)someData {
  self.worker.postMessage([CPString JSONFromObject:someData]);
}

@end