#ifndef PORTFOLIO_LIB_HPP
#define PORTFOLIO_LIB_HPP

#include <portfolio_optimizer/portfolio_lib_export.hpp>

[[nodiscard]] PORTFOLIO_LIB_EXPORT int factorial(int) noexcept;

[[nodiscard]] constexpr int factorial_constexpr(int input) noexcept
{
  if (input == 0) { return 1; }

  return input * factorial_constexpr(input - 1);
}

#endif
