//
//  ICUPattern.m
//  CocoaICU
//
//  Created by Aaron Evans on 11/19/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//
// more info: http://icu.sourceforge.net/apiref/icu4c/uregex_8h.html
//
// inspiration: http://java.sun.com/j2se/1.5.0/docs/api/index.html?java/util/regex/Pattern.html
//

#import "ICUPattern.h"
#import "ICUMatcher.h"
#import "NSStringICUAdditions.h"

struct URegularExpression;
/**
* Structure represeting a compiled regular rexpression, plus the results
 *    of a match operation.
 * @draft ICU 3.0
 */
typedef struct URegularExpression URegularExpression;

#define U_HIDE_DRAFT_API 1
#define U_DISABLE_RENAMING 1

#import <unicode/uregex.h>
#import <unicode/ustring.h>

NSUInteger const ICUCaseInsensitiveMatching = UREGEX_CASE_INSENSITIVE;
NSUInteger const ICUComments = UREGEX_COMMENTS;
NSUInteger const ICUDotMatchesAll = UREGEX_DOTALL;
NSUInteger const ICUMultiline = UREGEX_MULTILINE;
NSUInteger const ICUUnicodeWordBoundaries = UREGEX_UWORD;

@interface ICUPattern (Private)
-(void)setRe:(URegularExpression *)p;
-(NSUInteger)flags;
-(UChar *)textToSearch;

@end

@implementation ICUPattern

+(ICUPattern *)patternWithString:(NSString *)aPattern flags:(NSUInteger)flags {
	return [[self alloc] initWithString:aPattern flags:flags];	
}

+(ICUPattern *)patternWithString:(NSString *)aPattern {
	return [[self alloc] initWithString:aPattern flags:0];
}

-(id)initWithString:(NSString *)aPattern flags:(NSUInteger)f {

	if(![super init])
		return nil;

	textToSearch = NULL;
	flags = f;

	UParseError err;
	UErrorCode status = 0;
	UChar *regexStr = [aPattern UTF16String];
	URegularExpression *e = uregex_open(regexStr, -1, (uint32_t)flags, &err, &status);

	if(U_FAILURE(status)) {
		[NSException raise:@"Invalid Pattern Exception"
					format:@"Could not compile pattern: %s", u_errorName(status)];
	}

	[self setRe:e];

	return self;	
}

-(id)initWithString:(NSString *)aPattern {
	return [self initWithString:aPattern flags:0];
}

-(void)dealloc {
	if(textToSearch != NULL)
		free(textToSearch);
}

-(NSString *)stringToSearch {
	return [NSString stringWithICUString:[self textToSearch]];
}

-(void)setStringToSearch:(NSString *)aStringToSearchOver {
	NSParameterAssert(aStringToSearchOver);
	UChar *utf16String = [aStringToSearchOver copyUTF16String];
	UErrorCode status = 0;

	uregex_setText([self re], utf16String, -1, &status);

	[self reset];

	if(U_FAILURE(status)) {
		free(utf16String);
		[NSException raise:@"Invalid String Exception"
					format:@"Could not set text to match against: %s", u_errorName(status)];
	}

	if(textToSearch)
		free(textToSearch);
	textToSearch = utf16String;
}

-(UChar *)textToSearch {
	return (UChar *)textToSearch;
}

- (id)copyWithZone:(NSZone *)zone {

	ICUPattern *p = [[[self class] allocWithZone:zone] initWithString:[self description] flags:[self flags]];

	UErrorCode status = 0;
	URegularExpression *r = uregex_clone([self re], &status);
	if(U_FAILURE(status))
		[NSException raise:@"Copy Exception"
					format:@"Could not copy pattern: %s", u_errorName(status)];

	[p setRe:r];

	return p;
}

-(void)reset {
	UErrorCode status = 0;
	uregex_reset([self re], 0, &status);

	if(U_FAILURE(status)) {
		[NSException raise:@"Pattern Exception"
					format:@"Could not reset pattern: %s", u_errorName(status)];
	}	
}

-(NSUInteger)flags {
	return flags;
}

-(NSString *)pattern {
	return [self description];
}

-(void)setRe:(URegularExpression *)p {
	if(re != NULL)
		NSZoneFree(nil, re);

	re = p;
}

-(void *)re {
	return re;
}

-(NSString *)description {

	if([self re] != NULL) {
		UChar *p = NULL;
		UErrorCode status = 0;
		int32_t len = 0;
		
		p = (UChar *)uregex_pattern([self re], &len, &status);
		if(U_FAILURE(status)) {
			[NSException raise:@"Pattern Exception"
						format:@"Could not get pattern text from pattern."];
		}

		return [[NSString alloc] initWithBytes:p length:len encoding:[NSString nativeUTF16Encoding]];
	}

	return nil;
}

-(NSArray *)componentsSplitFromString:(NSString *)stringToSplit
{
	[self setStringToSearch:stringToSplit];
	BOOL isDone = NO;
	UErrorCode status = 0;

	NSMutableArray *results = [NSMutableArray array];
	NSInteger destFieldsCapacity = 16;
	size_t destCapacity = u_strlen([self textToSearch]);

	while(!isDone) {
		UChar *destBuf = (UChar *)NSZoneCalloc(nil, destCapacity, sizeof(UChar));
		int32_t requiredCapacity = 0;
		UChar *destFields[destFieldsCapacity];
		NSInteger numberOfComponents = uregex_split([self re],
													destBuf,
													(int32_t)destCapacity,
													&requiredCapacity,
													destFields,
													(int32_t)destFieldsCapacity,
													&status);
		
		if(status == U_BUFFER_OVERFLOW_ERROR) { // buffer was too small, grow it
			NSZoneFree(nil, destBuf);
			NSAssert(destCapacity * 2 < NSIntegerMax, @"Overflow occurred splitting string.");
			destCapacity = (destCapacity < requiredCapacity) ? requiredCapacity : destCapacity * 2;
			status = 0;
		} else if(destFieldsCapacity == numberOfComponents) {
			destFieldsCapacity *= 2;
			NSAssert(destFieldsCapacity *2 < NSIntegerMax, @"Overflow occurred splitting string.");
			NSZoneFree(nil, destBuf);
			status = 0;
		} else if(U_FAILURE(status)) {
			NSZoneFree(nil, destBuf);
			isDone = YES;
		} else {
			NSInteger i;
			
			for(i=0; i<numberOfComponents; i++) {
				NSAssert(i < destFieldsCapacity, @"Unexpected number of components found in split.");
				UChar *offsetStart = destFields[i];					
				[results addObject:[NSString stringWithICUString:offsetStart]];
			}
			isDone = YES;
		}
	}

	if(U_FAILURE(status))
		[NSException raise:@"Split Exception"
					format:@"Unable to split string: %s", u_errorName(status)];

	return [NSArray arrayWithArray:results];	
}

-(BOOL)matchesString:(NSString *)stringToMatchAgainst {
	ICUMatcher *m = [ICUMatcher matcherWithPattern:self overString:stringToMatchAgainst];
	return [m matches];
}

@end
