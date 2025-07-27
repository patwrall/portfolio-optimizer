#include <cstdlib>
#include <exception>
#include <fmt/base.h>
#include <fmt/format.h>


#include <CLI/CLI.hpp>
#include <spdlog/spdlog.h>

#include <internal_use_only/config.hpp>
#include <string>

// NOLINTNEXTLINE(bugprone-exception-escape)
int main(int argc, const char **argv)
{
  try {
    CLI::App app{ fmt::format(
      "{} version {}", portfolio_optimizer::cmake::project_name, portfolio_optimizer::cmake::project_version) };

    bool show_version = false;
    app.add_flag("--version", show_version, "Show version information");

    std::string data_directory = "data";
    app.add_flag("--data-dir", data_directory, "Path to data containing asset CSV files");

    CLI11_PARSE(app, argc, argv);

    if (show_version) {
      fmt::print("{}\n", portfolio_optimizer::cmake::project_version);
      return EXIT_SUCCESS;
    }

    // load assets
    // calculate from loaded assets
    // display effecient fronttier

  } catch (const std::exception &e) {
    spdlog::error("Unhandled exception in main: {}", e.what());
  }
}
