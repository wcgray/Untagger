#import <Foundation/Foundation.h>

@protocol UntaggerHTMLParserDelegate

- (void)recievedCharacters:(NSString*)characters;
- (void)endElement:(NSString*)elementName;
- (void)startElement:(NSString*)elementName;
- (void)finishedParsingDocument;

@end
