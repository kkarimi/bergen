#import <Cocoa/Cocoa.h>

/**
 * Main entry point for the macOS application.
 * Initializes and starts the application's main run loop.
 *
 * @param argc The number of arguments passed to the program.
 * @param argv The array of arguments passed to the program.
 * @return The exit status of the application.
 */
int main(int argc, const char *argv[]) {
  // Let the NSApplication class handle the main run loop
  return NSApplicationMain(argc, argv);
}
