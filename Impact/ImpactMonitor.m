//
//  ImpactMonitor.m
//  Impact
//
//  Created by Matt Massicotte on 2019-09-18.
//  Copyright © 2019 Chime Systems Inc. All rights reserved.
//

#import "ImpactMonitor.h"
#include "ImpactState.h"
#include "ImpactLog.h"
#include "ImpactSignal.h"
#include "ImpactMachException.h"

#include <sys/sysctl.h>

ImpactState* GlobalImpactState = NULL;

@implementation ImpactMonitor

+ (ImpactMonitor *)shared {
    static ImpactMonitor *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _suppressReportCrash = NO;
    }

    return self;
}

- (void)startWithURL:(NSURL *)url identifier:(NSUUID *)uuid {
    assert(GlobalImpactState == NULL);

    NSURL* parent = url.URLByDeletingLastPathComponent;

    NSError* error = nil;
    if (![NSFileManager.defaultManager createDirectoryAtURL:parent withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"[Impact] Unable to create directory for log %@", error);
        return;
    }

    GlobalImpactState = malloc(sizeof(ImpactState));

    GlobalImpactState->constantState.suppressReportCrash = self.suppressReportCrash == YES;

    atomic_store(&GlobalImpactState->mutableState.crashState, ImpactCrashStateUninitialized);

    ImpactResult result;

    NSLog(@"[Impact] trying to start with: %s", url.fileSystemRepresentation);
    
    result = ImpactLogInitialize(GlobalImpactState, url.fileSystemRepresentation);
    if (result != ImpactResultSuccess) {
        NSLog(@"[Impact] Unable to initialize log %d", result);
        return;
    }

    result = ImpactSignalInitialize(GlobalImpactState);
    if (result != ImpactResultSuccess) {
        NSLog(@"[Impact] Unable to initialize signal %d", result);
        return;
    }

    result = ImpactMachExceptionInitialize(GlobalImpactState);
    if (result != ImpactResultSuccess) {
        NSLog(@"[Impact] Unable to initialize mach exceptions %d", result);
        return;
    }


    [self logExecutableData:GlobalImpactState];
    [self logEnvironmentDataWithId:uuid state:GlobalImpactState];

    atomic_store(&GlobalImpactState->mutableState.crashState, ImpactCrashStateInitialized);

    ImpactDebugLog("[Log:INFO:%s] finished initialization\n", __func__);
}

- (NSString *)OSVersionString {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];

    return [NSString stringWithFormat:@"%ld.%ld.%ld", version.majorVersion, version.minorVersion, version.patchVersion];
}

- (void)logExecutableData:(ImpactState *)state {
    ImpactLogger* log = &state->constantState.log;

    NSBundle *mainBundle = [NSBundle mainBundle];

    ImpactLogWriteString(log, "[Application] ");

    if (self.applicationIdentifier.length != 0) {
        ImpactLogWriteKeyStringObject(log, "id", self.applicationIdentifier, false);
    } else {
        ImpactLogWriteKeyStringObject(log, "id", [mainBundle bundleIdentifier], false);
    }

    ImpactLogWriteKeyStringObject(log, "org_id", self.organizationIdentifier, false);

    ImpactLogWriteKeyStringObject(log, "version", [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"], false);
    ImpactLogWriteKeyStringObject(log, "short_version", [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], true);
}

- (void)logEnvironmentDataWithId:(NSUUID *)identifier state:(ImpactState *)state {
    ImpactLogger* log = &state->constantState.log;

    ImpactLogWriteString(log, "[Environment] ");

#if TARGET_OS_MAC
    ImpactLogWriteKeyString(log, "platform", "macOS", false);
#endif

    NSString* reportId = [[[identifier UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];

    ImpactLogWriteKeyString(log, "report_id", reportId.UTF8String, false);
    ImpactLogWriteKeyStringObject(log, "install_id", self.installIdentifier, false);

    char str[256] = {0};
    size_t size = sizeof(str);

    int result = 0;

    result = sysctlbyname("kern.osversion", str, &size, NULL, 0);
    if (result == 0) {
        ImpactLogWriteKeyString(log, "os_build", str, false);
    } else {
        ImpactLogWriteKeyString(log, "os_build", "<unknown>", false);
    }

    ImpactLogWriteKeyString(log, "os_version", [self OSVersionString].UTF8String, true);
}

@end
