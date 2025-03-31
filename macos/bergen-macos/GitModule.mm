#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import <os/log.h>

// Define log category for Git-related logs
static os_log_t bergenGitLog;

@interface GitModule : NSObject <RCTBridgeModule>
@end

@implementation GitModule

RCT_EXPORT_MODULE();

+ (void)initialize {
  if (self == [GitModule class]) {
    bergenGitLog = os_log_create("com.kkarimi.bergen", "GitModule");
  }
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

// Execute a shell command and return the output
- (NSString *)executeCommand:(NSString *)command inDirectory:(NSString *)directory {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:@"/bin/bash"];
  [task setArguments:@[@"-c", command]];
  
  if (directory) {
    [task setCurrentDirectoryPath:directory];
  }
  
  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  [task setStandardError:pipe];
  
  NSFileHandle *fileHandle = [pipe fileHandleForReading];
  
  @try {
    [task launch];
    [task waitUntilExit];
    
    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output ? output : @"";
  } @catch (NSException *exception) {
    os_log_error(bergenGitLog, "Error executing command: %{public}@, exception: %{public}@", 
                command, exception.description);
    return @"";
  }
}

// Get the Git repository root for a given file path
- (NSString *)getGitRepositoryRootForPath:(NSString *)path {
  NSString *command = [NSString stringWithFormat:@"cd \"%@\" && git rev-parse --show-toplevel 2>/dev/null || echo ''", path];
  NSString *directory = [path stringByDeletingLastPathComponent];
  NSString *output = [self executeCommand:command inDirectory:directory];
  
  // Trim whitespace and newlines
  output = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  return output;
}

// Check if a file is part of a Git repository
RCT_EXPORT_METHOD(isGitRepository:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *repoRoot = [self getGitRepositoryRootForPath:filePath];
    BOOL isGitRepo = repoRoot.length > 0;
    
    resolve(@{
      @"isGitRepository": @(isGitRepo),
      @"repositoryRoot": isGitRepo ? repoRoot : @""
    });
  });
}

// Get basic Git info for a file
RCT_EXPORT_METHOD(getFileGitInfo:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *repoRoot = [self getGitRepositoryRootForPath:filePath];
    
    if (repoRoot.length == 0) {
      resolve(@{
        @"isGitRepository": @(NO),
        @"repositoryRoot": @"",
        @"lastCommitAuthor": @"",
        @"lastCommitDate": @"",
        @"lastCommitHash": @"",
        @"lastCommitMessage": @"",
        @"fileStatus": @"",
        @"addedBy": @"",
        @"addedDate": @""
      });
      return;
    }
    
    NSString *directory = [filePath stringByDeletingLastPathComponent];
    
    // Get last commit info for the file
    NSString *lastCommitCommand = [NSString stringWithFormat:@"git log -1 --pretty=format:\"%%H|%%an|%%ad|%%s\" -- \"%@\" 2>/dev/null || echo ''", filePath];
    NSString *lastCommitOutput = [self executeCommand:lastCommitCommand inDirectory:directory];
    
    // Get file status
    NSString *statusCommand = [NSString stringWithFormat:@"git status --porcelain -- \"%@\" 2>/dev/null || echo ''", filePath];
    NSString *statusOutput = [self executeCommand:statusCommand inDirectory:directory];
    
    // Get info about when the file was added to the repository
    NSString *addedByCommand = [NSString stringWithFormat:@"git log --diff-filter=A --pretty=format:\"%%H|%%an|%%ad|%%s\" -- \"%@\" 2>/dev/null | tail -1 || echo ''", filePath];
    NSString *addedByOutput = [self executeCommand:addedByCommand inDirectory:directory];
    
    // Get current branch name
    NSString *branchCommand = @"git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ''";
    NSString *branchOutput = [self executeCommand:branchCommand inDirectory:directory];
    
    NSArray *lastCommitParts = [lastCommitOutput componentsSeparatedByString:@"|"];
    NSArray *addedByParts = [addedByOutput componentsSeparatedByString:@"|"];
    
    NSDictionary *result = @{
      @"isGitRepository": @(YES),
      @"repositoryRoot": repoRoot,
      @"currentBranch": [branchOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
      @"lastCommitHash": lastCommitParts.count > 0 ? lastCommitParts[0] : @"",
      @"lastCommitAuthor": lastCommitParts.count > 1 ? lastCommitParts[1] : @"",
      @"lastCommitDate": lastCommitParts.count > 2 ? lastCommitParts[2] : @"",
      @"lastCommitMessage": lastCommitParts.count > 3 ? lastCommitParts[3] : @"",
      @"fileStatus": [statusOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
      @"addedByHash": addedByParts.count > 0 ? addedByParts[0] : @"",
      @"addedByAuthor": addedByParts.count > 1 ? addedByParts[1] : @"",
      @"addedDate": addedByParts.count > 2 ? addedByParts[2] : @"",
      @"addedCommitMessage": addedByParts.count > 3 ? addedByParts[3] : @""
    };
    
    resolve(result);
  });
}

// Get commit history for a file
RCT_EXPORT_METHOD(getFileCommitHistory:(NSString *)filePath
                  limit:(NSInteger)limit
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *repoRoot = [self getGitRepositoryRootForPath:filePath];
    
    if (repoRoot.length == 0) {
      resolve(@[]);
      return;
    }
    
    NSString *directory = [filePath stringByDeletingLastPathComponent];
    
    // Limit to a reasonable number of commits
    NSInteger actualLimit = limit > 0 ? MIN(limit, 100) : 10;
    
    // Get commit history for the file
    NSString *command = [NSString stringWithFormat:@"git log -n %ld --pretty=format:\"%%H|%%an|%%ad|%%s\" -- \"%@\" 2>/dev/null", (long)actualLimit, filePath];
    NSString *output = [self executeCommand:command inDirectory:directory];
    
    if (output.length == 0) {
      resolve(@[]);
      return;
    }
    
    NSArray *commitLines = [output componentsSeparatedByString:@"\n"];
    NSMutableArray *commits = [NSMutableArray array];
    
    for (NSString *line in commitLines) {
      if (line.length == 0) continue;
      
      NSArray *parts = [line componentsSeparatedByString:@"|"];
      if (parts.count < 4) continue;
      
      [commits addObject:@{
        @"hash": parts[0],
        @"author": parts[1],
        @"date": parts[2],
        @"message": parts[3]
      }];
    }
    
    resolve(commits);
  });
}

@end