//
//  PTKeyCombo.m
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//

#import "PTKeyCombo.h"

#import "PTKeyCodeTranslator.h"

#import <Carbon/Carbon.h>

@implementation PTKeyCombo

+ (id)clearKeyCombo
{
	return [self keyComboWithKeyCode: -1 modifiers: -1];
}

+ (instancetype)keyComboWithKeyCode: (int)keyCode modifiers: (int)modifiers
{
	return [[self alloc] initWithKeyCode: keyCode modifiers: modifiers];
}

- (instancetype)initWithKeyCode: (int)keyCode modifiers: (int)modifiers
{
	self = [super init];
	
	if( self )
	{
		mKeyCode = keyCode;
		mModifiers = modifiers;
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder*)coder
{
	return [self initWithPlistRepresentation:[coder decodeObject]];
}

- (instancetype)initWithPlistRepresentation: (id)plist
{
	int keyCode, modifiers;
	
	if( !plist || ![plist count] )
	{
		keyCode = -1;
		modifiers = -1;
	}
	else
	{
		keyCode = [plist[@"keyCode"] intValue];
		if( keyCode <= 0 ) keyCode = -1;
	
		modifiers = [plist[@"modifiers"] intValue];
		if( modifiers <= 0 ) modifiers = -1;
	}

	return [self initWithKeyCode: keyCode modifiers: modifiers];
}

- (id)plistRepresentation
{
	return @{@"keyCode": @([self keyCode]),
				@"modifiers": @([self modifiers])};
}

- (void)encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:[self plistRepresentation]];
}

- (id)copyWithZone:(NSZone*)zone;
{
	return self;
}

- (BOOL)isEqual: (PTKeyCombo*)combo
{
	return	[self keyCode] == [combo keyCode] &&
			[self modifiers] == [combo modifiers];
}

#pragma mark -

- (int)keyCode
{
	return mKeyCode;
}

- (int)modifiers
{
	return mModifiers;
}

- (BOOL)isValidHotKeyCombo
{
	return mKeyCode >= 0 && mModifiers > 0;
}

- (BOOL)isClearCombo
{
	return mKeyCode == -1 && mModifiers == -1;
}

@end

#pragma mark -

@implementation PTKeyCombo (UserDisplayAdditions)

+ (NSString*)_stringForModifiers: (long)modifiers
{
	static unichar modToChar[4][2] =
	{
		{ cmdKey, 		kCommandUnicode },
		{ optionKey,	kOptionUnicode },
		{ controlKey,	kControlUnicode },
		{ shiftKey,		kShiftUnicode }
	};

	NSString* str = [NSString string];
	long i;

	for( i = 0; i < 4; i++ )
	{
		if( modifiers & modToChar[i][0] )
			str = [str stringByAppendingString: [NSString stringWithCharacters: &modToChar[i][1] length: 1]];
	}

	return str;
}

+ (NSDictionary*)_keyCodesDictionary
{
	static NSDictionary* keyCodes = nil;
	
	if( keyCodes == nil )
	{
		NSString* path;
		NSString* contents;
		
		path = [[NSBundle bundleForClass: self] pathForResource: @"KeyCodes" ofType: @"plist"];
#if LEGACY_BUILD
		contents = [NSString stringWithContentsOfFile: path];
#else
		contents = [NSString stringWithContentsOfFile:path usedEncoding:nil error:NULL];

#endif
		keyCodes = [contents propertyList];
	}
	
	return keyCodes;
}

+ (NSString*)_stringForKeyCode: (short)keyCode legacyKeyCodeMap: (NSDictionary*)dict
{
	id key;
	NSString* str;
	
	key = [NSString stringWithFormat: @"%d", keyCode];
	str = dict[key];
	
	if( !str )
		str = [NSString stringWithFormat: @"%X", keyCode];
	
	return str;
}

+ (NSString*)_stringForKeyCode: (short)keyCode newKeyCodeMap: (NSDictionary*)dict
{
	NSString* result;
	NSString* keyCodeStr;
	NSDictionary* unmappedKeys;
	NSArray* padKeys;
	
	keyCodeStr = [NSString stringWithFormat: @"%d", keyCode];
	
	//Handled if its not handled by translator
	unmappedKeys = dict[@"unmappedKeys"];
	result = unmappedKeys[keyCodeStr];
	if( result )
		return result;
	
	//Translate it
	result = [[[PTKeyCodeTranslator currentTranslator] translateKeyCode:keyCode] uppercaseString];
	
	//Handle if its a key-pad key
	padKeys = dict[@"padKeys"];
	if( [padKeys indexOfObject: keyCodeStr] != NSNotFound )
	{
		result = [NSString stringWithFormat:@"%@ %@", dict[@"padKeyString"], result];
	}
	
	return result;
}

+ (NSString*)_stringForKeyCode: (short)keyCode
{
	NSDictionary* dict;

	dict = [self _keyCodesDictionary];
	if( [dict[@"version"] intValue] <= 0 )
		return [self _stringForKeyCode: keyCode legacyKeyCodeMap: dict];

	return [self _stringForKeyCode: keyCode newKeyCodeMap: dict];
}

- (NSString*)description
{
	NSString* desc;
	
	if( [self isValidHotKeyCombo] ) //This might have to change
	{
		desc = [NSString stringWithFormat: @"%@%@",
				[[self class] _stringForModifiers: [self modifiers]],
				[[self class] _stringForKeyCode: [self keyCode]]];
	}
	else
	{
	#if __PROTEIN__
		desc = _PTLocalizedString( @"(None)", @"Hot Keys: Key Combo text for 'empty' combo" );
	#else
		desc = NSLocalizedString( @"(None)", @"Hot Keys: Key Combo text for 'empty' combo" );
	#endif
	}

	return desc;
}

@end
