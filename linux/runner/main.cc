#include "my_application.h"

#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <string>

namespace {

constexpr char kChildProcessEnvironment[] = "PILINEXT_RENDERER_CHILD";
constexpr char kDisableImpellerEnvironment[] = "PILINEXT_DISABLE_IMPELLER";
constexpr char kReadyFdEnvironment[] = "PILINEXT_RENDERER_READY_FD";

volatile sig_atomic_t g_renderer_child = -1;
volatile sig_atomic_t g_forwarded_signal = 0;

void ForwardSignal(int signal_number) {
  g_forwarded_signal = signal_number;
  if (g_renderer_child > 0) {
    kill(g_renderer_child, signal_number);
  }
}

void InstallSignalForwarding() {
  struct sigaction action {};
  action.sa_handler = ForwardSignal;
  sigemptyset(&action.sa_mask);
  sigaction(SIGINT, &action, nullptr);
  sigaction(SIGTERM, &action, nullptr);
  sigaction(SIGHUP, &action, nullptr);
}

bool EnvironmentEnabled(const char* name) {
  const char* value = std::getenv(name);
  return value != nullptr && std::strcmp(value, "0") != 0 &&
         std::strlen(value) > 0;
}

void ConfigureImpeller(bool enabled) {
  int switch_count = 0;
  if (const char* value = std::getenv("FLUTTER_ENGINE_SWITCHES")) {
    switch_count = std::atoi(value);
  }

  for (int index = 1; index <= switch_count; ++index) {
    const std::string name = "FLUTTER_ENGINE_SWITCH_" +
                             std::to_string(index);
    const char* value = std::getenv(name.c_str());
    if (value != nullptr &&
        std::strncmp(value, "enable-impeller=", 16) == 0) {
      setenv(name.c_str(), enabled ? "enable-impeller=true"
                                  : "enable-impeller=false",
             1);
      return;
    }
  }

  ++switch_count;
  const std::string name =
      "FLUTTER_ENGINE_SWITCH_" + std::to_string(switch_count);
  setenv(name.c_str(), enabled ? "enable-impeller=true"
                              : "enable-impeller=false",
         1);
  const std::string count = std::to_string(switch_count);
  setenv("FLUTTER_ENGINE_SWITCHES", count.c_str(), 1);
}

int RunFlutterApplication(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}

struct ChildResult {
  int status;
  bool rendered_first_frame;
};

ChildResult RunRendererChild(int argc, char** argv, bool enable_impeller) {
  int ready_pipe[2];
  if (pipe(ready_pipe) != 0) {
    return {-1, false};
  }

  const pid_t child = fork();
  if (child == 0) {
    signal(SIGINT, SIG_DFL);
    signal(SIGTERM, SIG_DFL);
    signal(SIGHUP, SIG_DFL);
    close(ready_pipe[0]);
    setenv(kChildProcessEnvironment, "1", 1);
    const std::string ready_fd = std::to_string(ready_pipe[1]);
    setenv(kReadyFdEnvironment, ready_fd.c_str(), 1);
    ConfigureImpeller(enable_impeller);
    execvp(argv[0], argv);
    _exit(127);
  }

  close(ready_pipe[1]);
  if (child < 0) {
    close(ready_pipe[0]);
    return {-1, false};
  }
  g_renderer_child = child;

  bool rendered_first_frame = false;
  int status = 0;
  while (true) {
    const pid_t wait_result = waitpid(child, &status, WNOHANG);
    if (wait_result == child) break;
    if (wait_result < 0 && errno != EINTR) {
      status = -1;
      break;
    }

    pollfd descriptor{};
    descriptor.fd = ready_pipe[0];
    descriptor.events = POLLIN | POLLHUP;
    const int poll_result = poll(&descriptor, 1, 100);
    if (poll_result > 0 && (descriptor.revents & POLLIN) != 0) {
      char signal_byte;
      if (read(ready_pipe[0], &signal_byte, 1) == 1) {
        rendered_first_frame = true;
        waitpid(child, &status, 0);
        break;
      }
    }
  }

  close(ready_pipe[0]);
  g_renderer_child = -1;
  return {status, rendered_first_frame};
}

int ExitCodeFromStatus(int status) {
  if (status < 0) return EXIT_FAILURE;
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
  return EXIT_FAILURE;
}

}  // namespace

int main(int argc, char** argv) {
  if (EnvironmentEnabled(kChildProcessEnvironment)) {
    return RunFlutterApplication(argc, argv);
  }

  InstallSignalForwarding();

  if (EnvironmentEnabled(kDisableImpellerEnvironment)) {
    const ChildResult result = RunRendererChild(argc, argv, false);
    return ExitCodeFromStatus(result.status);
  }

  const ChildResult impeller = RunRendererChild(argc, argv, true);
  if (g_forwarded_signal != 0) {
    return 128 + g_forwarded_signal;
  }
  if (impeller.rendered_first_frame ||
      (impeller.status >= 0 && WIFEXITED(impeller.status) &&
       WEXITSTATUS(impeller.status) == 0)) {
    return ExitCodeFromStatus(impeller.status);
  }

  g_printerr(
      "PiliNext: Impeller failed before the first frame; retrying with "
      "Skia.\n");
  const ChildResult skia = RunRendererChild(argc, argv, false);
  return ExitCodeFromStatus(skia.status);
}
