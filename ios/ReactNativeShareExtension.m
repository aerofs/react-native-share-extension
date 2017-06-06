#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"

#define URL_IDENTIFIER @"public.url"
#define TEXT_IDENTIFIER @"public.text"
#define VIDEO_IDENTIFIER @"public.audiovisual-content"
#define IMAGE_IDENTIFIER @"public.image"
#define COMPOSITE_IDENTIFIER @"public.composite-content"
#define DATA_IDENTIFIER @"public.data"

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
    NSTimer *autoTimer;
    NSString* type;
    NSString* value;
}

- (UIView*) shareView {
    return nil;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //object variable for extension doesn't work for react-native. It must be assign to gloabl
    //variable extensionContext. in this way, both exported method can touch extensionContext
    extensionContext = self.extensionContext;
    
    UIView *rootView = [self shareView];
    if (rootView.backgroundColor == nil) {
        rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
    }
    
    self.view = rootView;
}


RCT_EXPORT_METHOD(close) {
    [extensionContext completeRequestReturningItems:nil
                                  completionHandler:nil];
}



RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withCallback:^(NSArray* items, NSException* err) {
        if (err) {
            NSError* error = [[NSError alloc] initWithDomain:@"ShareExtension" code:0 userInfo:nil];
            reject(@"Error", @"Error occurred while extracting data from the selected item", error);
        }
        else {
            resolve(items);
        }
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSArray* items, NSException *exception))callback {
    @try {
        NSExtensionItem *item = [context.inputItems firstObject];
        NSMutableArray* items = [[NSMutableArray alloc] initWithCapacity:5];
        [item.attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
            if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER]) {
                NSDictionary* dict = [self processItemProvider:provider forTypeIdentifier:TEXT_IDENTIFIER];
                if (dict != nil) {
                    [items addObject:dict];
                }
            }
            else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]) {
                NSDictionary* dict = [self processItemProvider:provider forTypeIdentifier:IMAGE_IDENTIFIER];
                if (dict != nil) {
                    [items addObject:dict];
                }
            }
            else if ([provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER]) {
                NSDictionary* dict = [self processItemProvider:provider forTypeIdentifier:VIDEO_IDENTIFIER];
                if (dict != nil) {
                    [items addObject:dict];
                }
            }
            else if ([provider hasItemConformingToTypeIdentifier:COMPOSITE_IDENTIFIER]) {
                NSDictionary* dict = [self processItemProvider:provider forTypeIdentifier:COMPOSITE_IDENTIFIER];
                if (dict != nil) {
                    [items addObject:dict];
                }
            }
            else if ([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER]) {
                NSDictionary* dict = [self processItemProvider:provider forTypeIdentifier:URL_IDENTIFIER];
                if (dict != nil) {
                    [items addObject:dict];
                }
            }
            else if ([provider hasItemConformingToTypeIdentifier:DATA_IDENTIFIER]) {
                NSDictionary* dict = [self processItemProvider:provider forTypeIdentifier:DATA_IDENTIFIER];
                if (dict != nil) {
                    [items addObject:dict];
                }
            }
        }];
        if (callback) {
            callback(items, nil);
        }
        
    }
    @catch (NSException *exception) {
        if(callback) {
            callback(nil,exception);
        }
    }
}

- (NSDictionary*)processItemProvider:(NSItemProvider*)provider forTypeIdentifier:(NSString*)identifier {
    
    __block NSDictionary* dict = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    [provider loadItemForTypeIdentifier:identifier options:nil completionHandler:^(id<NSSecureCoding> _Nullable item, NSError * _Null_unspecified error) {
        
        NSObject* itemObj = (NSObject*)item;
        if ([itemObj isKindOfClass:[NSString class]]) {
            NSString * str = (NSString *)item;
            dict = @{
                     @"type": @"text",
                     @"data": str
                     };
        }
        else if ([itemObj isKindOfClass:[NSURL class]] || [itemObj isKindOfClass:[NSData class]]) {
            NSURL *url = (NSURL *)item;
            NSString *urlType = @"url";
            if ([url.absoluteString hasPrefix:@"file"]) {
                urlType = @"file";
            }
            dict = @{
                     @"type": urlType,
                     @"data": url.absoluteString
                     };
        }
        else {
            dict = nil;
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return dict;
    
}

@end
