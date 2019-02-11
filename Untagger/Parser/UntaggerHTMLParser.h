#import <Foundation/Foundation.h>
#import "UntaggerHTMLParserDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface UntaggerHTMLParser : NSObject

@property (nonatomic, weak) NSObject<UntaggerHTMLParserDelegate> *delegate;

- (void)parseHtmlString:(NSString *)htmlString;

@end

NS_ASSUME_NONNULL_END
