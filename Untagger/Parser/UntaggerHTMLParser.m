#import "UntaggerHTMLParser.h"
#include <libxml/parser.h>

typedef struct XmlParserStateData {
    UntaggerHTMLParser* parser;
} XmlParserStateData;
static xmlSAXHandler htmlParserSaxHandler;

void parserCharacters(void *user_data, const xmlChar *ch, int len) {
    UntaggerHTMLParser *parser = ((XmlParserStateData*)user_data)->parser;
    NSString * _Nullable characters = [NSString stringWithUTF8String:(const char *)ch];
    xmlChar *chCopy = NULL;
    if (!characters) {
        chCopy = malloc(sizeof(xmlChar) * (len + 1));
        memcpy(chCopy, ch, sizeof(xmlChar) * (len));
        chCopy[len] = '\0';
        characters = [NSString stringWithUTF8String:(const char *)chCopy];
    }
    
    [parser.delegate recievedCharacters:characters];
    
    if (chCopy != NULL) {
        free(chCopy);
    }
}

void parserStartElement(void* user_data, const xmlChar* name, const xmlChar** attrs) {
    UntaggerHTMLParser *parser = ((XmlParserStateData*)user_data)->parser;
    [parser.delegate startElement:[NSString stringWithUTF8String:(const char *)name]];
}

void parserEndElement(void* user_data, const xmlChar* name) {
    UntaggerHTMLParser *parser = ((XmlParserStateData*)user_data)->parser;
    [parser.delegate endElement:[NSString stringWithUTF8String:(const char *)name]];
}

void parserEndDocument(void *user_data) {
    UntaggerHTMLParser *parser = ((XmlParserStateData*)user_data)->parser;
    [parser.delegate finishedParsingDocument];
}

@implementation UntaggerHTMLParser

- (void)parseHtmlString:(NSString *)htmlString {
    XmlParserStateData userData;
    userData.parser = self;
    
    htmlParserSaxHandler.endDocument = parserEndDocument;
    htmlParserSaxHandler.characters = parserCharacters;
    htmlParserSaxHandler.startElement = parserStartElement;
    htmlParserSaxHandler.endElement = parserEndElement;
    
    htmlSAXParseDoc((const xmlChar*)[htmlString UTF8String], "utf-8", &htmlParserSaxHandler, &userData);
}

@end
