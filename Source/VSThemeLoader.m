//
//  VSThemeLoader.m
//  Q Branch LLC
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSThemeLoader.h"
#import "VSTheme.h"

@interface VSThemeLoader ()

@property (nonatomic, strong, readwrite) VSTheme *defaultTheme;
@property (nonatomic, strong, readwrite) VSTheme *variables;
@property (nonatomic, strong, readwrite) NSArray *themes;
@property (nonatomic, copy, readwrite) NSString *themesFilePath;

@end


@implementation VSThemeLoader

- (id)init {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	NSString *filename = @"DB5";
	NSDictionary *themesDictionary;
	_themesFilePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
	if (_themesFilePath != nil) {
		themesDictionary = [NSDictionary dictionaryWithContentsOfFile:_themesFilePath];
	} else {
		_themesFilePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
        themesDictionary = [self themesDictionaryFromJSONFileAtPath:_themesFilePath];
	}
	
    [self setupWithDictionary:themesDictionary];
	
	return self;
}

- (void)setupWithDictionary:(NSDictionary *)themesDictionary {
    
	NSMutableArray *themes = [NSMutableArray array];
	for (NSString *oneKey in themesDictionary) {
		
		VSTheme *theme = [[VSTheme alloc] initWithDictionary:themesDictionary[oneKey]];
		if ([[oneKey lowercaseString] isEqualToString:@"default"])
			_defaultTheme = theme;
        else if ([[oneKey lowercaseString] isEqualToString:@"variables"])
            _variables = theme;
        
		theme.name = oneKey;
		[themes addObject:theme];
	}
    
    _defaultTheme.parentTheme = _variables;
    
    for (VSTheme *oneTheme in themes) { /*All themes inherit from the default theme.*/
		if (oneTheme != _defaultTheme && oneTheme != _variables)
			oneTheme.parentTheme = _defaultTheme;
        
        oneTheme.imageFolderPath = _imageFolderPath;
    }
    
	_themes = themes;
}

- (VSTheme *)themeNamed:(NSString *)themeName {
    
	for (VSTheme *oneTheme in self.themes) {
		if ([themeName isEqualToString:oneTheme.name])
			return oneTheme;
	}
    
	return nil;
}

- (void)setImageFolderPath:(NSString *)imageFolderPath {
    for (VSTheme *oneTheme in self.themes) {
        oneTheme.imageFolderPath = imageFolderPath;
    }
    _imageFolderPath = imageFolderPath;
}

- (id)initWithFileAtPath:(NSString *)themesFilePath {
    self = [super init];
    if (self == nil)
        return nil;
    
    _themesFilePath = themesFilePath;
    
    NSDictionary *themesDictionary = [self themesDictionaryFromFileAtPath:themesFilePath];
    [self setupWithDictionary:themesDictionary];
    
    return self;
}

- (NSDictionary *)themesDictionaryFromFileAtPath:(NSString *)themesFilePath {
    
    NSDictionary *themesDictionary;
    if ([[themesFilePath pathExtension] isEqualToString:@"plist"]) {
        themesDictionary = [NSDictionary dictionaryWithContentsOfFile:themesFilePath];
    } else if ([[themesFilePath pathExtension] isEqualToString:@"json"]) {
        themesDictionary = [self themesDictionaryFromJSONFileAtPath:themesFilePath];
    }
    
    return themesDictionary;
}

- (NSDictionary *)themesDictionaryFromJSONFileAtPath:(NSString *)themesFilePath {
    
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:themesFilePath];
    [stream open];
    NSDictionary *themesDictionary = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:nil];
    [stream close];
    
    return themesDictionary;
}

- (void)handleThemeFileChangesWithBlock:(void (^)())handler {
    
    int descriptor = open([self.themesFilePath fileSystemRepresentation], O_EVTONLY);
    if (descriptor < 0)
        return;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // The way some text editors (e.g. vim) save a file appears to this mechanism to be deleting then re-creating
    // the file. So, we need to watch for edit events (WRITE | EXTEND) but also deletion of the file.
    __block dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                              (uintptr_t)descriptor,
                                                              DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_DELETE,
                                                              queue);
    
    VSThemeLoader *__weak weakLoader = self;
    dispatch_source_set_event_handler(source, ^{
        // For cases where the editor saved the file by appearing to delete it first, we'll cancel the monitor and then
        // re-create it after we've reloaded.
        dispatch_source_cancel(source);
        
        VSThemeLoader *strongLoader = weakLoader;
        if (strongLoader) {
            NSDictionary *dictionary = [strongLoader themesDictionaryFromFileAtPath:strongLoader.themesFilePath];
            [strongLoader setupWithDictionary:dictionary];

            dispatch_sync(dispatch_get_main_queue(), ^{
                handler();
            });
            
            [strongLoader handleThemeFileChangesWithBlock:handler];
        }
    });
    
    dispatch_source_set_cancel_handler(source, ^{
        close(descriptor);
    });
    
    dispatch_resume(source);
}

@end

