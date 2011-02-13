//
// CPWebSocket.j
//
// Based off https://github.com/samsonjs/cpwebsocket
//

@import <Foundation/CPObject.j>

kCPWebSocketStateConnecting = 0,
kCPWebSocketStateOpen       = 1,
kCPWebSocketStateClosed     = 2;

@implementation CPWebSocket : CPObject {
    JSObject websocket;
    id       delegate;
    CPArray  _queue;
    BOOL     _close;
}

+ (id)openWebSocketWithURL:(CPString)url delegate:(id)aDelegate {
    return  [[self alloc] initWithURL:url delegate:aDelegate];
}

- (id)initWithURL:(CPString)url delegate:(id)aDelegate {
    self = [super init];
    if (self) {
        self.websocket = new WebSocket(url);
        self.delegate = aDelegate;
        self._queue = [CPArray array];
        [self _bindCallbacks];
        self._close = NO;
    }
    var _unload = window.onunload;
    window.onunload = function() {
        [self close];
        _unload();
    }
    return self;
}

- (void)_bindCallbacks {
    self.websocket.onopen = function() {
        // WebSocket is open.. send everything in the queue
        var _l = [_queue count]
        if (_l > 0) {
            for (var i = 0; i < _l; ++i) {
                [self _send:[_queue objectAtIndex:i]];
            }
        }
        
        [delegate webSocketDidOpen:self];
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        
        if (_close) {
            [self close];
        }
    };
    self.websocket.onclose = function(evt) {
        [delegate webSocketDidClose:self];
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
    self.websocket.onmessage = function(evt) {
        [delegate webSocket:self didReceiveMessage:evt.data];
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
    self.websocket.onerror = function(evt) {
        [delegate webSocket:self didReceiveError:evt];
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
}

- (void)rebindToDelegate:(id)aDelegate {
    self.delegate = aDelegate;
    [self _bindCallbacks];
}

- (CPString)URL {
    return self.websocket.URL;
}

- (CPNumber)state {
    return self.websocket.readyState;
}

- (CPNumber)bytesBuffered {
    return self.websocket.bufferedAmount;
}

- (void)close {
    if ([self state] === kCPWebSocketStateOpen) {
        self.websocket.close();
    }
    else {
        self._close = YES;
    }
}

- (BOOL)_send:(CPString)data {
    switch ([self state]) {
        case kCPWebSocketStateConnecting:
            [_queue addObject:data];
            return NO;
        case kCPWebSocketStateOpen:
            return self.websocket.send(data);
        case kCPWebSocketStateClosed:
            return NO;
        default:
            return NO;
    }
}

- (BOOL)sendMessage:(CPString)aMessage {
  return [self _send:aMessage];
}

- (BOOL)sendData:(JSObject)someData {
  return [self _send:[CPString JSONFromObject:someData]];
}

@end
